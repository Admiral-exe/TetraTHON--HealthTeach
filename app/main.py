# app/main.py
from fastapi import FastAPI
from app.database import db
from fastapi.middleware.cors import CORSMiddleware
from app.routers import triage, chronic, history, patient

app = FastAPI(
    title="HealthTech AI Triage Engine Backend",
    version="1.0.0",
    description="Production-grade core clinical data triage routing architecture."
)

# --- THE HACKATHON CORS PERIMETER CONFIGURATION ---
# This allows your Flutter app to communicate with the FastAPI endpoints smoothly
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r".*",  # Allows all host interfaces (Flutter Web, Android Emulator, Desktop, Production Cloud)
    allow_credentials=True,
    allow_methods=["*"],  # Allows POST, GET, OPTIONS, PUT requests
    allow_headers=["*"],  # Allows standard HTTP metadata headers
)

# Include the core production route controllers
app.include_router(triage.router, prefix="/api/v1")
app.include_router(chronic.router, prefix="/api/v1")
app.include_router(history.router, prefix="/api/v1")
app.include_router(patient.router)


@app.get("/")
async def root_status():
    return {
        "status": "operational",
        "engine": "Gemini 2.5 Flash",
        "disease_matrix_nodes": 105
    }