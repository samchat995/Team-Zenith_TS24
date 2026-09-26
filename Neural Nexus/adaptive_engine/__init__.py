"""
Adaptive engine package for Neural Nexus.
"""
from .models import GameTelemetry, PerformanceMetrics, AdaptiveRecommendation
from .feature_engineering import extract_features, calculate_speed_score, calculate_consistency_score
from .difficulty_engine import DifficultyEngine
from .performance_analyzer import PerformanceAnalyzer
from .recommendation_engine import RecommendationEngine

__all__ = [
    "GameTelemetry",
    "PerformanceMetrics",
    "AdaptiveRecommendation",
    "extract_features",
    "calculate_speed_score",
    "calculate_consistency_score",
    "DifficultyEngine",
    "PerformanceAnalyzer",
    "RecommendationEngine"
]
