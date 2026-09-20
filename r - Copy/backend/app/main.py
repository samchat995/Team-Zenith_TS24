"""
Neural Nexus — Backend API Entry Point.
AI-Based Cognitive Gaming and Memory Assistance Platform for Elderly Dementia Patients.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .database import engine, Base
from .routers import auth, patients, games, reminders, mood, memory, sync, healthcare, admin

# Automatically create all SQLite tables on startup
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="NEURAL NEXUS API",
    description=(
        "Backend API for Neural Nexus: AI-Based Cognitive Gaming and Memory Assistance Platform "
        "for Elderly Dementia Patients in the North Eastern Region (NER). "
        "Strictly provides cognitive engagement and caregiver assistance; zero medical/clinical diagnosis."
    ),
    version="1.0.0"
)

# CORS configuration allowing mobile apps and local web dashboards
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers (both with and without /api prefix for full client compatibility)
routers = [
    auth.router,
    patients.router,
    games.router,
    reminders.router,
    mood.router,
    memory.router,
    sync.router,
    healthcare.router,
    admin.router,
]
for r in routers:
    app.include_router(r)
    app.include_router(r, prefix="/api")


@app.get("/")
def root():
    return {
        "project": "NEURAL NEXUS",
        "subtitle": "Adaptive Cognitive Games + Memory Assistance",
        "tagline": "Small Steps. Stronger Memories.",
        "status": "ONLINE",
        "version": "1.0.0",
        "disclaimer": (
            "Neural Nexus is an engaging cognitive stimulation and memory assistance platform. "
            "It does not diagnose, treat, or replace professional medical evaluation."
        ),
        "docs_url": "/docs"
    }


@app.get("/health")
@app.get("/api/health")
def health_check():
    return {"status": "ok", "service": "NEURAL NEXUS API"}

