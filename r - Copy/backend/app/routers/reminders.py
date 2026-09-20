"""
Reminders router for Neural Nexus.
Supports Medicine, Hydration, Daily Activities, and Medical Appointments.
"""
from datetime import datetime, timezone
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import User, Patient, Reminder, AuditLog
from ..schemas import ReminderCreate, ReminderUpdate, ReminderOut
from ..auth import get_current_user

router = APIRouter(prefix="/reminders", tags=["Reminders"])


@router.get("", response_model=List[ReminderOut])
def get_reminders(
    patient_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    if current_user.role == "PATIENT" and patient.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Unauthorized")

    reminders = db.query(Reminder).filter(Reminder.patient_id == patient_id).order_by(Reminder.created_at.asc()).all()
    return reminders


@router.post("", response_model=ReminderOut)
def create_reminder(
    payload: ReminderCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    patient = db.query(Patient).filter(Patient.id == payload.patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    new_reminder = Reminder(
        patient_id=payload.patient_id,
        title=payload.title,
        reminder_type=payload.reminder_type,
        time_of_day=payload.time_of_day,
        frequency=payload.frequency,
        notes=payload.notes,
        completed=False
    )
    db.add(new_reminder)
    db.commit()
    db.refresh(new_reminder)
    return new_reminder


@router.put("/{reminder_id}", response_model=ReminderOut)
def update_reminder(
    reminder_id: str,
    payload: ReminderUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    reminder = db.query(Reminder).filter(Reminder.id == reminder_id).first()
    if not reminder:
        raise HTTPException(status_code=404, detail="Reminder not found")

    if payload.title is not None:
        reminder.title = payload.title
    if payload.time_of_day is not None:
        reminder.time_of_day = payload.time_of_day
    if payload.notes is not None:
        reminder.notes = payload.notes
    if payload.completed is not None:
        reminder.completed = payload.completed
        reminder.completed_at = datetime.now(timezone.utc) if payload.completed else None

    db.commit()
    db.refresh(reminder)
    return reminder


@router.delete("/{reminder_id}")
def delete_reminder(
    reminder_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    reminder = db.query(Reminder).filter(Reminder.id == reminder_id).first()
    if not reminder:
        raise HTTPException(status_code=404, detail="Reminder not found")

    db.delete(reminder)
    db.commit()
    return {"status": "DELETED", "reminder_id": reminder_id}
