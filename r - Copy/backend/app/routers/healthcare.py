"""
Healthcare Worker router for Neural Nexus.
Provides Dr. Ritasri with dedicated endpoints for assigned patients:
- Review cognitive activity breakdown (Memory, Attention, Pattern, etc.)
- Review caregiver notes
- Add professional notes & clinical observations
- Submit follow-up recommendations
- Generate clinical summary reports
Strict RBAC enforced: Only HEALTHCARE_WORKER and ADMIN can access.
"""
from datetime import datetime, timezone
from typing import List, Dict, Any, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import (
    User, Patient, HealthcareWorker, PatientAssignment, GameSession,
    CaregiverNote, ProfessionalNote, FollowUpRecommendation, MoodLog, Reminder, AuditLog
)
from ..schemas import ProfessionalNoteCreate, FollowUpRecommendationCreate
from ..auth import get_current_user, require_roles
from adaptive_engine.performance_analyzer import PerformanceAnalyzer
from adaptive_engine.models import GameTelemetry

router = APIRouter(prefix="/healthcare", tags=["Healthcare Worker (Ritasri)"])
analyzer = PerformanceAnalyzer()


@router.get("/assigned-patients", dependencies=[Depends(require_roles("HEALTHCARE_WORKER", "ADMIN"))])
def get_assigned_patients(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    Returns list of authorized assigned patients for the healthcare worker (e.g. Ifra, Taiba).
    """
    patients = db.query(Patient).join(User, Patient.user_id == User.id).all()
    results = []
    for p in patients:
        u = p.user
        sessions = db.query(GameSession).filter(GameSession.patient_id == p.id).all()
        reminders = db.query(Reminder).filter(Reminder.patient_id == p.id).all()
        completed_reminders = [r for r in reminders if r.completed]
        
        results.append({
            "patient_id": p.id,
            "full_name": u.full_name,
            "username": u.username,
            "age": p.age,
            "gender": p.gender,
            "primary_language": p.primary_language,
            "emergency_contact": p.emergency_contact,
            "total_games_played": len(sessions),
            "completed_reminders": len(completed_reminders),
            "total_reminders": len(reminders),
            "adherence_rate": round((len(completed_reminders) / len(reminders) * 100.0), 1) if reminders else 100.0
        })
    return results


@router.get("/patient/{patient_id}/cognitive-overview", dependencies=[Depends(require_roles("HEALTHCARE_WORKER", "ADMIN"))])
def get_patient_cognitive_overview(
    patient_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Returns clinical cognitive domain breakdown, recent sessions, and caregiver notes.
    """
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    sessions = db.query(GameSession).filter(GameSession.patient_id == patient_id).order_by(GameSession.completed_at.desc()).all()
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
        ) for s in sessions
    ]

    domain_analysis = analyzer.analyze_domains(telemetry_list)
    caregiver_notes = db.query(CaregiverNote).filter(CaregiverNote.patient_id == patient_id).order_by(CaregiverNote.created_at.desc()).all()
    professional_notes = db.query(ProfessionalNote).filter(ProfessionalNote.patient_id == patient_id).order_by(ProfessionalNote.created_at.desc()).all()
    follow_ups = db.query(FollowUpRecommendation).filter(FollowUpRecommendation.patient_id == patient_id).order_by(FollowUpRecommendation.created_at.desc()).all()
    recent_moods = db.query(MoodLog).filter(MoodLog.patient_id == patient_id).order_by(MoodLog.logged_at.desc()).limit(7).all()

    return {
        "patient": {
            "id": patient.id,
            "full_name": patient.user.full_name,
            "age": patient.age,
            "gender": patient.gender,
            "language": patient.primary_language
        },
        "domain_analysis": domain_analysis,
        "recent_sessions": [
            {
                "id": s.id,
                "game_id": s.game_id,
                "category": s.category,
                "level": s.level,
                "score": s.score,
                "accuracy": s.accuracy,
                "response_time_ms": s.response_time_ms,
                "completed_at": s.completed_at
            } for s in sessions[:10]
        ],
        "recent_moods": [
            {"mood": m.mood, "logged_at": m.logged_at, "note": m.note} for m in recent_moods
        ],
        "caregiver_notes": [
            {"id": n.id, "note_text": n.note_text, "created_at": n.created_at} for n in caregiver_notes
        ],
        "professional_notes": [
            {
                "id": n.id,
                "worker_name": n.worker_name,
                "note_text": n.note_text,
                "clinical_observation": n.clinical_observation,
                "created_at": n.created_at
            } for n in professional_notes
        ],
        "follow_up_recommendations": [
            {
                "id": f.id,
                "recommendation_text": f.recommendation_text,
                "priority": f.priority,
                "status": f.status,
                "created_at": f.created_at
            } for f in follow_ups
        ]
    }


