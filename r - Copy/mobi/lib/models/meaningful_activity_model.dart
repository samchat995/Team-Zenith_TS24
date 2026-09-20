class MeaningfulActivityItem {
  final String id;
  final String type; // gardening, painting, reading, music, household, family, storytelling
  final String titleKey;
  final String emoji;
  final String descKey;
  final int defaultMinutes;

  const MeaningfulActivityItem({
    required this.id,
    required this.type,
    required this.titleKey,
    required this.emoji,
    required this.descKey,
    required this.defaultMinutes,
  });
}

class ActivityLog {
  final String id;
  final String patientId;
  final String activityType;
  final int durationMinutes;
  final String engagement; // Great, Good, Calm
  final String? note;
  final int xpEarned;
  final DateTime completedAt;

  ActivityLog({
    required this.id,
    required this.patientId,
    required this.activityType,
    required this.durationMinutes,
    required this.engagement,
    this.note,
    this.xpEarned = 20,
    DateTime? completedAt,
  }) : completedAt = completedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'activity_type': activityType,
    'duration_minutes': durationMinutes,
    'engagement': engagement,
    'note': note,
    'xp_earned': xpEarned,
    'completed_at': completedAt.toIso8601String(),
  };
}
