"""
Performance Analyzer for Neural Nexus.
Aggregates cognitive domain trends and non-alarmist caregiver alerts.
"""
from typing import List, Dict, Any
from collections import defaultdict
import numpy as np
from .models import GameTelemetry
from .feature_engineering import extract_features


class PerformanceAnalyzer:
    DOMAINS = ["memory", "attention", "pattern", "routine", "language", "auditory", "emotion"]

    def analyze_domains(self, all_sessions: List[GameTelemetry]) -> Dict[str, Any]:
        """
        Analyzes performance segmented by cognitive domain.
        """
        domain_sessions = defaultdict(list)
        for s in all_sessions:
            cat = s.category.lower()
            domain_sessions[cat].append(s)

        domain_results = {}
        for domain in self.DOMAINS:
            sessions = domain_sessions.get(domain, [])
            if sessions:
                metrics = extract_features(sessions)
                domain_results[domain] = {
                    "total_sessions": len(sessions),
                    "composite_score": metrics.composite_score,
                    "avg_accuracy": metrics.accuracy_score,
                    "avg_speed": metrics.speed_score,
                    "consistency": metrics.consistency_score,
                    "completion_rate": metrics.completion_rate
                }
            else:
                domain_results[domain] = {
                    "total_sessions": 0,
                    "composite_score": 0.0,
                    "avg_accuracy": 0.0,
                    "avg_speed": 0.0,
                    "consistency": 0.0,
                    "completion_rate": 0.0
                }

        overall_metrics = extract_features(all_sessions)
        return {
            "overall": overall_metrics.model_dump(),
            "domains": domain_results,
            "total_games_played": len(all_sessions)
        }

    def generate_caregiver_alerts(self, recent_sessions: List[GameTelemetry], pending_reminders_count: int = 0) -> List[Dict[str, str]]:
        """
        Generates helpful, non-alarmist caregiver notifications.
        STRICT COMPLIANCE: Never say 'dementia worsening' or 'medical deterioration'.
        """
        alerts = []

        if not recent_sessions:
            alerts.append({
                "type": "info",
                "message": "Patient has not completed any cognitive activities today. A friendly reminder may help."
            })
        elif len(recent_sessions) < 2:
            alerts.append({
                "type": "info",
                "message": "Recent game activity is lower than usual. Please check in with the patient."
            })

        if pending_reminders_count >= 3:
            alerts.append({
                "type": "warning",
                "message": f"{pending_reminders_count} reminders remain incomplete. Please check in to ensure hydration and medicine routine."
            })

        if recent_sessions:
            recent_accuracy = np.mean([s.accuracy for s in recent_sessions[-3:]])
            if recent_accuracy < 45.0:
                alerts.append({
                    "type": "gentle",
                    "message": "Patient seemed fatigued in recent sessions. Consider encouraging a short rest or hydration break."
                })

        return alerts
