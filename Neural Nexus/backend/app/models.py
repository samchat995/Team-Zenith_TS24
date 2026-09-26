"""
SQLAlchemy ORM models for Neural Nexus.
Strict data isolation per patient and role-based permissions.
"""
from datetime import datetime, timezone
import uuid
from sqlalchemy import Column, String, Integer, Float, Boolean, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship as orm_relationship
from .database import Base


def gen_uuid():
    return str(uuid.uuid4())


def now_utc():
    return datetime.now(timezone.utc)


class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    email = Column(String(255), unique=True, index=True, nullable=True)
    username = Column(String(100), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=True)
    pin = Column(String(10), nullable=True)  # 4-digit PIN for patient
    full_name = Column(String(150), nullable=False)
    role = Column(String(50), nullable=False)  # PATIENT, CAREGIVER, HEALTHCARE_WORKER, ADMIN
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=now_utc)

    # Relationships
    patient_profile = orm_relationship("Patient", back_populates="user", uselist=False)
    caregiver_profile = orm_relationship("Caregiver", back_populates="user", uselist=False)
    healthcare_profile = orm_relationship("HealthcareWorker", back_populates="user", uselist=False)


class Patient(Base):
    __tablename__ = "patients"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    user_id = Column(String(36), ForeignKey("users.id"), unique=True, nullable=False)
    age = Column(Integer, default=70)
    gender = Column(String(20), default="Female")
    primary_language = Column(String(20), default="en")  # en, hi, as
    emergency_contact = Column(String(100), nullable=True)
    initial_assessment_completed = Column(Boolean, default=False)
    created_at = Column(DateTime, default=now_utc)

    user = orm_relationship("User", back_populates="patient_profile")
    game_sessions = orm_relationship("GameSession", back_populates="patient", cascade="all, delete-orphan")
    mood_logs = orm_relationship("MoodLog", back_populates="patient", cascade="all, delete-orphan")
    reminders = orm_relationship("Reminder", back_populates="patient", cascade="all, delete-orphan")
    memory_items = orm_relationship("MemoryItem", back_populates="patient", cascade="all, delete-orphan")
    caregiver_notes = orm_relationship("CaregiverNote", back_populates="patient", cascade="all, delete-orphan")
    professional_notes = orm_relationship("ProfessionalNote", back_populates="patient", cascade="all, delete-orphan")
    follow_ups = orm_relationship("FollowUpRecommendation", back_populates="patient", cascade="all, delete-orphan")
    initial_assessments = orm_relationship("InitialAssessment", back_populates="patient", cascade="all, delete-orphan")



class Caregiver(Base):
    __tablename__ = "caregivers"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    user_id = Column(String(36), ForeignKey("users.id"), unique=True, nullable=False)
    phone = Column(String(50), nullable=True)
    relationship_to_patient = Column(String(100), default="Family Caregiver")

    user = orm_relationship("User", back_populates="caregiver_profile")


class HealthcareWorker(Base):
    __tablename__ = "healthcare_workers"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    user_id = Column(String(36), ForeignKey("users.id"), unique=True, nullable=False)
    professional_id = Column(String(100), unique=True, index=True, nullable=False)
    specialization = Column(String(150), default="Elderly Cognitive Support")
    hospital_clinic = Column(String(200), default="Guwahati Regional Health Centre")

    user = orm_relationship("User", back_populates="healthcare_profile")


class PatientAssignment(Base):
    __tablename__ = "patient_assignments"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    patient_id = Column(String(36), ForeignKey("patients.id"), nullable=False)
    caregiver_id = Column(String(36), ForeignKey("caregivers.id"), nullable=True)
    healthcare_worker_id = Column(String(36), ForeignKey("healthcare_workers.id"), nullable=True)
    assigned_at = Column(DateTime, default=now_utc)


class Game(Base):
    __tablename__ = "games"

    id = Column(String(100), primary_key=True)
    title = Column(String(150), nullable=False)
    category = Column(String(50), nullable=False)  # memory, attention, pattern, routine, language, auditory, emotion
    description = Column(Text, nullable=True)
    min_level = Column(Integer, default=1)
    max_level = Column(Integer, default=5)


class GameSession(Base):
    __tablename__ = "game_sessions"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    patient_id = Column(String(36), ForeignKey("patients.id"), index=True, nullable=False)
    game_id = Column(String(100), nullable=False)
    category = Column(String(50), nullable=False)
    level = Column(Integer, default=1)
    score = Column(Integer, default=0)
    accuracy = Column(Float, default=0.0)
    attempts = Column(Integer, default=1)
    mistakes = Column(Integer, default=0)
    response_time_ms = Column(Integer, default=1000)
    duration_seconds = Column(Integer, default=30)
    completed = Column(Boolean, default=True)
    completed_at = Column(DateTime, default=now_utc)
    offline_created = Column(Boolean, default=False)
    synced = Column(Boolean, default=True)

    patient = orm_relationship("Patient", back_populates="game_sessions")


