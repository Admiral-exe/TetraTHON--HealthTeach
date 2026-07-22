import asyncio
import os
import sys
from pathlib import Path
from dotenv import load_dotenv
from motor.motor_asyncio import AsyncIOMotorClient

# Load environment variables
env_path = Path(__file__).parent / ".env"
load_dotenv(dotenv_path=env_path)

MONGO_URL = os.getenv("MONGODB_URL")
DB_NAME = os.getenv("DATABASE_NAME", "healthtech_db")

def get_db():
    if not MONGO_URL:
        print("[ERROR] MONGODB_URL is missing in .env file.")
        sys.exit(1)
    client = AsyncIOMotorClient(MONGO_URL)
    return client[DB_NAME]

async def list_users():
    db = get_db()
    patients = await db["patients"].find().to_list(length=100)
    
    print("\n==========================================")
    print(f"  REGISTERED PATIENTS ({len(patients)} Records Found)")
    print("==========================================")
    
    if not patients:
        print("[!] No patient records found in MongoDB database.")
        return []

    for idx, p in enumerate(patients, 1):
        p.pop("_id", None)
        print(f"\n[{idx}] Patient ID     : {p.get('patient_id')}")
        print(f"    Full Name      : {p.get('full_name')}")
        print(f"    Phone Number   : {p.get('phone_number')}")
        print(f"    Age / Gender   : {p.get('age')} yrs / {p.get('gender')}")
        print(f"    Blood Group    : {p.get('blood_group')}")
        print(f"    Email          : {p.get('email') or 'Not provided'}")
        print(f"    Chronic List   : {', '.join(p.get('chronic_diseases', [])) or 'None'}")
        print(f"    Permissions    : {', '.join(p.get('permissions_granted', [])) or 'None'}")
        print(f"    Registered At  : {p.get('created_at') or 'N/A'}")
        print("-" * 42)

    return patients

async def search_user():
    db = get_db()
    query = input("\nEnter Patient ID, Phone Number, or Name to search: ").strip()
    if not query:
        print("[!] Search query cannot be empty.")
        return None

    patient = await db["patients"].find_one({
        "$or": [
            {"patient_id": {"$regex": query, "$options": "i"}},
            {"phone_number": {"$regex": query, "$options": "i"}},
            {"full_name": {"$regex": query, "$options": "i"}},
            {"first_name": {"$regex": query, "$options": "i"}},
            {"last_name": {"$regex": query, "$options": "i"}}
        ]
    })

    if not patient:
        print(f"\n[!] No user found matching query: '{query}'")
        return None

    patient.pop("_id", None)
    print("\n==========================================")
    print("  USER DETAILS FOUND")
    print("==========================================")
    for k, v in patient.items():
        print(f"  {k:20}: {v}")
    print("==========================================")
    return patient

async def edit_user():
    db = get_db()
    patient = await search_user()
    if not patient:
        return

    patient_id = patient["patient_id"]
    print(f"\n--- Editing User: {patient.get('full_name')} ({patient_id}) ---")
    print("(Press ENTER to keep existing value for any field)")

    new_first = input(f"First Name [{patient.get('first_name')}]: ").strip()
    new_last = input(f"Last Name [{patient.get('last_name')}]: ").strip()
    new_phone = input(f"Phone Number [{patient.get('phone_number')}]: ").strip()
    new_email = input(f"Email [{patient.get('email')}]: ").strip()
    new_age_str = input(f"Age [{patient.get('age')}]: ").strip()
    new_gender = input(f"Gender [{patient.get('gender')}]: ").strip()
    new_bg = input(f"Blood Group [{patient.get('blood_group')}]: ").strip()
    new_chronic_str = input(f"Chronic Diseases (comma-separated) [{', '.join(patient.get('chronic_diseases', []))}]: ").strip()

    updates = {}
    if new_first:
        updates["first_name"] = new_first
    if new_last:
        updates["last_name"] = new_last
    
    first = updates.get("first_name", patient.get("first_name", ""))
    last = updates.get("last_name", patient.get("last_name", ""))
    updates["full_name"] = f"{first} {last}".strip()

    if new_phone:
        updates["phone_number"] = new_phone
    if new_email:
        updates["email"] = new_email
    if new_age_str:
        try:
            updates["age"] = int(new_age_str)
        except ValueError:
            print("[!] Invalid age entered, keeping existing value.")
    if new_gender:
        updates["gender"] = new_gender
    if new_bg:
        updates["blood_group"] = new_bg
    if new_chronic_str:
        updates["chronic_diseases"] = [c.strip() for c in new_chronic_str.split(",") if c.strip()]

    if not updates:
        print("[!] No changes made.")
        return

    result = await db["patients"].update_one(
        {"patient_id": patient_id},
        {"$set": updates}
    )

    if result.modified_count > 0:
        print(f"\n[SUCCESS] User '{patient_id}' updated successfully in MongoDB!")
    else:
        print("\n[!] User record updated or unchanged.")

async def remove_user():
    db = get_db()
    patient = await search_user()
    if not patient:
        return

    patient_id = patient["patient_id"]
    name = patient.get("full_name")

    confirm = input(f"\n[WARNING] Are you sure you want to PERMANENTLY REMOVE user '{name}' ({patient_id}) from MongoDB? (type 'yes' to confirm): ").strip().lower()
    
    if confirm == "yes":
        result = await db["patients"].delete_one({"patient_id": patient_id})
        if result.deleted_count > 0:
            print(f"\n[SUCCESS] User '{name}' ({patient_id}) was completely deleted from database.")
        else:
            print(f"\n[!] Failed to delete user '{patient_id}'.")
    else:
        print("\n[CANCELLED] User deletion cancelled.")

async def main():
    while True:
        print("\n==========================================")
        print("   HEALTHCARE USER DATABASE MANAGER")
        print("==========================================")
        print("  1. List All Users")
        print("  2. Search User by ID / Phone / Name")
        print("  3. Edit / Update User Details")
        print("  4. Remove / Delete User from Database")
        print("  5. Exit")
        print("==========================================")

        choice = input("Select an option (1-5): ").strip()

        if choice == "1":
            await list_users()
        elif choice == "2":
            await search_user()
        elif choice == "3":
            await edit_user()
        elif choice == "4":
            await remove_user()
        elif choice == "5":
            print("\nExiting User Manager. Goodbye!\n")
            break
        else:
            print("[!] Invalid option. Please select 1 to 5.")

if __name__ == "__main__":
    asyncio.run(main())
