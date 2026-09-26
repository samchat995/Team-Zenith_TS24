"""
Mood and emotional well-being check-in router for Neural Nexus.
Provides non-diagnostic emotional logging and history.
"""
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import User, Patient, MoodLog
from ..schemas import MoodLogCreate, MoodLogOut
from ..auth import get_current_user

router = APIRouter(prefix="/mood", tags=["Mood"])


@router.post("", response_model=MoodLogOut)
def log_mood(
    payload: MoodLogCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    patient = db.query(Patient).filter(Patient.id == payload.patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    if current_user.role == "PATIENT" and patient.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Unauthorized")

    new_log = MoodLog(
        patient_id=payload.patient_id,
        mood=payload.mood,
        note=payload.note,
        language=payload.language
    )
    db.add(new_log)
    db.commit()
    db.refresh(new_log)
    return new_log


@router.get("", response_model=List[MoodLogOut])
def get_mood_logs(
    patient_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    logs = db.query(MoodLog).filter(
        MoodLog.patient_id == patient_id
    ).order_by(MoodLog.logged_at.desc()).limit(30).all()
    return logs