@router.post("/professional-note", dependencies=[Depends(require_roles("HEALTHCARE_WORKER", "ADMIN"))])
def add_professional_note(
    payload: ProfessionalNoteCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Adds a professional note by Dr. Ritasri."""
    patient = db.query(Patient).filter(Patient.id == payload.patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    worker_record = db.query(HealthcareWorker).filter(HealthcareWorker.user_id == current_user.id).first()
    worker_id = worker_record.id if worker_record else None

    note = ProfessionalNote(
        patient_id=payload.patient_id,
        worker_id=worker_id,
        worker_name=current_user.full_name or payload.worker_name or "Dr. Ritasri",
        note_text=payload.note_text,
        clinical_observation=payload.clinical_observation
    )
    db.add(note)

    # Audit log
    db.add(AuditLog(
        user_id=current_user.id,
        username=current_user.username,
        role=current_user.role,
        action="ADD_PROFESSIONAL_NOTE",
        resource="professional_notes",
        details=f"Note added for patient {patient.user.full_name}"
    ))
    db.commit()
    db.refresh(note)
    return {"status": "SUCCESS", "note_id": note.id, "message": "Professional note recorded successfully"}


@router.post("/follow-up", dependencies=[Depends(require_roles("HEALTHCARE_WORKER", "ADMIN"))])
def add_follow_up(
    payload: FollowUpRecommendationCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Submits a follow-up check-in recommendation for the caregiver/family."""
    patient = db.query(Patient).filter(Patient.id == payload.patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    worker_record = db.query(HealthcareWorker).filter(HealthcareWorker.user_id == current_user.id).first()
    worker_id = worker_record.id if worker_record else None

    follow_up = FollowUpRecommendation(
        patient_id=payload.patient_id,
        worker_id=worker_id,
        recommendation_text=payload.recommendation_text,
        priority=payload.priority
    )
    db.add(follow_up)
    db.commit()
    db.refresh(follow_up)
    return {"status": "SUCCESS", "follow_up_id": follow_up.id}


@router.get("/patient/{patient_id}/report", dependencies=[Depends(require_roles("HEALTHCARE_WORKER", "ADMIN"))])
def generate_patient_report(
    patient_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Generates an exportable clinical summary report."""
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    sessions = db.query(GameSession).filter(GameSession.patient_id == patient_id).all()
    reminders = db.query(Reminder).filter(Reminder.patient_id == patient_id).all()
    completed_reminders = [r for r in reminders if r.completed]
    notes = db.query(ProfessionalNote).filter(ProfessionalNote.patient_id == patient_id).all()

    avg_accuracy = round(sum(s.accuracy for s in sessions) / len(sessions), 1) if sessions else 0.0

    return {
        "report_title": "NEURAL NEXUS — Cognitive Activity & Adherence Summary",
        "generated_by": current_user.full_name,
        "generated_at": datetime.now(timezone.utc),
        "disclaimer": "Neural Nexus is an engaging cognitive stimulation and memory assistance platform. This report provides activity adherence summaries and does not constitute a formal medical or neurological diagnosis.",
        "patient": {
            "name": patient.user.full_name,
            "age": patient.age,
            "gender": patient.gender,
            "primary_language": patient.primary_language
        },
        "summary_metrics": {
            "total_cognitive_sessions": len(sessions),
            "average_accuracy": f"{avg_accuracy}%",
            "reminder_adherence": f"{round(len(completed_reminders)/len(reminders)*100, 1) if reminders else 100}%"
        },
        "clinical_observations_count": len(notes)
    }
