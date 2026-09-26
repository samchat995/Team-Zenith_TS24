"""
Data models for the Neural Nexus Adaptive Engine.
Strictly non-diagnostic telemetry models.
"""
from datetime import datetime, timezone
from typing import List, Optional
from pydantic import BaseModel, Field


class GameTelemetry(BaseModel):
    patient_id: str
    game_id: str
    category: str  # memory, attention, pattern, routine, language, auditory, emotion
    level: int = Field(default=1, ge=1, le=5)
    score: int = Field(default=0, ge=0)
    accuracy: float = Field(default=0.0, ge=0.0, le=100.0)  # Percentage 0-100
    attempts: int = Field(default=1, ge=1)
    mistakes: int = Field(default=0, ge=0)
    response_time_ms: int = Field(default=1000, ge=0)  # Average reaction time in ms
    duration_seconds: int = Field(default=30, ge=1)
    completed: bool = True
    completed_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class PerformanceMetrics(BaseModel):
    composite_score: float  # 0 to 100
    accuracy_score: float   # 0 to 100
    speed_score: float      # 0 to 100
    consistency_score: float# 0 to 100
    completion_rate: float  # 0 to 100
    total_sessions_analyzed: int


class AdaptiveRecommendation(BaseModel):
    patient_id: str
    game_id: str
    current_level: int
    recommended_level: int
    recommendation: str  # "INCREASE", "MAINTAIN", "REDUCE"
    reason: str          # Clear, explainable non-diagnostic justification
    recommended_game_category: Optional[str] = None
    suggested_game_id: Optional[str] = None
