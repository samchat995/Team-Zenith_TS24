class ReminderModel {
  final String id;
  final String patientId;
  final String title;
  final String reminderType; // medicine, hydration, daily_activity, appointment
  final String timeOfDay;
  final String frequency;
  final bool completed;
  final String? notes;

  ReminderModel({
    required this.id,
    required this.patientId,
    required this.title,
    required this.reminderType,
    required this.timeOfDay,
    this.frequency = 'Daily',
    this.completed = false,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'title': title,
      'reminder_type': reminderType,
      'time_of_day': timeOfDay,
      'frequency': frequency,
      'completed': completed ? 1 : 0,
      'notes': notes,
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id']?.toString() ?? '',
      patientId: map['patient_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      reminderType: map['reminder_type']?.toString() ?? 'medicine',
      timeOfDay: map['time_of_day']?.toString() ?? '09:00 AM',
      frequency: map['frequency']?.toString() ?? 'Daily',
      completed: map['completed'] == 1 || map['completed'] == true,
      notes: map['notes']?.toString(),
    );
  }

  ReminderModel copyWith({bool? completed}) {
    return ReminderModel(
      id: id,
      patientId: patientId,
      title: title,
      reminderType: reminderType,
      timeOfDay: timeOfDay,
      frequency: frequency,
      completed: completed ?? this.completed,
      notes: notes,
    );
  }
}
