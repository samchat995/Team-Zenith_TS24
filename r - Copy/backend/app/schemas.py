"""
Pydantic validation schemas for Neural Nexus backend.
"""
from datetime import datetime
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, EmailStr, Field, ConfigDict


# Auth Schemas
class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    role: str
    full_name: str
    patient_id: Optional[str] = None


class PatientPinLogin(BaseModel):
    name_or_id: str  # "Ifra" or "Taiba" or user_id
    pin: str         # "1234"


class StaffLogin(BaseModel):
    email: str       # email or username
    password: str


class UserLogin(BaseModel):
    username_or_email: str
    password: str


class UserRegister(BaseModel):
    username: str
    password: str
    full_name: str
    email: Optional[str] = None
    role: str = "PATIENT"  # PATIENT or CAREGIVER
    age: Optional[int] = 70
    gender: Optional[str] = "Female"
    primary_language: Optional[str] = "en"
    emergency_contact: Optional[str] = None
    phone: Optional[str] = None
    caregiver_id: Optional[str] = None



# Patient Schemas
class PatientProfileOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    full_name: str
    role: str
    age: int
    gender: str
    primary_language: str
    emergency_contact: Optional[str] = None
    created_at: datetime


# Game Session Schemas
class GameSessionCreate(BaseModel):
    patient_id: str
    game_id: str
    category: str
    level: int = Field(default=1, ge=1, le=5)
    score: int = Field(default=0, ge=0)
    accuracy: float = Field(default=0.0, ge=0.0, le=100.0)
    attempts: int = Field(default=1, ge=1)
    mistakes: int = Field(default=0, ge=0)
    response_time_ms: int = Field(default=1000, ge=0)
    duration_seconds: int = Field(default=30, ge=1)
    completed: bool = True
    offline_created: bool = False


class GameSessionOut(GameSessionCreate):
    model_config = ConfigDict(from_attributes=True)

    id: str
    completed_at: datetime
    synced: bool


# Reminder Schemas
class ReminderCreate(BaseModel):
    patient_id: str
    title: str
    reminder_type: str  # medicine, hydration, daily_activity, appointment
    time_of_day: str
    frequency: str = "Daily"
    notes: Optional[str] = None


class ReminderUpdate(BaseModel):
    title: Optional[str] = None
    time_of_day: Optional[str] = None
    completed: Optional[bool] = None
    notes: Optional[str] = None


class ReminderOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    patient_id: str
    title: str
    reminder_type: str
    time_of_day: str
    frequency: str
    completed: bool
    completed_at: Optional[datetime] = None
    notes: Optional[str] = None
    created_at: datetime


# Mood Log Schemas
class MoodLogCreate(BaseModel):
    patient_id: str
    mood: str  # Happy, Calm, Okay, Tired, Worried
    note: Optional[str] = None
    language: str = "en"


class MoodLogOut(MoodLogCreate):
    model_config = ConfigDict(from_attributes=True)

    id: str
    logged_at: datetime


# Memory Item Schemas
class MemoryItemCreate(BaseModel):
    patient_id: str
    category: str  # family, favorite, place, routine
    title: str
    details: str
    relationship: Optional[str] = None
    image_url: Optional[str] = None


class MemoryItemOut(MemoryItemCreate):
    model_config = ConfigDict(from_attributes=True)

    id: str
    created_at: datetime


# Notes Schemas
class CaregiverNoteCreate(BaseModel):
    patient_id: str
    note_text: str


class ProfessionalNoteCreate(BaseModel):
    patient_id: str
    worker_name: Optional[str] = "Dr. Ritasri"
    note_text: str
    clinical_observation: Optional[str] = None


class FollowUpRecommendationCreate(BaseModel):
    patient_id: str
    recommendation_text: str
    priority: str = "Normal"


# Sync Schemas
class SyncPayload(BaseModel):
    patient_id: str
    sessions: List[GameSessionCreate] = []
    reminders_completed: List[str] = []
    moods: List[MoodLogCreate] = []


class SyncResponse(BaseModel):
    status: str = "SUCCESS"
    synced_sessions_count: int
    synced_moods_count: int
    synced_reminders_count: int
    server_time: datetime


# Initial 10-Question Assessment Schemas
class InitialAssessmentResponseCreate(BaseModel):
    question_id: int
    character_name: Optional[str] = None
    location: Optional[str] = None
    question_text: str
    story_summary: Optional[str] = None
    answer: str  # "Yes" or "No"
    language: str = "en"


class InitialAssessmentResponseOut(InitialAssessmentResponseCreate):
    model_config = ConfigDict(from_attributes=True)

    id: str
    assessment_id: str
    answered_at: datetime


class InitialAssessmentCreate(BaseModel):
    patient_id: str
    caregiver_id: Optional[str] = None
    language: str = "en"
    notes: Optional[str] = None
    responses: List[InitialAssessmentResponseCreate]


class InitialAssessmentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    patient_id: str
    caregiver_id: Optional[str] = None
    completed: bool
    total_questions: int
    yes_count: int
    no_count: int
    language: str
    completed_at: datetime
    notes: Optional[str] = None
    responses: List[InitialAssessmentResponseOut] = []

