import re
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from google import genai
from google.genai import types
from dotenv import load_dotenv

from app.models.schemas import TriageRequest, TriageResponse, PredictedCondition, ProbableConditionItem
from app.core.rules import evaluate_critical_vitals
from app.core.disease_data import get_disease_severity
from app.core.memory import format_langchain_context_window

load_dotenv()
router = APIRouter(prefix="/triage", tags=["Phase 1: Urgent Triage"])
ai_client = genai.Client()

from app.core.ai_response_engine import AIResponseEngine, GeminiProbableCondition, GeminiClinicalExtraction

@router.post("/analyze", response_model=TriageResponse)
async def analyze_symptoms(payload: TriageRequest):
    # Step A: Local Priority Vital Rules Checks
    is_emergency, breached_flags = evaluate_critical_vitals(payload)
    
    if is_emergency:
        return TriageResponse(
            is_emergency_bypass=True,
            extracted_symptoms=["Critical Vitals Deviation"],
            probable_conditions=[
                ProbableConditionItem(
                    condition_name="Hypertensive Crisis / Respiratory Distress",
                    severity_remark="HIGH",
                    description="Physiological vital limits breached."
                )
            ],
            triage_reasoning="Critical physiological vital readings require immediate medical intervention.",
            clinical_explanation="Emergency vital thresholds exceeded. Immediate hospital emergency room admission is indicated.",
            recommended_next_steps=["Call emergency services (108) immediately", "Do not attempt self-medication"],
            critical_red_flags=breached_flags,
            predicted_diagnoses=[
                PredictedCondition(
                    condition_name="hypertensive_crisis" if "Hypertensive" in "".join(breached_flags) else "acute_respiratory_distress_syndrome",
                    probability_score=1.0,
                    base_severity_score=9.5,
                    calculated_risk_index=9.5
                )
            ],
            plain_language_rationale="Your recorded vitals represent a high-severity physiological threshold. Do not wait for standard diagnostic routines.",
            red_flags=breached_flags
        )
        
    # Step B: Contextual LLM Processing + Dataset Severity Indexing Matrix
    try:
        # Build dynamic background context instruction if history toggle is enabled
        history_buffer = ""
        if payload.include_medical_history and payload.patient_id:
            from app.core.medical_history_retriever import MedicalHistoryRetriever
            history_res = await MedicalHistoryRetriever.get_targeted_history_context(
                patient_id=payload.patient_id,
                query_text=payload.symptoms_text,
                limit=5
            )
            if history_res["history_context_str"]:
                history_buffer = (
                    f"\n[TARGETED MEDICAL HISTORY RECORD - CATEGORY: {history_res['target_category']}]:\n"
                    f"{history_res['history_context_str']}\n"
                )
        elif payload.scrubbed_history_context:
            history_buffer = f"\n[DE-IDENTIFIED PATIENT MEDICAL HISTORY RECORD]:\n{payload.scrubbed_history_context}\n"

        # Apply LangChain conversation memory (last 3 turns context window)
        langchain_memory_buffer = format_langchain_context_window(payload.chat_history or [], k=3)

        from app.core.ai_response_engine import AIResponseEngine, GeminiClinicalExtraction

        prompt = f"{history_buffer}\n{langchain_memory_buffer}\nCurrent Patient Reported Symptoms: '{payload.symptoms_text}'"
        
        try:
            response = await ai_client.aio.models.generate_content(
                model='gemini-2.5-flash',
                contents=prompt,
                config=types.GenerateContentConfig(
                    system_instruction=AIResponseEngine.SYSTEM_INSTRUCTION,
                    response_mime_type="application/json",
                    response_schema=GeminiClinicalExtraction,
                    temperature=0.2,
                ),
            )
            llm_data = GeminiClinicalExtraction.model_validate_json(response.text)
        except Exception as err:
            print(f"[TriageRouter] LLM API warning ({err}). Building 5-point clinical synthesis locally.")
            llm_data = AIResponseEngine.build_local_fallback_5point(payload.symptoms_text, history_buffer)

        # Enforce strict ordering (HIGH -> MEDIUM -> LOW) & conditional Section 5 removal
        llm_data = AIResponseEngine.sanitize_and_format_5point(llm_data, input_text=payload.symptoms_text)

        # Cross-reference the LLM outputs against our Master Disease Dataset Matrix
        final_diagnoses = []
        for diag in (llm_data.possible_diagnoses or llm_data.probable_conditions):
            base_severity = get_disease_severity(diag.condition_name)
            calculated_risk = round(0.85 * base_severity, 2)
            final_diagnoses.append(
                PredictedCondition(
                    condition_name=diag.condition_name,
                    probability_score=0.85,
                    base_severity_score=base_severity,
                    calculated_risk_index=calculated_risk
                )
            )
            
        final_diagnoses.sort(key=lambda x: x.calculated_risk_index, reverse=True)
        
        # Convert llm_data.probable_conditions to ProbableConditionItem list
        mapped_probable = [
            ProbableConditionItem(
                condition_name=item.condition_name,
                severity_remark=item.severity_remark.upper() if item.severity_remark.upper() in ["HIGH", "MEDIUM", "LOW"] else "MEDIUM",
                description=item.description
            )
            for item in llm_data.probable_conditions
        ]

        return TriageResponse(
            is_emergency_bypass=False,
            extracted_symptoms=llm_data.extracted_symptoms,
            probable_conditions=mapped_probable,
            triage_reasoning=llm_data.triage_reasoning,
            clinical_explanation=llm_data.clinical_explanation,
            recommended_next_steps=llm_data.recommended_next_steps,
            critical_red_flags=llm_data.critical_red_flags,
            predicted_diagnoses=final_diagnoses,
            plain_language_rationale=llm_data.triage_reasoning,
            red_flags=llm_data.critical_red_flags
        )
    except Exception as e:
        print(f"[TriageRouter] Critical Endpoint Exception: {e}")
        from app.core.system_error_handler import SystemErrorHandler
        raise SystemErrorHandler.get_maintenance_exception()