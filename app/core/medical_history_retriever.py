import json
from typing import Dict, List, Optional
from app.database import db
from app.core.systemic_classifier import SystemicClassifier

class MedicalHistoryRetriever:
    """
    Targeted Database Query & Payload Grouping Engine.
    
    SYSTEMATIC FILTERING PIPELINE:
    1. Systemic Switch: Uses SystemicClassifier to detect target category for query (e.g. CARDIOVASCULAR).
    2. Targeted DB Query: Queries db["medical_reports"] for patient_id matching target category + GENERAL (latest first).
    3. Payload Grouping: Extracts ONLY clinical_summary and lab_vitals into a clean, compact JSON history block.
    """

    @classmethod
    async def get_targeted_history_context(
        cls, 
        patient_id: str, 
        query_text: str, 
        limit: int = 5
    ) -> Dict[str, any]:
        if not patient_id or not patient_id.strip():
            return {
                "target_category": "GENERAL",
                "matched_count": 0,
                "history_context_str": ""
            }

        pid = patient_id.upper().strip()

        # Step 1: Hybrid Systemic Category Classification
        target_category = SystemicClassifier.classify_hybrid(query_text)

        # Step 2: Targeted MongoDB Query
        matched_reports = []
        if db is not None:
            try:
                cursor = db["medical_reports"].find({
                    "patient_id": pid,
                    "systemic_category": {"$in": [target_category, "GENERAL"]}
                }).sort("uploaded_at", -1).limit(limit)

                matched_reports = await cursor.to_list(length=limit)
            except Exception as e:
                print(f"[HistoryRetriever] DB Query warning: {e}")

        # Fallback to checking patients collection if medical_reports is empty
        if not matched_reports and db is not None:
            try:
                patient_doc = await db["patients"].find_one({"patient_id": pid})
                if patient_doc and "medical_reports" in patient_doc:
                    raw_reports = patient_doc.get("medical_reports", [])
                    matched_reports = [
                        r for r in raw_reports 
                        if r.get("systemic_category", "GENERAL") in [target_category, "GENERAL"]
                    ][:limit]
            except Exception as e:
                print(f"[HistoryRetriever] Patient doc fallback warning: {e}")

        # Step 3: Payload Grouping (Extract ONLY clinical_summary & lab_vitals)
        compact_payload = []
        for r in matched_reports:
            compact_payload.append({
                "report_type": r.get("report_type", "Medical Report"),
                "report_date": r.get("report_date", "Recent"),
                "systemic_category": r.get("systemic_category", "GENERAL"),
                "clinical_summary": r.get("clinical_summary", ""),
                "lab_vitals": r.get("lab_vitals", [])
            })

        history_json_str = json.dumps(compact_payload, indent=2) if compact_payload else ""

        return {
            "target_category": target_category,
            "matched_count": len(compact_payload),
            "history_context_str": history_json_str
        }
