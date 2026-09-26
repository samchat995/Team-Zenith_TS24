"""
Recommendation Engine for Neural Nexus.
Selects personalized 'Today's Activity' and recommended games across cognitive domains.
Combines Scikit-Learn logic with explainable rule-based fallback.
"""
from typing import List, Dict, Any, Optional
from collections import Counter
from .models import GameTelemetry, AdaptiveRecommendation
from .difficulty_engine import DifficultyEngine
from .performance_analyzer import PerformanceAnalyzer


class RecommendationEngine:
    GAMES_CATALOG = [
        {"id": "remember_objects", "title": "Remember the Objects", "category": "memory", "desc": "A short activity to exercise your memory"},
        {"id": "memory_match", "title": "Memory Match", "category": "memory", "desc": "Find matching pairs of familiar objects"},
        {"id": "routine_order", "title": "Daily Routine Order", "category": "routine", "desc": "Arrange your daily morning activities"},
        {"id": "find_different", "title": "Find the Different Object", "category": "attention", "desc": "Spot the object that looks different"},
        {"id": "twin_shapes", "title": "Twin Shapes & Colors", "category": "attention", "desc": "Match matching shapes and soothing colors"},
        {"id": "pattern_completion", "title": "Pattern Completion", "category": "pattern", "desc": "Complete the simple visual pattern"},
        {"id": "object_categorization", "title": "Object Categorization", "category": "pattern", "desc": "Sort familiar items into helpful groups"},
        {"id": "story_recall", "title": "Story Recall", "category": "language", "desc": "Listen to a calm short story and recall details"},
        {"id": "emotion_recognition", "title": "Emotion Recognition", "category": "emotion", "desc": "Identify feelings from friendly faces"},
        {"id": "face_name_memory", "title": "Face & Name Memory", "category": "memory", "desc": "Recognize familiar friends and family"},
        {"id": "location_memory", "title": "Location Memory", "category": "memory", "desc": "Recall where objects were placed in the home"},
        {"id": "sound_memory", "title": "Sound Memory", "category": "auditory", "desc": "Listen and recall pleasant soothing sounds"},
        {"id": "word_recall", "title": "Word Recall", "category": "language", "desc": "Remember gentle everyday words"},
        {"id": "object_recognition", "title": "Object Recognition", "category": "language", "desc": "Name familiar items around the house"},
        {"id": "sequence_recall", "title": "Sequence Recall", "category": "memory", "desc": "Recall the sequence of 3 familiar items"},
        {"id": "missing_object", "title": "Which One is Missing?", "category": "memory", "desc": "Spot which familiar item was removed"},
        {"id": "match_pairs", "title": "Match Related Pairs", "category": "pattern", "desc": "Match cup with saucer, lock with key"},
        {"id": "picture_word_match", "title": "Picture & Word Match", "category": "language", "desc": "Match everyday picture with its name"}
    ]

    def __init__(self):
        self.diff_engine = DifficultyEngine()
        self.analyzer = PerformanceAnalyzer()

    def get_todays_activity(self, patient_id: str, history: List[GameTelemetry]) -> Dict[str, Any]:
        """
        Recommends the primary 'Today's Activity' displayed on the patient dashboard.
        By default or for variety, picks 'Remember the Objects' or rotates to an under-practiced domain.
        """
        if not history:
            default_game = self.GAMES_CATALOG[0]  # remember_objects
            return {
                "game_id": default_game["id"],
                "title": default_game["title"],
                "category": default_game["category"],
                "description": default_game["desc"],
                "recommended_level": 1,
                "reason": "Welcome! Let's start your day with a calm, gentle memory exercise.",
                "games_completed_today": 0,
                "target_games_today": 4,
                "progress_percentage": 0.0
            }

        # Calculate domains played recently
        recent_categories = [s.category.lower() for s in history[-5:]]
        cat_counts = Counter(recent_categories)

        # Find under-exercised category
        preferred_category = "memory"
        for candidate in ["memory", "attention", "pattern", "routine", "language"]:
            if cat_counts[candidate] == 0:
                preferred_category = candidate
                break

        # Pick game in preferred category
        candidates = [g for g in self.GAMES_CATALOG if g["category"] == preferred_category]
        chosen_game = candidates[0] if candidates else self.GAMES_CATALOG[0]

        # Calculate level for this game
        game_history = [s for s in history if s.game_id == chosen_game["id"]]
        current_level = game_history[-1].level if game_history else 1
        rec = self.diff_engine.evaluate_difficulty(patient_id, chosen_game["id"], current_level, game_history[-3:])

        completed_today = len([s for s in history if s.completed])
        progress_pct = min(100.0, round((completed_today / 4.0) * 100.0, 1))

        return {
            "game_id": chosen_game["id"],
            "title": chosen_game["title"],
            "category": chosen_game["category"],
            "description": chosen_game["desc"],
            "recommended_level": rec.recommended_level,
            "reason": rec.reason,
            "games_completed_today": completed_today,
            "target_games_today": 4,
            "progress_percentage": progress_pct
        }
