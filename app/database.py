import os
import json
import asyncio
from pathlib import Path
from dotenv import load_dotenv
import certifi
from motor.motor_asyncio import AsyncIOMotorClient

# Explicitly resolve absolute path to .env file at project root
BASE_DIR = Path(__file__).resolve().parent.parent
ENV_PATH = BASE_DIR / ".env"
if ENV_PATH.exists():
    load_dotenv(dotenv_path=ENV_PATH)
else:
    load_dotenv()

MONGO_URL = os.getenv("MONGODB_URL")
DB_NAME = os.getenv("DATABASE_NAME", "healthtech_db")
FALLBACK_FILE = BASE_DIR / "app" / "data" / "local_db_fallback.json"


class LocalJSONStorage:
    def __init__(self, filepath: Path):
        self.filepath = filepath
        self.filepath.parent.mkdir(parents=True, exist_ok=True)
        if not self.filepath.exists():
            self._save({"patients": [], "medical_reports": []})

    def _load(self):
        try:
            with open(self.filepath, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return {"patients": [], "medical_reports": []}

    def _save(self, data):
        try:
            with open(self.filepath, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
        except Exception as e:
            print(f"[LocalDB] Storage write error: {e}")

    def list_collections(self):
        data = self._load()
        return list(data.keys())

    def get_collection(self, name: str):
        data = self._load()
        return data.get(name, [])

    def save_collection(self, name: str, items: list):
        data = self._load()
        data[name] = items
        self._save(data)


local_store = LocalJSONStorage(FALLBACK_FILE)


class ResilientCursor:
    def __init__(self, motor_cursor, local_items: list):
        self._motor_cursor = motor_cursor
        self._local_items = local_items
        self._sort_key = None
        self._sort_direction = -1

    def limit(self, count):
        self._limit_count = count
        if self._motor_cursor is not None:
            try:
                self._motor_cursor.limit(count)
            except Exception:
                pass
        return self

    def sort(self, key, direction=-1):
        self._sort_key = key
        self._sort_direction = direction
        if self._motor_cursor is not None:
            try:
                self._motor_cursor.sort(key, direction)
            except Exception:
                pass
        return self

    async def to_list(self, length=500):
        motor_items = []
        if self._motor_cursor is not None:
            try:
                motor_items = await self._motor_cursor.to_list(length=length)
            except Exception as e:
                print(f"[ResilientDB] MongoDB find to_list fallback ({e})")

        if motor_items:
            return motor_items

        # Fallback to local items if motor returned nothing or failed
        items = list(self._local_items)
        if self._sort_key:
            reverse = self._sort_direction < 0
            try:
                items.sort(key=lambda x: str(x.get(self._sort_key, "")), reverse=reverse)
            except Exception:
                pass
        return items[:length]


class ResilientCollection:
    def __init__(self, motor_db, name: str):
        self._motor_db = motor_db
        self.name = name

    def _matches_filter(self, doc: dict, query: dict) -> bool:
        if not query:
            return True
        for k, v in query.items():
            if k == "$or":
                matched_or = False
                for clause in v:
                    if self._matches_filter(doc, clause):
                        matched_or = True
                        break
                if not matched_or:
                    return False
            elif isinstance(v, dict):
                doc_val = doc.get(k)
                if "$regex" in v:
                    import re
                    pattern = v["$regex"]
                    flags = re.IGNORECASE if v.get("$options") == "i" else 0
                    if not doc_val or not re.search(pattern, str(doc_val), flags):
                        return False
            else:
                if doc.get(k) != v:
                    return False
        return True

    def _apply_update(self, doc: dict, update: dict):
        if "$set" in update:
            for k, v in update["$set"].items():
                doc[k] = v
        return doc

    async def find_one(self, query=None):
        if self._motor_db is not None:
            try:
                res = await self._motor_db[self.name].find_one(query or {})
                if res:
                    return res
            except Exception as e:
                print(f"[ResilientDB] MongoDB find_one fallback ({e})")

        items = local_store.get_collection(self.name)
        for doc in items:
            if self._matches_filter(doc, query or {}):
                return doc.copy()
        return None

    def find(self, query=None):
        motor_cursor = None
        if self._motor_db is not None:
            try:
                motor_cursor = self._motor_db[self.name].find(query or {})
            except Exception as e:
                print(f"[ResilientDB] MongoDB find fallback ({e})")

        items = local_store.get_collection(self.name)
        matched_local = [doc.copy() for doc in items if self._matches_filter(doc, query or {})]
        return ResilientCursor(motor_cursor, matched_local)

    async def update_one(self, query: dict, update: dict, upsert=False):
        # 1. Update local storage backup
        items = local_store.get_collection(self.name)
        updated_count = 0
        found = False
        for idx, doc in enumerate(items):
            if self._matches_filter(doc, query):
                found = True
                updated_doc = self._apply_update(doc, update)
                items[idx] = updated_doc
                updated_count = 1
                break

        if not found and upsert:
            new_doc = {}
            for k, v in query.items():
                if not k.startswith("$"):
                    new_doc[k] = v
            new_doc = self._apply_update(new_doc, update)
            items.append(new_doc)
            updated_count = 1

        local_store.save_collection(self.name, items)

        # 2. Update Motor MongoDB if available
        if self._motor_db is not None:
            try:
                return await self._motor_db[self.name].update_one(query, update, upsert=upsert)
            except Exception as e:
                print(f"[ResilientDB] MongoDB update_one warning ({e})")

        class UpdateResult:
            modified_count = updated_count
        return UpdateResult()

    async def insert_one(self, document: dict):
        # 1. Insert into local storage backup
        items = local_store.get_collection(self.name)
        doc_copy = document.copy()
        items.append(doc_copy)
        local_store.save_collection(self.name, items)

        # 2. Insert into Motor MongoDB if available
        if self._motor_db is not None:
            try:
                return await self._motor_db[self.name].insert_one(document)
            except Exception as e:
                print(f"[ResilientDB] MongoDB insert_one warning ({e})")

        class InsertResult:
            inserted_id = doc_copy.get("patient_id") or doc_copy.get("report_id") or "local_id"
        return InsertResult()

    async def delete_one(self, query: dict):
        # 1. Delete from local storage backup
        items = local_store.get_collection(self.name)
        new_items = [doc for doc in items if not self._matches_filter(doc, query)]
        deleted_count = len(items) - len(new_items)
        local_store.save_collection(self.name, new_items)

        # 2. Delete from Motor MongoDB if available
        if self._motor_db is not None:
            try:
                return await self._motor_db[self.name].delete_one(query)
            except Exception as e:
                print(f"[ResilientDB] MongoDB delete_one warning ({e})")

        class DeleteResult:
            deleted_count = deleted_count
        return DeleteResult()


class ResilientDB:
    def __init__(self, motor_db):
        self._motor_db = motor_db

    def __getitem__(self, name: str):
        return ResilientCollection(self._motor_db, name)

    async def list_collection_names(self):
        if self._motor_db is not None:
            try:
                return await self._motor_db.list_collection_names()
            except Exception as e:
                print(f"[ResilientDB] MongoDB list_collection_names fallback ({e})")
        return local_store.list_collections()


# Initialize Motor Client safely with 3-second selection timeout
_motor_db = None
if MONGO_URL:
    try:
        client = AsyncIOMotorClient(
            MONGO_URL,
            tlsCAFile=certifi.where(),
            tlsAllowInvalidCertificates=True,
            serverSelectionTimeoutMS=3000
        )
        _motor_db = client[DB_NAME]
    except Exception as _e:
        print(f"[Database] AsyncIOMotorClient init warning: {_e}")

db = ResilientDB(_motor_db)