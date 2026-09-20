import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/game_session_model.dart';
import '../../services/auth_service.dart';

class EmotionRecognitionGame extends StatefulWidget {
  const EmotionRecognitionGame({super.key});

  @override
  State<EmotionRecognitionGame> createState() => _EmotionRecognitionGameState();
}

class _EmotionRecognitionGameState extends State<EmotionRecognitionGame> {
  int _round = 1;
  int _score = 0;
  bool _finished = false;

  final List<Map<String, dynamic>> _faces = [
    {
      'emoji': '😊',
      'label': 'Happy',
      'options': ['Happy', 'Sad', 'Angry'],
    },
    {
      'emoji': '🙂',
      'label': 'Calm',
      'options': ['Calm', 'Worried', 'Surprised'],
    },
    {
      'emoji': '😮',
      'label': 'Surprised',
      'options': ['Surprised', 'Angry', 'Sleepy'],
    },
  ];

  void _chooseEmotion(String choice) {
    final cur = _faces[_round - 1];
    if (choice == cur['label']) {
      _score += 30;
      if (_round < _faces.length) {
        setState(() => _round++);
      } else {
        setState(() => _finished = true);
        _saveSession();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Take another look at the smiling eyes and mouth!')),
      );
    }
  }

  Future<void> _saveSession() async {
    final patientId = AuthService.instance.patientId ?? 'ifra_01';
    final session = GameSessionModel(
      patientId: patientId,
      gameId: 'emotion_recognition',
      category: 'emotion',
      level: 1,
      score: _score,
      accuracy: 90.0,
      attempts: 3,
      mistakes: 0,
      responseTimeMs: 1300,
      durationSeconds: 20,
      completed: true,
      offlineCreated: true,
    );
    await DatabaseHelper.instance.insertSession(session);
  }

  @override
  Widget build(BuildContext context) {
    final cur = _faces[_round - 1];
    final options = cur['options'] as List<String>;

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        title: const Text('Emotion Recognition', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
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
                        const Text('❤️', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 8),
                        const Text('Great Recognition!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text('Score: $_score points', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {
                            _round = 1;
                            _score = 0;
                            _finished = false;
                          }),
                          child: const Text('Play Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Text('Face $_round of ${_faces.length}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
                    const SizedBox(height: 14),
                    const Text(
                      'How does this person feel?',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 24),

                    // Big Friendly Face
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16)],
                      ),
                      child: Center(
                        child: Text(cur['emoji'] as String, style: const TextStyle(fontSize: 72)),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Large Answer Buttons
                    ...options.map((opt) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _chooseEmotion(opt),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0F172A),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
                              ),
                              elevation: 0,
                            ),
                            child: Text(opt, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
