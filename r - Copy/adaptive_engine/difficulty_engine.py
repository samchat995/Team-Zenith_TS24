"""
Adaptive Difficulty Engine for Neural Nexus.
Adjusts cognitive challenge levels gradually (Level 1 to 5) with explainable reasoning.
Zero medical/clinical diagnosis.
"""
from typing import List
from .models import GameTelemetry, AdaptiveRecommendation
from .feature_engineering import extract_features


class DifficultyEngine:
    def __init__(self, min_level: int = 1, max_level: int = 5):
        self.min_level = min_level
        self.max_level = max_level

    def evaluate_difficulty(
        self,
        patient_id: str,
        game_id: str,
        current_level: int,
        recent_sessions: List[GameTelemetry]
    ) -> AdaptiveRecommendation:
        """
        Evaluates the patient's performance across recent sessions (typically last 3-5 sessions)
        and outputs a transparent recommendation.
        """
        if not recent_sessions:
            return AdaptiveRecommendation(
                patient_id=patient_id,
                game_id=game_id,
                current_level=current_level,
                recommended_level=current_level,
                recommendation="MAINTAIN",
                reason="Starting activity at introductory comfort level."
            )

        metrics = extract_features(recent_sessions)
        composite = metrics.composite_score
        avg_accuracy = metrics.accuracy_score
        completion = metrics.completion_rate

        # Criteria for gradual adaptation:
        # High performance: Composite >= 82% AND Accuracy >= 80% AND completed
        if composite >= 82.0 and avg_accuracy >= 80.0 and completion >= 90.0:
            if current_level < self.max_level:
                new_level = current_level + 1
                reason = (
                    f"Strong engagement and high accuracy ({avg_accuracy:.0f}%) across recent sessions. "
                    f"Gently progressing to Level {new_level} for healthy cognitive stimulation."
                )
                recommendation = "INCREASE"
            else:
                new_level = self.max_level
                reason = (
                    f"Mastery maintained at highest Level {self.max_level} with {avg_accuracy:.0f}% accuracy. "
                    "Continuing at this engaging level."
                )
                recommendation = "MAINTAIN"

        # Low performance or fatigue: Composite < 52% OR Accuracy < 50% OR completion < 60%
        elif composite < 52.0 or avg_accuracy < 50.0 or completion < 60.0:
            if current_level > self.min_level:
                new_level = current_level - 1
                reason = (
                    f"Recent sessions showed signs of effort or fatigue (Accuracy: {avg_accuracy:.0f}%). "
                    f"Reducing difficulty to Level {new_level} to keep the activity relaxing and enjoyable."
                )
                recommendation = "REDUCE"
            else:
                new_level = self.min_level
                reason = (
                    "Maintaining introductory Level 1 with extra gentle pacing and encouragement."
                )
                recommendation = "MAINTAIN"

        # Stable performance
        else:
            new_level = current_level
            reason = (
                f"Comfortable and stable performance (Composite Score: {composite:.0f}%). "
                f"Maintaining Level {current_level}."
            )
            recommendation = "MAINTAIN"

        return AdaptiveRecommendation(
            patient_id=patient_id,
            game_id=game_id,
            current_level=current_level,
            recommended_level=new_level,
            recommendation=recommendation,
            reason=reason
        )
