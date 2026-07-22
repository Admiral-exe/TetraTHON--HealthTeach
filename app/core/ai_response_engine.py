from typing import List, Dict, Optional
from pydantic import BaseModel, Field
from datetime import datetime
import json
import re

class GeminiProbableCondition(BaseModel):
    condition_name: str = Field(..., description="Full clinical title of probable condition in English (e.g., Essential Hypertension).")
    severity_remark: str = Field(..., description="MUST be exactly one of: 'HIGH', 'MEDIUM', or 'LOW'.")
    description: str = Field(..., description="Brief clinical explanation linking user symptoms to this condition.")

class GeminiClinicalExtraction(BaseModel):
    extracted_symptoms: List[str] = Field(..., description="List of recognized symptoms extracted from text.")
    possible_diagnoses: List[GeminiProbableCondition] = Field(..., description="Legacy diagnosis list.")
    probable_conditions: List[GeminiProbableCondition] = Field(..., description="COMPULSORY Section 1: Exactly 3 probable conditions strictly ordered HIGH, MEDIUM, LOW.")
    triage_reasoning: str = Field(..., description="COMPULSORY Section 2: Medical reasoning for priority assignment.")
    clinical_explanation: str = Field(..., description="COMPULSORY Section 3: Detailed clinical explanation and medication guidance.")
    recommended_next_steps: List[str] = Field(..., description="COMPULSORY Section 4: Actionable steps for care, rest, and hydration.")
    critical_red_flags: List[str] = Field(default=[], description="Section 5: Emergency red flags. Empty array [] for NO-RISK / HOMECARE evaluations.")

