"""
Game endpoints for Neural Nexus.
Catalog of 18 cognitive games and telemetry ingestion with real-time adaptive feedback.
"""
from typing import List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import User, Patient, Game, GameSession, AuditLog
from ..schemas import GameSessionCreate, GameSessionOut
from ..auth import get_current_user
from adaptive_engine.difficulty_engine import DifficultyEngine
from adaptive_engine.models import GameTelemetry
from adaptive_engine.recommendation_engine import RecommendationEngine

router = APIRouter(prefix="/games", tags=["Games"])
diff_engine = DifficultyEngine(min_level=1, max_level=5)
rec_engine = RecommendationEngine()


@router.get("", response_model=List[Dict[str, Any]])
def get_games_catalog():
    """Returns all 18 playable cognitive games categorized across domains."""
    return rec_engine.GAMES_CATALOG


@router.post("/session")
def record_game_session(
    payload: GameSessionCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Records a completed game session telemetry and invokes the Adaptive AI Engine.
    Returns the updated difficulty recommendation and non-diagnostic explanation.
    """
    patient = db.query(Patient).filter(Patient.id == payload.patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    # If patient role, check isolation
    if current_user.role == "PATIENT" and patient.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Unauthorized")

    new_session = GameSession(
        patient_id=payload.patient_id,
        game_id=payload.game_id,
        category=payload.category,
        level=payload.level,
        score=payload.score,
        accuracy=payload.accuracy,
        attempts=payload.attempts,
        mistakes=payload.mistakes,
        response_time_ms=payload.response_time_ms,
        duration_seconds=payload.duration_seconds,
        completed=payload.completed,
        offline_created=payload.offline_created,
        synced=True
    )
    db.add(new_session)
    db.commit()
    db.refresh(new_session)

    # Fetch recent sessions for this game to compute adaptive recommendation
    recent_db_sessions = db.query(GameSession).filter(
        GameSession.patient_id == payload.patient_id,
        GameSession.game_id == payload.game_id
    ).order_by(GameSession.completed_at.desc()).limit(5).all()

    telemetry_list = [
        GameTelemetry(
            patient_id=s.patient_id,
            game_id=s.game_id,
            category=s.category,
            level=s.level,
            score=s.score,
            accuracy=s.accuracy,
            attempts=s.attempts,
            mistakes=s.mistakes,
            response_time_ms=s.response_time_ms,
            duration_seconds=s.duration_seconds,
            completed=s.completed,
            completed_at=s.completed_at
        ) for s in reversed(recent_db_sessions)
    ]

    rec = diff_engine.evaluate_difficulty(
        patient_id=payload.patient_id,
        game_id=payload.game_id,
        current_level=payload.level,
        recent_sessions=telemetry_list
    )

    return {
        "session_id": new_session.id,
        "score": new_session.score,
        "accuracy": new_session.accuracy,
        "adaptive_feedback": {
            "current_level": rec.current_level,
            "recommended_level": rec.recommended_level,
            "recommendation": rec.recommendation,
            "reason": rec.reason
        }
    }


@router.get("/patient/{patient_id}/sessions")
def get_patient_game_sessions(
    patient_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Retrieves session history for a patient."""
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    if current_user.role == "PATIENT" and patient.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Unauthorized")

    sessions = db.query(GameSession).filter(
        GameSession.patient_id == patient_id
    ).order_by(GameSession.completed_at.desc()).limit(30).all()

    return sessions