class MoodLog(Base):
    __tablename__ = "mood_logs"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    patient_id = Column(String(36), ForeignKey("patients.id"), index=True, nullable=False)
    mood = Column(String(50), nullable=False)  # Happy, Calm, Okay, Tired, Worried
    note = Column(Text, nullable=True)
    language = Column(String(10), default="en")
    logged_at = Column(DateTime, default=now_utc)

    patient = orm_relationship("Patient", back_populates="mood_logs")


class Reminder(Base):
    __tablename__ = "reminders"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    patient_id = Column(String(36), ForeignKey("patients.id"), index=True, nullable=False)
    title = Column(String(200), nullable=False)
    reminder_type = Column(String(50), nullable=False)  # medicine, hydration, daily_activity, appointment
    time_of_day = Column(String(20), nullable=False)   # e.g., "09:00 AM", "02:00 PM"
    frequency = Column(String(50), default="Daily")
    completed = Column(Boolean, default=False)
    completed_at = Column(DateTime, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=now_utc)

    patient = orm_relationship("Patient", back_populates="reminders")


class MemoryItem(Base):
    __tablename__ = "memory_items"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    patient_id = Column(String(36), ForeignKey("patients.id"), index=True, nullable=False)
    category = Column(String(50), nullable=False)  # family, favorite, place, routine
    title = Column(String(150), nullable=False)
    details = Column(Text, nullable=False)
    relationship = Column(String(100), nullable=True)
    image_url = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=now_utc)

    patient = orm_relationship("Patient", back_populates="memory_items")


class CaregiverNote(Base):
    __tablename__ = "caregiver_notes"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    patient_id = Column(String(36), ForeignKey("patients.id"), index=True, nullable=False)
    caregiver_id = Column(String(36), ForeignKey("caregivers.id"), nullable=True)
    note_text = Column(Text, nullable=False)
    created_at = Column(DateTime, default=now_utc)

    patient = orm_relationship("Patient", back_populates="caregiver_notes")


class ProfessionalNote(Base):
    __tablename__ = "professional_notes"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    patient_id = Column(String(36), ForeignKey("patients.id"), index=True, nullable=False)
    worker_id = Column(String(36), ForeignKey("healthcare_workers.id"), nullable=True)
    worker_name = Column(String(150), default="Dr. Ritasri")
    note_text = Column(Text, nullable=False)
    clinical_observation = Column(Text, nullable=True)
    created_at = Column(DateTime, default=now_utc)

    patient = orm_relationship("Patient", back_populates="professional_notes")


class FollowUpRecommendation(Base):
    __tablename__ = "follow_up_recommendations"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    patient_id = Column(String(36), ForeignKey("patients.id"), index=True, nullable=False)
    worker_id = Column(String(36), ForeignKey("healthcare_workers.id"), nullable=True)
    recommendation_text = Column(Text, nullable=False)
    priority = Column(String(20), default="Normal")  # Routine, Normal, Priority
    status = Column(String(50), default="Pending")
    created_at = Column(DateTime, default=now_utc)

    patient = orm_relationship("Patient", back_populates="follow_ups")


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    user_id = Column(String(36), nullable=True)
    username = Column(String(100), nullable=True)
    role = Column(String(50), nullable=True)
    action = Column(String(100), nullable=False)
    resource = Column(String(100), nullable=False)
    details = Column(Text, nullable=True)
    timestamp = Column(DateTime, default=now_utc)


class InitialAssessment(Base):
    __tablename__ = "initial_assessments"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    patient_id = Column(String(36), ForeignKey("patients.id"), index=True, nullable=False)
    caregiver_id = Column(String(36), ForeignKey("caregivers.id"), nullable=True)
    completed = Column(Boolean, default=True)
    total_questions = Column(Integer, default=10)
    yes_count = Column(Integer, default=0)
    no_count = Column(Integer, default=0)
    language = Column(String(10), default="en")
    completed_at = Column(DateTime, default=now_utc)
    notes = Column(Text, nullable=True)

    patient = orm_relationship("Patient", back_populates="initial_assessments")
    responses = orm_relationship("InitialAssessmentResponse", back_populates="assessment", cascade="all, delete-orphan")


class InitialAssessmentResponse(Base):
    __tablename__ = "initial_assessment_responses"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    assessment_id = Column(String(36), ForeignKey("initial_assessments.id"), index=True, nullable=False)
    question_id = Column(Integer, nullable=False)
    character_name = Column(String(100), nullable=True)
    location = Column(String(100), nullable=True)
    question_text = Column(Text, nullable=False)
    story_summary = Column(Text, nullable=True)
    answer = Column(String(10), nullable=False)  # "Yes" or "No"
    language = Column(String(10), default="en")
    answered_at = Column(DateTime, default=now_utc)

    assessment = orm_relationship("InitialAssessment", back_populates="responses")

