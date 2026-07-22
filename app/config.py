import os

class Settings:
    PROJECT_NAME: str = "HealthTech AI Companion Backend"
    API_V1_STR: str = "/api/v1"
    # The SDK automatically loads GEMINI_API_KEY from environment variables,
    # but we store a layout alias here just in case.
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")

settings = Settings()