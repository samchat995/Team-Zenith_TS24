"""
Offline Synchronization Engine router for Neural Nexus.
Ingests offline-queued game sessions, mood logs, and reminder statuses.
"""
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import User, Patient, GameSession, MoodLog, Reminder, AuditLog
from ..schemas import SyncPayload, SyncResponse
from ..auth import get_current_user

router = APIRouter(prefix="/sync", tags=["Offline Sync"])


@router.post("", response_model=SyncResponse)
def synchronize_offline_data(
    payload: SyncPayload,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    patient = db.query(Patient).filter(Patient.id == payload.patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    synced_sessions = 0
    for s in payload.sessions:
        session_obj = GameSession(
            patient_id=payload.patient_id,
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
            offline_created=True,
            synced=True
        )
        db.add(session_obj)
        synced_sessions += 1

    synced_moods = 0
    for m in payload.moods:
        mood_obj = MoodLog(
            patient_id=payload.patient_id,
            mood=m.mood,
            note=m.note,
            language=m.language
        )
        db.add(mood_obj)
        synced_moods += 1

    synced_reminders = 0
    for r_id in payload.reminders_completed:
        rem = db.query(Reminder).filter(Reminder.id == r_id, Reminder.patient_id == payload.patient_id).first()
        if rem:
            rem.completed = True
            rem.completed_at = datetime.now(timezone.utc)
            synced_reminders += 1

    db.commit()

    return SyncResponse(
        status="SUCCESS",
        synced_sessions_count=synced_sessions,
        synced_moods_count=synced_moods,
        synced_reminders_count=synced_reminders,
        server_time=datetime.now(timezone.utc)
    )
