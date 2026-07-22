import asyncio
import os
from dotenv import load_dotenv
from motor.motor_asyncio import AsyncIOMotorClient

load_dotenv()

async def inspect_patients():
    mongo_url = os.getenv("MONGODB_URL")
    db_name = os.getenv("DATABASE_NAME", "healthtech_db")
    
    print(f"\n==========================================")
    print(f"  HealthTech MongoDB Patient Inspector")
    print(f"==========================================")
    print(f"Connecting to Database: '{db_name}'...")
    
    client = AsyncIOMotorClient(mongo_url)
    db = client[db_name]
    
    try:
        collections = await db.list_collection_names()
        if "patients" not in collections:
            print("\n[!] No 'patients' collection found yet.")
            print("-> Make sure your FastAPI backend is running (.\\.venv\\Scripts\\python.exe -m uvicorn app.main:app --reload)")
            print("   and you clicked 'Complete Setup' in the app.\n")
            return

        patients = await db["patients"].find().to_list(length=50)
        print(f"\n[SUCCESS] Total Saved Patients: {len(patients)}\n")
        
        for idx, p in enumerate(patients, 1):
            p.pop("_id", None)
            print(f"--- Patient Record #{idx} ---")
            print(f"  ID (patient_id)    : {p.get('patient_id')}")
            print(f"  Name               : {p.get('full_name')}")
            print(f"  Phone Number       : {p.get('phone_number')}")
            print(f"  Age / Gender       : {p.get('age')} yrs / {p.get('gender')}")
            print(f"  Blood Group        : {p.get('blood_group')}")
            print(f"  Email              : {p.get('email', 'None')}")
            print(f"  Chronic Diseases   : {p.get('chronic_diseases', [])}")
            print(f"  Consent Given      : {p.get('consent_given')}")
            print(f"  Permissions        : {p.get('permissions_granted', [])}")
            print(f"  Registered At      : {p.get('created_at')}")
            print("-" * 40)
            
    except Exception as err:
        print(f"[ERROR] Connection Error: {err}")


if __name__ == "__main__":
    asyncio.run(inspect_patients())
