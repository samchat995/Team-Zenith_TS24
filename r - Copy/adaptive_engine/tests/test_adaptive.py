"""
Unit tests for Neural Nexus Adaptive Engine.
Verifies deterministic progression, explainability, and non-diagnostic constraints.
"""
import unittest
from datetime import datetime
from adaptive_engine.models import GameTelemetry
from adaptive_engine.feature_engineering import extract_features, calculate_speed_score
from adaptive_engine.difficulty_engine import DifficultyEngine
from adaptive_engine.performance_analyzer import PerformanceAnalyzer
from adaptive_engine.recommendation_engine import RecommendationEngine


class TestAdaptiveEngine(unittest.TestCase):
    def setUp(self):
        self.diff_engine = DifficultyEngine(min_level=1, max_level=5)
        self.analyzer = PerformanceAnalyzer()
        self.rec_engine = RecommendationEngine()

    def test_feature_weighting_formula(self):
        # 1 session with 100% accuracy, fast response (1000ms), 100% completion
        session = GameTelemetry(
            patient_id="ifra_01",
            game_id="memory_match",
            category="memory",
            level=1,
            score=100,
            accuracy=100.0,
            attempts=1,
            mistakes=0,
            response_time_ms=1000,
            duration_seconds=20,
            completed=True
        )
        metrics = extract_features([session])
        self.assertEqual(metrics.accuracy_score, 100.0)
        self.assertEqual(metrics.completion_rate, 100.0)
        self.assertGreaterEqual(metrics.composite_score, 85.0)

    def test_progression_increase_on_high_performance(self):
        # 3 consecutive sessions with high accuracy and good speed
        sessions = [
            GameTelemetry(
                patient_id="ifra_01",
                game_id="remember_objects",
                category="memory",
                level=2,
                score=90,
                accuracy=95.0,
                attempts=1,
                mistakes=0,
                response_time_ms=1200,
                completed=True
            ) for _ in range(3)
        ]
        rec = self.diff_engine.evaluate_difficulty("ifra_01", "remember_objects", current_level=2, recent_sessions=sessions)
        self.assertEqual(rec.recommendation, "INCREASE")
        self.assertEqual(rec.recommended_level, 3)
        self.assertIn("Gently progressing", rec.reason)
        # Ensure strictly no medical diagnoses
        self.assertNotIn("dementia", rec.reason.lower())
        self.assertNotIn("alzheimer", rec.reason.lower())

    def test_reduction_on_fatigue_or_low_score(self):
        # 3 sessions with low accuracy and slow response
        sessions = [
            GameTelemetry(
                patient_id="taiba_02",
                game_id="routine_order",
                category="routine",
                level=3,
                score=30,
                accuracy=35.0,
                attempts=3,
                mistakes=4,
                response_time_ms=6500,
                completed=True
            ) for _ in range(3)
        ]
        rec = self.diff_engine.evaluate_difficulty("taiba_02", "routine_order", current_level=3, recent_sessions=sessions)
        self.assertEqual(rec.recommendation, "REDUCE")
        self.assertEqual(rec.recommended_level, 2)
        self.assertIn("Reducing difficulty", rec.reason)
        self.assertNotIn("dementia", rec.reason.lower())

    def test_maintain_when_stable(self):
        sessions = [
            GameTelemetry(
                patient_id="ifra_01",
                game_id="pattern_completion",
                category="pattern",
                level=2,
                score=70,
                accuracy=70.0,
                attempts=1,
                mistakes=1,
                response_time_ms=2500,
                completed=True
            ) for _ in range(3)
        ]
        rec = self.diff_engine.evaluate_difficulty("ifra_01", "pattern_completion", current_level=2, recent_sessions=sessions)
        self.assertEqual(rec.recommendation, "MAINTAIN")
        self.assertEqual(rec.recommended_level, 2)

    def test_caregiver_alerts_non_alarmist(self):
        # Low activity alerts
        alerts = self.analyzer.generate_caregiver_alerts([], pending_reminders_count=3)
        self.assertTrue(any("not completed any cognitive activities" in a["message"] for a in alerts))
        self.assertTrue(any("reminders remain incomplete" in a["message"] for a in alerts))
        for a in alerts:
            self.assertNotIn("deteriorat", a["message"].lower())
            self.assertNotIn("worsen", a["message"].lower())

    def test_todays_activity_recommendation(self):
        activity = self.rec_engine.get_todays_activity("ifra_01", [])
        self.assertEqual(activity["game_id"], "remember_objects")
        self.assertEqual(activity["recommended_level"], 1)
        self.assertEqual(activity["target_games_today"], 4)


if __name__ == "__main__":
    unittest.main()