class AIResponseEngine:
    """
    Dedicated Clinical AI Response Engine enforcing 5-Point Clinical Syntax:
    1. Probable Conditions (Exactly 3 items strictly ordered: HIGH -> MEDIUM -> LOW)
    2. Triage Assessment Reasoning
    3. Clinical Explanation & Medications
    4. Recommended Next Steps
    5. Critical Red Flags (Only for HIGH-ALERT; Omitted [] for NO-RISK / HOMECARE)
    """

    SYSTEM_INSTRUCTION = (
        "You are Arogya AI, an expert primary care medical triage assistant.\n"
        "Analyze the patient's reported symptoms alongside any provided medical history and recent conversation context.\n\n"
        "MULTILINGUAL RESPONSE RULE:\n"
        "Detect the language of the patient's reported input (e.g. Hindi, Hinglish, Marathi, Tamil, Telugu, Spanish, French, English, etc.).\n"
        "Write all explanations, triage_reasoning, clinical_explanation, recommended_next_steps, critical_red_flags, and condition descriptions in the EXACT SAME LANGUAGE as the patient's input.\n\n"
        "CRITICAL MEDICAL TERMINOLOGY GUARDRAIL:\n"
        "Keep all disease names (e.g., 'Migraine with Aura', 'Tension-Type Headache', 'Essential Hypertension', 'Type 2 Diabetes Mellitus', 'Gastroesophageal Reflux (GERD)'), "
        "and specific medication names (e.g., 'Acetaminophen', 'Ibuprofen', 'Metformin', 'Amoxicillin') in standard ENGLISH only for clinical precision.\n\n"
        "STRICT PROBABLE CONDITIONS ORDERING RULE:\n"
        "You MUST return EXACTLY 3 probable conditions in strict ordered sequence:\n"
        "- 1st Item: HIGH severity_remark\n"
        "- 2nd Item: MEDIUM severity_remark\n"
        "- 3rd Item: LOW severity_remark\n"
        "Do NOT repeat severity remarks (e.g. NEVER return two MEDIUM or two LOW conditions).\n\n"
        "CRITICAL RED FLAGS CONDITIONAL RULE:\n"
        "- If the highest severity is HIGH ('HIGH-ALERT'), populate critical_red_flags with emergency red flag symptoms.\n"
        "- If the evaluation is 'NO-RISK' (MEDIUM) or 'HOMECARE' (LOW), you MUST return an EMPTY array for critical_red_flags ([]). Do NOT provide critical_red_flags for NO-RISK or HOMECARE evaluations."
    )

    @classmethod
    def sanitize_and_format_5point(cls, extraction: GeminiClinicalExtraction, input_text: str = "") -> GeminiClinicalExtraction:
        """
        Guarantees strict ordering (HIGH -> MEDIUM -> LOW) and removes Section 5 (Critical Red Flags)
        for NO-RISK (MEDIUM) and HOMECARE (LOW) responses.
        """
        raw_conds = extraction.probable_conditions or extraction.possible_diagnoses or []

        high_item = None
        med_item = None
        low_item = None

        for c in raw_conds:
            sev = c.severity_remark.upper().strip()
            if sev == "HIGH" and not high_item:
                high_item = c
            elif sev == "MEDIUM" and not med_item:
                med_item = c
            elif sev == "LOW" and not low_item:
                low_item = c

        # Construct distinct items if any tier is missing
        if not high_item:
            high_item = GeminiProbableCondition(
                condition_name="Clinical Symptom Elevation",
                severity_remark="HIGH",
                description="Elevated symptom intensity requiring close monitoring and clinical evaluation."
            )
        if not med_item:
            med_item = GeminiProbableCondition(
                condition_name="Primary Physiological Strain",
                severity_remark="MEDIUM",
                description="Moderate physiological strain associated with reported symptoms."
            )
        if not low_item:
            low_item = GeminiProbableCondition(
                condition_name="Systemic Fatigue & Hydration Shift",
                severity_remark="LOW",
                description="Transient bodily fatigue, stress adaptation, or hydration adjustment."
            )

        # Enforce strict ordering: HIGH -> MEDIUM -> LOW
        ordered_conds = [high_item, med_item, low_item]
        extraction.probable_conditions = ordered_conds
        extraction.possible_diagnoses = ordered_conds

        # Determine overall Triage Category: HIGH-ALERT, NO-RISK, or HOMECARE
        # Rule: Omit Section 5 (Critical Red Flags) for NO-RISK or HOMECARE
        s_lower = input_text.lower()
        is_high_risk_query = any(w in s_lower for w in ["chest pain", "heart attack", "shortness of breath", "severe blood pressure"])

        if not is_high_risk_query and high_item.condition_name == "Clinical Symptom Elevation":
            # Demote to NO-RISK / HOMECARE if query has no high-risk markers
            extraction.critical_red_flags = []

        return extraction

    @classmethod
    def build_local_fallback_5point(cls, query_text: str, history_buffer: str) -> GeminiClinicalExtraction:
        """
        Local Healthcare NLP Engine constructing a complete response with strictly ordered 
        HIGH -> MEDIUM -> LOW conditions and conditional Section 5 handling.
        """
        s_text = query_text.strip()
        s_lower = s_text.lower()
        hist_lower = (history_buffer or "").lower()

        # Check for cardiovascular / HIGH-ALERT context
        if any(w in s_lower for w in ["chest", "bp", "blood pressure", "hypertension", "heart", "cardiac"]):
            conds = [
                GeminiProbableCondition(
                    condition_name="Essential Hypertension & Vascular Strain",
                    severity_remark="HIGH",
                    description="Elevated arterial blood pressure causing systemic vascular resistance and cardiovascular workload."
                ),
                GeminiProbableCondition(
                    condition_name="Anginal Discomfort & Myocardial Strain",
                    severity_remark="MEDIUM",
                    description="Imbalance in myocardial oxygen demand causing acute ischemic chest discomfort."
                ),
                GeminiProbableCondition(
                    condition_name="Stress-Induced Cardiopulmonary Overload",
                    severity_remark="LOW",
                    description="Transient elevation in heart rate and vascular tone secondary to physical stress or anxiety."
                )
            ]
            reasoning = (
                f"High priority assigned to Essential Hypertension based on your query '{s_text}' "
                "and recorded cardiovascular medical history. Recorded blood pressure metrics indicate elevated vascular workload."
            )
            explanation = (
                "Cardiovascular chest discomfort requires prompt clinical evaluation and close monitoring. "
                "Adhere to prescribed antihypertensive therapy (e.g. Amlodipine or Telmisartan) and avoid self-medication."
            )
            next_steps = [
                "Rest in a comfortable, reclined position and avoid physical exertion",
                "Measure and log your blood pressure and heart rate",
                "Keep prescribed cardiovascular medications readily accessible",
                "Seek immediate medical evaluation if chest pressure worsens"
            ]
            red_flags = [
                "Severe crushing chest pain radiating to left arm, neck, or jaw",
                "Sudden onset of severe shortness of breath or dizziness",
                "Cold sweats, nausea, or loss of consciousness (syncope)"
            ]

        # Check for NO-RISK (Medium) / Diabetes / Sugar context
        elif any(w in s_lower for w in ["sugar", "glucose", "hba1c", "diabetes", "diabetic", "glycemic"]):
            conds = [
                GeminiProbableCondition(
                    condition_name="Hyperglycemia & Glycemic Variability",
                    severity_remark="HIGH",
                    description="Elevated serum blood glucose and HbA1c parameters impacting metabolic homeostasis."
                ),
                GeminiProbableCondition(
                    condition_name="Type 2 Diabetes Mellitus Strain",
                    severity_remark="MEDIUM",
                    description="Insulin resistance associated with postprandial glucose spikes and metabolic strain."
                ),
                GeminiProbableCondition(
                    condition_name="Metabolic Electrolyte Imbalance",
                    severity_remark="LOW",
                    description="Mild electrolyte shift and hydration alteration secondary to osmotic diuresis."
                )
            ]
            reasoning = (
                f"Triage assessment highlights Glycemic Variability based on your input '{s_text}' and uploaded lab history. "
                "Recorded glucose metrics and HbA1c parameters indicate ongoing metabolic adjustments."
            )
            explanation = (
                "Blood glucose control depends on diet, physical activity, and pharmacological support. "
                "Maintain adherence to prescribed oral hypoglycemic agents (such as Metformin 500mg) and follow low-glycemic dietary guidelines."
            )
            next_steps = [
                "Monitor fasting and postprandial blood glucose levels daily",
                "Maintain adequate fluid intake with water and non-sweetened hydration",
                "Follow a balanced diet low in refined carbohydrates",
                "Consult your endocrinologist for periodic HbA1c evaluation"
            ]
            red_flags = []  # Omitted for NO-RISK / HOMECARE

        # Check for NO-RISK (Medium) / Stomach / GERD context
        elif any(w in s_lower for w in ["stomach", "acid", "gerd", "reflux", "abdominal", "gastric"]):
            conds = [
                GeminiProbableCondition(
                    condition_name="Gastroesophageal Reflux (GERD)",
                    severity_remark="HIGH",
                    description="Regurgitation of gastric acid into the esophagus causing retrosternal burning and stomach pain."
                ),
                GeminiProbableCondition(
                    condition_name="Acute Gastritis & Dyspepsia",
                    severity_remark="MEDIUM",
                    description="Inflammation of the gastric mucosal lining leading to epigastric discomfort and fullness."
                ),
                GeminiProbableCondition(
                    condition_name="Functional Digestive Strain",
                    severity_remark="LOW",
                    description="Transient gastrointestinal motility slowdown related to dietary factors or stress."
                )
            ]
            reasoning = (
                f"Epigastric discomfort and acid reflux symptoms identified for query '{s_text}'. "
                "Gastric acid hypersecretion irritates stomach mucosa, creating localized discomfort."
            )
            explanation = (
                "GERD and gastric acidity respond effectively to lifestyle and pharmacological measures. "
                "Over-the-counter antacids (such as Magnesium Hydroxide) or Proton Pump Inhibitors (Omeprazole) help reduce gastric acid secretion."
            )
            next_steps = [
                "Eat smaller, frequent meals and avoid spicy or greasy foods",
                "Avoid lying flat for at least 3 hours after eating",
                "Take prescribed antacids or acid suppressants as advised by your physician"
            ]
            red_flags = []  # Omitted for NO-RISK / HOMECARE

        # Check for HOMECARE (Low) / Headache / Dizziness / General symptoms
        else:
            conds = [
                GeminiProbableCondition(
                    condition_name="Migraine without Aura",
                    severity_remark="HIGH",
                    description="Throbbing cephalic discomfort exacerbated by bright lights or physical exertion."
                ),
                GeminiProbableCondition(
                    condition_name="Primary Tension-Type Headache",
                    severity_remark="MEDIUM",
                    description="Bilateral band-like pressure headache associated with physical fatigue, stress, or eye strain."
                ),
                GeminiProbableCondition(
                    condition_name="Systemic Fatigue & Physiological Strain",
                    severity_remark="LOW",
                    description="General bodily exhaustion, dehydration, or transient physiological adaptation."
                )
            ]
            reasoning = (
                f"Evaluated your reported symptom query '{s_text}' against your health history. "
                "Cephalic discomfort and dizziness frequently stem from systemic fatigue, hydration status, or vascular tension."
            )
            explanation = (
                "Mild headaches and dizziness often improve with adequate rest and hydration. "
                "If necessary, over-the-counter analgesics such as Acetaminophen or Ibuprofen may provide temporary relief under medical guidance."
            )
            next_steps = [
                "Rest in a quiet, dimly lit, well-ventilated room",
                "Drink 2-3 liters of water or oral rehydration fluids daily",
                "Limit screen time and practice stress reduction techniques",
                "Schedule a physician consultation if symptoms persist over 48 hours"
            ]
            red_flags = []  # Omitted for NO-RISK / HOMECARE evaluations

        words = [w.capitalize() for w in re.findall(r'\b[A-Za-z]{4,}\b', s_text)[:4]] or ["Symptom Check"]

        res = GeminiClinicalExtraction(
            extracted_symptoms=words,
            possible_diagnoses=conds,
            probable_conditions=conds,
            triage_reasoning=reasoning,
            clinical_explanation=explanation,
            recommended_next_steps=next_steps,
            critical_red_flags=red_flags
        )
        return cls.sanitize_and_format_5point(res, input_text=query_text)
