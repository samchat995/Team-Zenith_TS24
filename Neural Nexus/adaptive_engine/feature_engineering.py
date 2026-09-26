"""
Feature engineering utilities for analyzing elderly cognitive session telemetry.
Calculates normalized metrics without clinical diagnostic assumptions.
"""
from typing import List
import numpy as np
from .models import GameTelemetry, PerformanceMetrics


def calculate_speed_score(avg_response_time_ms: float) -> float:
    """
    Normalizes response time into a 0-100 score.
    For elderly users:
    - Under 1200ms: ~100
    - 2500ms: ~70
    - 4000ms: ~50
    - Over 7000ms: drops toward 20
    """
    if avg_response_time_ms <= 0:
        return 50.0
    # Soft logistic decay tailored for elderly reaction times
    normalized = 100.0 / (1.0 + np.exp((avg_response_time_ms - 2800.0) / 1400.0))
    return float(np.clip(normalized * 1.5, 10.0, 100.0))


def calculate_consistency_score(accuracies: List[float]) -> float:
    """
    Measures performance stability across recent attempts.
    Higher standard deviation results in lower consistency.
    """
    if len(accuracies) < 2:
        return 80.0  # Default initial prior
    std_dev = float(np.std(accuracies))
    # A standard deviation of 0 gives 100%, 25 gives 50%
    score = max(20.0, 100.0 - (std_dev * 2.0))
    return min(100.0, score)


def extract_features(sessions: List[GameTelemetry]) -> PerformanceMetrics:
    """
    Computes Composite Performance Score:
    Score = 40% Accuracy + 25% Speed + 20% Consistency + 15% Completion
    """
    if not sessions:
        return PerformanceMetrics(
            composite_score=50.0,
            accuracy_score=50.0,
            speed_score=50.0,
            consistency_score=80.0,
            completion_rate=100.0,
            total_sessions_analyzed=0
        )

    accuracies = [s.accuracy for s in sessions]
    response_times = [s.response_time_ms for s in sessions]
    completions = [100.0 if s.completed else 0.0 for s in sessions]

    avg_accuracy = float(np.mean(accuracies))
    avg_speed = float(calculate_speed_score(float(np.mean(response_times))))
    consistency = float(calculate_consistency_score(accuracies))
    completion_rate = float(np.mean(completions))

    # Weightings required by specification:
    # 40% accuracy, 25% response time, 20% consistency, 15% completion
    composite = (0.40 * avg_accuracy) + (0.25 * avg_speed) + (0.20 * consistency) + (0.15 * completion_rate)

    return PerformanceMetrics(
        composite_score=round(composite, 2),
        accuracy_score=round(avg_accuracy, 2),
        speed_score=round(avg_speed, 2),
        consistency_score=round(consistency, 2),
        completion_rate=round(completion_rate, 2),
        total_sessions_analyzed=len(sessions)
    )
