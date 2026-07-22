import re
from typing import Optional
from google import genai
from google.genai import types

class SystemicClassifier:
    """
    Hybrid Systemic Category Classifier for Medical Queries & Reports.
    
    Architecture:
    1. Fast Rule-Based Keyword Engine: Instantly matches medical terms without network latency.
    2. Gemini LLM Fallback: If keyword check defaults to GENERAL or detects complex phrasing,
       triggers a quick 1-sentence classification call to Gemini to reliably assign the exact systemic_category.
    """

    VALID_CATEGORIES = {
        "CARDIOVASCULAR",
        "RESPIRATORY",
        "ENDOCRINE",
        "GASTROINTESTINAL",
        "NEUROLOGICAL",
        "MUSCULOSKELETAL",
        "GENERAL"
    }

    KEYWORD_MATRIX = {
        "CARDIOVASCULAR": [
            "heart", "chest pain", "pulse", "dizziness", "blood pressure", "hypertension", 
            "angina", "palpitations", "cholesterol", "ecg", "cardiac", "arrhythmia", "tachycardia"
        ],
        "RESPIRATORY": [
            "breath", "shortness of breath", "cough", "lung", "asthma", "wheezing", "spo2", 
            "oxygen", "pneumonia", "respiratory", "phlegm", "chest tightness", "bronchitis"
        ],
        "ENDOCRINE": [
            "glucose", "blood sugar", "hba1c", "diabetes", "thyroid", "insulin", "diabetic", 
            "metabolism", "tsh", "pancreas", "endocrine"
        ],
        "GASTROINTESTINAL": [
            "stomach", "abdomen", "nausea", "liver", "digestion", "vomiting", "acid reflux", 
            "diarrhea", "gut", "gastric", "ulcer", "constipation"
        ],
        "NEUROLOGICAL": [
            "headache", "migraine", "brain", "numbness", "seizure", "stroke", "vertigo", 
            "paralysis", "nerve", "dizzy", "fainting", "neuropathy"
        ],
        "MUSCULOSKELETAL": [
            "joint", "bone", "muscle", "arthritis", "back pain", "fracture", "knee pain", 
            "spine", "ligament", "sprain", "stiffness"
        ]
    }

    @classmethod
    def classify_fast(cls, text: str) -> str:
        """Rule-based keyword classification matching."""
        if not text or not text.strip():
            return "GENERAL"

        lower_text = text.lower()
        scores = {cat: 0 for cat in cls.KEYWORD_MATRIX}

        for category, keywords in cls.KEYWORD_MATRIX.items():
            for kw in keywords:
                if re.search(r'\b' + re.escape(kw) + r'\b', lower_text):
                    scores[category] += 2
                elif kw in lower_text:
                    scores[category] += 1

        best_category = max(scores, key=scores.get)
        if scores[best_category] > 0:
            return best_category

        return "GENERAL"

    @classmethod
    def classify_hybrid(cls, text: str) -> str:
        """
        Hybrid entry point:
        Rule-based first -> Gemini Fallback if GENERAL or ambiguous phrasing.
        """
        fast_category = cls.classify_fast(text)
        
        # If fast keyword match found a specific medical category, return it instantly
        if fast_category != "GENERAL":
            return fast_category

        # Fallback to Gemini LLM for complex / ambiguous queries
        try:
            ai_client = genai.Client()
            prompt = f"""
            Classify the following medical symptom query into EXACTLY ONE of these categories:
            - CARDIOVASCULAR
            - RESPIRATORY
            - ENDOCRINE
            - GASTROINTESTINAL
            - NEUROLOGICAL
            - MUSCULOSKELETAL
            - GENERAL

            QUERY: "{text}"

            Respond ONLY with the exact single category name from the list above. No explanations.
            """

            response = ai_client.models.generate_content(
                model="gemini-2.5-flash",
                contents=prompt,
                config=types.GenerateContentConfig(
                    temperature=0.0,
                    max_output_tokens=10
                )
            )

            raw_output = (response.text or "").strip().upper()
            cleaned_category = re.sub(r'[^A-Z]', '', raw_output)

            for cat in cls.VALID_CATEGORIES:
                if cat in cleaned_category:
                    return cat

        except Exception as e:
            print(f"[SystemicClassifier] Gemini classification fallback warning: {e}")

        return "GENERAL"
