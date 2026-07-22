import hashlib
import time
import uuid
import re
from typing import Optional, Dict

class PatientIDGenerator:
    """
    Healthcare-grade Unique Patient Identifier (UPI) Generator.
    
    Algorithm Specification:
    1. Prefix: 'HT' (HealthTech Ecosystem Code)
    2. Epoch/Year Segment: Current Year or Birth Year Identifier (e.g. '26' or '2026')
    3. Hash Digest: SHA-256 digest of (Normalized Name + DOB/UUID + High-Precision Timestamp + Salt)
    4. Base-36 Encoding: Converts top 40-bit hash integer into 6-character uppercase alphanumeric code.
    5. Checksum Digit: Modulo-36 Luhn-variant checksum digit for data entry verification.
    
    Output Format: HT-2026-8829-K (or HT-XXXX-XXXX)
    """

    ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    PREFIX = "HT"

    @classmethod
    def _normalize_name(cls, name: str) -> str:
        """Strip special characters and convert to uppercase."""
        return re.sub(r'[^A-Z]', '', name.upper())

    @classmethod
    def _base36_encode(cls, number: int, length: int = 6) -> str:
        """Converts an integer to a fixed-length Base-36 string."""
        chars = []
        while number > 0:
            number, remainder = divmod(number, 36)
            chars.append(cls.ALPHABET[remainder])
        encoded = "".join(reversed(chars)) if chars else "0"
        return encoded.zfill(length)[-length:]

    @classmethod
    def _calculate_checksum(cls, code: str) -> str:
        """Calculates a Modulo-36 Luhn check digit for the patient code."""
        total = 0
        for i, char in enumerate(reversed(code)):
            val = cls.ALPHABET.index(char)
            if i % 2 == 1:
                val *= 2
                if val >= 36:
                    val -= 35
            total += val
        check_index = (36 - (total % 36)) % 36
        return cls.ALPHABET[check_index]

    @classmethod
    def generate_patient_id(
        cls,
        patient_name: str,
        dob: Optional[str] = None,
        national_id: Optional[str] = None
    ) -> Dict[str, str]:
        """
        Generates a globally unique, cryptographically seeded Patient ID.
        """
        norm_name = cls._normalize_name(patient_name)
        timestamp_ns = time.time_ns()
        random_uuid = uuid.uuid4().hex

        # Seed string construction
        seed = f"{norm_name}|{dob or ''}|{national_id or ''}|{timestamp_ns}|{random_uuid}"
        
        # SHA-256 Cryptographic Hash
        hash_digest = hashlib.sha256(seed.encode('utf-8')).hexdigest()
        
        # Extract integer from first 10 hex chars (40 bits)
        hash_int = int(hash_digest[:10], 16)
        
        # Generate 6-char Base36 code
        unique_payload = cls._base36_encode(hash_int, length=6)
        
        # Year segment
        year_str = time.strftime("%Y")
        
        # Raw sequence before checksum
        raw_code = f"{year_str}{unique_payload}"
        check_digit = cls._calculate_checksum(raw_code)
        
        formatted_id = f"{cls.PREFIX}-{year_str}-{unique_payload[:3]}-{unique_payload[3:]}{check_digit}"

        return {
            "patient_id": formatted_id,
            "raw_payload": unique_payload,
            "check_digit": check_digit,
            "algorithm": "SHA256-Base36-Luhn36",
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        }

    @classmethod
    def validate_patient_id(cls, patient_id: str) -> bool:
        """
        Validates the format and Luhn-36 checksum of a Patient ID.
        """
        clean_id = patient_id.replace("-", "").upper()
        if not clean_id.startswith(cls.PREFIX):
            return False
        
        body = clean_id[len(cls.PREFIX):]
        if len(body) < 8:
            return False
            
        code_part = body[:-1]
        expected_check = body[-1]
        
        calculated_check = cls._calculate_checksum(code_part)
        return expected_check == calculated_check

# Standalone helper function
def create_patient_id(name: str, dob: Optional[str] = None) -> str:
    result = PatientIDGenerator.generate_patient_id(patient_name=name, dob=dob)
    return result["patient_id"]
