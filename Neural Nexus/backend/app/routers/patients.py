"""
Patient endpoints with strict role-based access control and patient data isolation.
Calculates dynamic dashboard metrics directly from user records.
"""
from datetime import datetime, timezone
from typing import List, Dict, Any, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import (
    User, Patient, Caregiver, GameSession, Reminder, CaregiverNote,
    PatientAssignment, InitialAssessment, InitialAssessmentResponse, AuditLog
)
from ..schemas import PatientProfileOut, InitialAssessmentCreate, InitialAssessmentOut
from ..auth import get_current_user
from adaptive_engine.recommendation_engine import RecommendationEngine
from adaptive_engine.models import GameTelemetry

router = APIRouter(prefix="/patients", tags=["Patients"])
rec_engine = RecommendationEngine()


@router.get("", response_model=List[Dict[str, Any]])
def list_patients(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    Lists patients based on role:
    - CAREGIVER: returns only authorized assigned patients
    - HEALTHCARE_WORKER: returns authorized assigned patients
    - ADMIN: returns all patients
    - PATIENT: rejected with 403
    """
    if current_user.role == "PATIENT":
        raise HTTPException(status_code=403, detail="Patients cannot view patient lists.")

    if current_user.role == "CAREGIVER":
        cg = db.query(Caregiver).filter(Caregiver.user_id == current_user.id).first()
        if cg:
            assigned_ids = [a.patient_id for a in db.query(PatientAssignment).filter(PatientAssignment.caregiver_id == cg.id).all()]
            query = db.query(Patient).filter(Patient.id.in_(assigned_ids)).join(User, Patient.user_id == User.id)
        else:
            return []
    else:
        query = db.query(Patient).join(User, Patient.user_id == User.id)

    patients = query.all()


    results = []
    for p in patients:
        u = p.user
        completed_sessions = db.query(GameSession).filter(GameSession.patient_id == p.id, GameSession.completed == True).count()
        pending_reminders = db.query(Reminder).filter(Reminder.patient_id == p.id, Reminder.completed == False).count()
        results.append({
            "id": p.id,
            "user_id": u.id,
            "full_name": u.full_name,
            "username": u.username,
            "age": p.age,
            "gender": p.gender,
            "primary_language": p.primary_language,
            "emergency_contact": p.emergency_contact,
            "completed_games_count": completed_sessions,
            "pending_reminders_count": pending_reminders,
        })
    return results


@router.get("/{patient_id}/dashboard-summary")
def get_patient_dashboard_summary(
    patient_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Calculates dynamic patient home dashboard summary.
    If patient is logged in, validates that they are accessing their own data.
    """
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    # Strict isolation: if patient role, must match own user_id
    if current_user.role == "PATIENT" and patient.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Unauthorized: cannot access another patient's records.")

    # Calculate real sessions completed today
    sessions = db.query(GameSession).filter(GameSession.patient_id == patient_id).all()
    today_sessions = [s for s in sessions if s.completed]
    games_completed_today = len(today_sessions)
    target_games_today = 4

    # Calculate dynamic percentage: combination of games completed (max 75%) + reminder completion (max 25%)
    reminders = db.query(Reminder).filter(Reminder.patient_id == patient_id).all()
    completed_reminders = [r for r in reminders if r.completed]
    pending_reminders = [r for r in reminders if not r.completed]

    games_ratio = min(1.0, games_completed_today / target_games_today) if target_games_today > 0 else 0
    reminders_ratio = (len(completed_reminders) / len(reminders)) if reminders else 1.0

    calculated_progress = round((games_ratio * 75.0) + (reminders_ratio * 25.0), 1)

    # Adaptive recommendation for Today's Activity
    telemetry_history = [
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
        ) for s in sessions
    ]
    todays_activity = rec_engine.get_todays_activity(patient_id, telemetry_history)

    # Assigned Caregiver & latest note
    assignment = db.query(PatientAssignment).filter(PatientAssignment.patient_id == patient_id).first()
    caregiver_name = "Assigned Caregiver"
    if assignment and assignment.caregiver_id:
        cg = db.query(Caregiver).filter(Caregiver.id == assignment.caregiver_id).first()
        if cg and cg.user:
            caregiver_name = cg.user.full_name

    latest_note = db.query(CaregiverNote).filter(CaregiverNote.patient_id == patient_id).order_by(CaregiverNote.created_at.desc()).first()

    return {
        "patient_id": patient.id,
        "full_name": patient.user.full_name,
        "username": patient.user.username,
        "role": "Patient",
        "primary_language": patient.primary_language,
        "initial_assessment_completed": bool(patient.initial_assessment_completed),
        "progress_percentage": calculated_progress,
        "games_completed_today": games_completed_today,
        "target_games_today": target_games_today,
        "pending_reminders_count": len(pending_reminders),
        "total_reminders_count": len(reminders),
        "today_activity": todays_activity,
        "caregiver": {
            "name": caregiver_name,
            "latest_note": latest_note.note_text if latest_note else "Remember to enjoy your afternoon cognitive games!"
        }
    }


@router.post("/{patient_id}/initial-assessment", response_model=InitialAssessmentOut)
def save_initial_assessment(
    patient_id: str,
    payload: InitialAssessmentCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Saves the initial 10-question onboarding assessment and individual responses.
    Marks initial_assessment_completed = True for the patient.
    """
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    yes_count = sum(1 for r in payload.responses if r.answer.strip().lower() in ["yes", "हाँ", "হয়", "true"])
    no_count = len(payload.responses) - yes_count

    # Determine caregiver
    caregiver_id = payload.caregiver_id
    if not caregiver_id:
        assignment = db.query(PatientAssignment).filter(PatientAssignment.patient_id == patient_id).first()
        if assignment and assignment.caregiver_id:
            caregiver_id = assignment.caregiver_id

    assessment = InitialAssessment(
        patient_id=patient_id,
        caregiver_id=caregiver_id,
        completed=True,
        total_questions=len(payload.responses),
        yes_count=yes_count,
        no_count=no_count,
        language=payload.language,
        notes=payload.notes or "Initial Onboarding Assessment"
    )
    db.add(assessment)
    db.flush()

    for r in payload.responses:
        resp = InitialAssessmentResponse(
            assessment_id=assessment.id,
            question_id=r.question_id,
            character_name=r.character_name,
            location=r.location,
            question_text=r.question_text,
            story_summary=r.story_summary,
            answer=r.answer,
            language=r.language
        )
        db.add(resp)

    patient.initial_assessment_completed = True
    db.add(AuditLog(
        user_id=current_user.id,
        username=current_user.username,
        role=current_user.role,
        action="SAVE_INITIAL_ASSESSMENT",
        resource="patients",
        details=f"Saved initial assessment for patient {patient.user.full_name}: {len(payload.responses)} responses"
    ))
    db.commit()
    db.refresh(assessment)
    return assessment


@router.get("/{patient_id}/initial-assessment", response_model=Optional[InitialAssessmentOut])
def get_initial_assessment(
    patient_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Retrieves the latest initial assessment with all 10 question responses.
    Accessible to Patient (own record), assigned Caregiver, Healthcare Worker, or Admin.
    """
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    assessment = db.query(InitialAssessment).filter(
        InitialAssessment.patient_id == patient_id
    ).order_by(InitialAssessment.completed_at.desc()).first()

    return assessment

