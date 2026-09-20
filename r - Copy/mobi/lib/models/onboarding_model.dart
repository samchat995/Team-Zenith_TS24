class OnboardingQuestion {
  final int id;
  final String questionEn;
  final String questionHi;
  final String questionAs;
  final String category;
  final List<String> optionsEn;
  final List<String> optionsHi;
  final List<String> optionsAs;

  const OnboardingQuestion({
    required this.id,
    required this.questionEn,
    required this.questionHi,
    required this.questionAs,
    required this.category,
    required this.optionsEn,
    required this.optionsHi,
    required this.optionsAs,
  });

  String getQuestion(String lang) {
    if (lang == 'hi') return questionHi;
    if (lang == 'as') return questionAs;
    return questionEn;
  }

  List<String> getOptions(String lang) {
    if (lang == 'hi') return optionsHi;
    if (lang == 'as') return optionsAs;
    return optionsEn;
  }
}

class OnboardingAnswer {
  final int questionId;
  final String answer;
  final bool skipped;
  final DateTime answeredAt;

  OnboardingAnswer({
    required this.questionId,
    required this.answer,
    this.skipped = false,
    DateTime? answeredAt,
  }) : answeredAt = answeredAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'answer': answer,
    'skipped': skipped,
    'answered_at': answeredAt.toIso8601String(),
  };

  factory OnboardingAnswer.fromJson(Map<String, dynamic> json) => OnboardingAnswer(
    questionId: json['question_id'] as int,
    answer: json['answer'] as String,
    skipped: json['skipped'] as bool? ?? false,
    answeredAt: DateTime.tryParse(json['answered_at'] as String? ?? '') ?? DateTime.now(),
  );
}
