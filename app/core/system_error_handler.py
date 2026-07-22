from fastapi import HTTPException
from pydantic import BaseModel, Field
from typing import List

class SystemErrorNotice(BaseModel):
    error_code: str = Field(..., description="Unique error code (e.g. SERVICE_MAINTENANCE, LLM_QUOTA_EXCEEDED).")
    message: str = Field(..., description="Short 1-2 line user-facing status message.")
    details: str = Field(..., description="Technical detail or guidance.")

class SystemErrorHandler:
    """
    Dedicated System Maintenance & Network Error Handler.
    Kept SEPARATE from AI Clinical Responses to prevent confusing fake diagnoses.
    """

    @classmethod
    def get_maintenance_exception(cls, detail: str = "Arogya AI is currently under maintenance. Please try again in a few moments.") -> HTTPException:
        return HTTPException(
            status_code=503,
            detail=detail
        )

    @classmethod
    def build_maintenance_notice(cls) -> dict:
        return {
            "error_code": "SERVICE_MAINTENANCE",
            "message": "Arogya AI is currently under maintenance. Please try again in a few moments.",
            "details": "Backend service update in progress. Normal operation will resume shortly."
        }
