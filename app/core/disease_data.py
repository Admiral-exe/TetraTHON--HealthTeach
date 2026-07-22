# app/core/disease_data.py

DISEASE_SEVERITY_MATRIX = {
    # --- CARDIOVASCULAR & CIRCULATORY (1-20) ---
    "essential_hypertension": 3.0, "secondary_hypertension": 4.5, "hypertensive_crisis": 9.5,
    "coronary_artery_disease": 6.5, "myocardial_infarction": 10.0, "angina_pectoris": 6.0,
    "congestive_heart_failure": 7.5, "atrial_fibrillation": 5.5, "ventricular_tachycardia": 9.0,
    "bradycardia": 4.0, "pericarditis": 5.0, "myocarditis": 6.5, "deep_vein_thrombosis": 7.0,
    "pulmonary_embolism": 9.5, "peripheral_artery_disease": 4.5, "aortic_aneurysm": 8.5,
    "mitral_valve_prolapse": 3.5, "infective_endocarditis": 7.5, "cardiomyopathy": 6.8, "varicose_veins": 1.5,

    # --- RESPIRATORY SYSTEM (21-40) ---
    "acute_bronchitis": 2.5, "chronic_bronchitis": 4.5, "emphysema": 5.5, "asthma_exacerbation": 6.5,
    "copd_flare": 7.0, "bacterial_pneumonia": 6.0, "viral_pneumonia": 5.0, "aspiration_pneumonia": 7.5,
    "pulmonary_fibrosis": 6.0, "pneumothorax": 9.0, "sleep_apnea": 3.5, "allergic_rhinitis": 1.0,
    "sinusitis": 1.5, "pharyngitis": 1.5, "laryngitis": 1.5, "influenza": 3.0, "covid_19_severe": 7.0,
    "tuberculosis": 6.0, "pleurisy": 4.0, "acute_respiratory_distress_syndrome": 9.8,

    # --- GASTROINTESTINAL & HEPATIC (41-60) ---
    "gastroesophageal_reflux_disease": 2.0, "acute_gastritis": 2.5, "peptic_ulcer_disease": 4.0,
    "appendicitis": 8.5, "acute_cholecystitis": 7.0, "acute_pancreatitis": 8.0, "chronic_pancreatitis": 5.5,
    "ulcerative_colitis": 5.0, "crohns_disease": 5.0, "irritable_bowel_syndrome": 2.0,
    "diverticulitis": 5.5, "celiac_disease": 3.0, "hemorrhoids": 1.5, "cirrhosis_of_liver": 7.0,
    "acute_hepatitis_a": 4.0, "chronic_hepatitis_b": 5.0, "chronic_hepatitis_c": 5.0,
    "non_alcoholic_fatty_liver_disease": 2.5, "cholelithiasis": 4.0, "bowel_obstruction": 8.5,

    # --- NEUROLOGICAL & PSYCHIATRIC (61-80) ---
    "migraine_headache": 2.5, "tension_headache": 1.5, "cluster_headache": 4.0, "ischemic_stroke": 10.0,
    "hemorrhagic_stroke": 10.0, "transient_ischemic_attack": 7.5, "epilepsy_seizure": 6.5,
    "status_epilepticus": 9.5, "multiple_sclerosis": 5.5, "parkinsons_disease": 4.5,
    "alzheimers_dementia": 4.0, "meningitis_bacterial": 9.5, "encephalitis": 8.5,
    "peripheral_neuropathy": 3.0, "trigeminal_neuralgia": 4.0, "generalized_anxiety_disorder": 2.5,
    "major_depressive_disorder": 4.0, "bipolar_disorder": 4.5, "schizophrenia": 5.0, "panic_disorder": 3.5,

    # --- ENDOCRINE, RENAL & METABOLIC (81-105) ---
    "type_1_diabetes": 5.0, "type_2_diabetes": 3.5, "diabetic_ketoacidosis": 9.0,
    "hypoglycemia_severe": 7.5, "hypothyroidism": 2.0, "hyperthyroidism": 3.0,
    "chronic_kidney_disease_stage_3": 4.5, "chronic_kidney_disease_stage_5": 8.0,
    "acute_kidney_injury": 7.5, "nephrolithiasis": 5.0, "urinary_tract_infection": 2.5,
    "pyelonephritis": 5.5, "rheumatoid_arthritis": 4.0, "osteoarthritis": 2.0,
    "gouty_arthritis": 3.5, "systemic_lupus_erythematosus": 5.5, "osteoporosis": 2.5,
    "iron_deficiency_anemia": 2.0, "pernicious_anemia": 2.5, "aplastic_anemia": 7.0,
    "fibromyalgia": 3.0, "psoriasis": 2.0, "cellulitis": 4.5, "sepsis": 10.0, "anaphylaxis": 10.0
}

def get_disease_severity(disease_key: str) -> float:
    """Safely retrieves database severity scoring fallback metrics for unlisted vectors."""
    # Standardize string formatting to prevent matching failures
    normalized_key = disease_key.strip().lower().replace(" ", "_")
    return DISEASE_SEVERITY_MATRIX.get(normalized_key, 3.0) # Fallback to standard 3.0 if new/unmapped