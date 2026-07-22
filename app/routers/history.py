# app/routers/history.py
from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from app.models.schemas import MedicalFileSanitizeResponse
from app.core.extractor import extract_text_from_pdf
from app.core.security_scrubber import SecurityScrubber
from app.core.disease_data import DISEASE_SEVERITY_MATRIX

router = APIRouter(prefix="/history", tags=["Phase 3: Historical Health Analytics"])

@router.post("/sanitize-file", response_model=MedicalFileSanitizeResponse)
async def sanitize_uploaded_medical_file(
    user_token: str = Form(..., description="Anonymized token linking this action to the mobile device."),
    file: UploadFile = File(..., description="Raw PDF report or medical record sheet.")
):
    """
    Accepts raw medical file uploads, parses textual parameters, 
    and sanitizes PII/PHI metrics seamlessly before system ingestion.
    """
    # Verify file formats safely
    if not file.filename.endswith('.pdf'):
        raise HTTPException(status_code=400, detail="Invalid layout standard. Only PDF reports are accepted currently.")
        
    try:
        # Read the uploaded file object into memory memory
        file_bytes = await file.read()
        
        # Execute structural extraction
        raw_text = extract_text_from_pdf(file_bytes)
        
        if not raw_text.strip() or "Extraction Failure" in raw_text:
            raise HTTPException(status_code=422, detail="Unable to extract clear textual lines from the document.")
            
        # Run through the privacy protection sanitization engine
        scrub_res = SecurityScrubber.anonymize_medical_text(raw_text)
        clean_clinical_text = scrub_res["scrubbed_text"]
        
        # Cross-reference words inside the clean text against our 100+ disease matrix keys
        detected_indicators = []
        clean_text_lower = clean_clinical_text.lower().replace("_", " ")
        
        for disease in DISEASE_SEVERITY_MATRIX.keys():
            standard_name = disease.replace("_", " ")
            if standard_name in clean_text_lower:
                detected_indicators.append(disease)
                
        return MedicalFileSanitizeResponse(
            user_token=user_token,
            file_name=file.filename,
            extracted_text_preview=raw_text[:200] + "...",
            scrubbed_clinical_text=clean_clinical_text,
            detected_indicators=list(set(detected_indicators))
        )
        
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"File ingestion pipeline error: {str(e)}")


@router.get("/{patient_id}")
async def get_patient_history_by_id(patient_id: str):
    """
    Retrieves full patient profile and medical report history by patient_id.
    """
    from app.database import db
    if db is None:
        raise HTTPException(status_code=500, detail="Database connection uninitialized")
    
    pid = patient_id.upper().strip()
    patient = await db["patients"].find_one({"patient_id": pid})
    if not patient:
        raise HTTPException(status_code=404, detail=f"Patient with ID '{patient_id}' not found")
    
    patient.pop("_id", None)
    return patient