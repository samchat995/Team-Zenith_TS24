import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/game_session_model.dart';
import '../../services/auth_service.dart';

class StoryRecallGame extends StatefulWidget {
  const StoryRecallGame({super.key});

  @override
  State<StoryRecallGame> createState() => _StoryRecallGameState();
}

class _StoryRecallGameState extends State<StoryRecallGame> {
  int _questionIndex = 0;
  int _score = 0;
  bool _finished = false;

  final String _story =
      '"Rita went to the garden in the morning. She gently watered the yellow marigolds and then returned home to drink warm tea."';

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Where did Rita go in the morning?',
      'choices': [
        {'text': 'To the Garden', 'correct': true},
        {'text': 'To the Market', 'correct': false},
      ],
    },
    {
      'question': 'What did Rita water?',
      'choices': [
        {'text': 'The Flowers', 'correct': true},
        {'text': 'The Vegetables', 'correct': false},
      ],
    },
    {
      'question': 'What did she drink after returning home?',
      'choices': [
        {'text': 'Warm Tea', 'correct': true},
        {'text': 'Cold Juice', 'correct': false},
      ],
    },
  ];

  void _chooseAnswer(bool correct) {
    if (correct) {
      _score += 30;
    }
    if (_questionIndex < _questions.length - 1) {
      setState(() => _questionIndex++);
    } else {
      setState(() => _finished = true);
      _saveSession();
    }
  }

  Future<void> _saveSession() async {
    final patientId = AuthService.instance.patientId ?? 'ifra_01';
    final session = GameSessionModel(
      patientId: patientId,
      gameId: 'story_recall',
      category: 'language',
      level: 1,
      score: _score,
      accuracy: (_score / 90.0) * 100.0,
      attempts: 3,
      mistakes: 0,
      responseTimeMs: 2000,
      durationSeconds: 30,
      completed: true,
      offlineCreated: true,
    );
    await DatabaseHelper.instance.insertSession(session);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: const Text('Story Recall', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _finished
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📖', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 8),
                        const Text('Story Completed!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text('Score: $_score / 90 points', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {
                            _questionIndex = 0;
                            _score = 0;
                            _finished = false;
                          }),
                          child: const Text('Read Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Story Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFED7AA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('SHORT STORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFD97706))),
                              Icon(Icons.volume_up_rounded, color: Color(0xFF2563EB)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(_story, style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B), height: 1.45, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Question ${_questionIndex + 1} of ${_questions.length}',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _questions[_questionIndex]['question'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 20),

                    // 2 Large Answer Buttons
                    ...(_questions[_questionIndex]['choices'] as List<Map<String, dynamic>>).map((choice) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _chooseAnswer(choice['correct'] as bool),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0F172A),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                              ),
                              elevation: 0,
                            ),
                            child: Text(choice['text'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
        ),
      ),
    );
  }
}
