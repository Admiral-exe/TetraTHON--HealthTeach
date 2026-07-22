# app/core/extractor.py
import pdfplumber
from io import BytesIO

def extract_text_from_pdf(file_bytes: bytes) -> str:
    """Extracts raw textual lines out of digital PDF report documents."""
    extracted_text = ""
    try:
        with pdfplumber.open(BytesIO(file_bytes)) as pdf:
            for page in pdf.pages:
                text = page.extract_text()
                if text:
                    extracted_text += text + "\n"
        return extracted_text.strip()
    except Exception as e:
        return f"PDF Extraction Failure: {str(e)}"