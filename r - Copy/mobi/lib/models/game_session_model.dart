class GameSessionModel {
  final String? id;
  final String patientId;
  final String gameId;
  final String category;
  final int level;
  final int score;
  final double accuracy;
  final int attempts;
  final int mistakes;
  final int responseTimeMs;
  final int durationSeconds;
  final bool completed;
  final DateTime completedAt;
  final bool offlineCreated;
  final bool synced;

  GameSessionModel({
    this.id,
    required this.patientId,
    required this.gameId,
    required this.category,
    this.level = 1,
    this.score = 0,
    this.accuracy = 0.0,
    this.attempts = 1,
    this.mistakes = 0,
    this.responseTimeMs = 1000,
    this.durationSeconds = 30,
    this.completed = true,
    DateTime? completedAt,
    this.offlineCreated = false,
    this.synced = false,
  }) : completedAt = completedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'game_id': gameId,
      'category': category,
      'level': level,
      'score': score,
      'accuracy': accuracy,
      'attempts': attempts,
      'mistakes': mistakes,
      'response_time_ms': responseTimeMs,
      'duration_seconds': durationSeconds,
      'completed': completed ? 1 : 0,
      'completed_at': completedAt.toIso8601String(),
      'offline_created': offlineCreated ? 1 : 0,
      'synced': synced ? 1 : 0,
    };
  }

  factory GameSessionModel.fromMap(Map<String, dynamic> map) {
    return GameSessionModel(
      id: map['id'],
      patientId: map['patient_id'] ?? '',
      gameId: map['game_id'] ?? '',
      category: map['category'] ?? '',
      level: map['level'] ?? 1,
      score: map['score'] ?? 0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
      attempts: map['attempts'] ?? 1,
      mistakes: map['mistakes'] ?? 0,
      responseTimeMs: map['response_time_ms'] ?? 1000,
      durationSeconds: map['duration_seconds'] ?? 30,
      completed: map['completed'] == 1 || map['completed'] == true,
      completedAt: DateTime.tryParse(map['completed_at'] ?? '') ?? DateTime.now(),
      offlineCreated: map['offline_created'] == 1 || map['offline_created'] == true,
      synced: map['synced'] == 1 || map['synced'] == true,
    );
  }
}
