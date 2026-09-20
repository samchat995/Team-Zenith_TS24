class MoodModel {
  final String? id;
  final String patientId;
  final String mood; // Happy, Calm, Okay, Tired, Worried
  final String? note;
  final DateTime loggedAt;

  MoodModel({
    this.id,
    required this.patientId,
    required this.mood,
    this.note,
    DateTime? loggedAt,
  }) : loggedAt = loggedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'mood': mood,
      'note': note,
      'logged_at': loggedAt.toIso8601String(),
    };
  }

  factory MoodModel.fromMap(Map<String, dynamic> map) {
    return MoodModel(
      id: map['id']?.toString(),
      patientId: map['patient_id']?.toString() ?? '',
      mood: map['mood']?.toString() ?? 'Calm',
      note: map['note']?.toString(),
      loggedAt: DateTime.tryParse(map['logged_at'] ?? '') ?? DateTime.now(),
    );
  }
}
