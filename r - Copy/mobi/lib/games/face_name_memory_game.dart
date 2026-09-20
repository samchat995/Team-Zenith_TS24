import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/game_session_model.dart';
import '../../services/auth_service.dart';

class FaceNameMemoryGame extends StatefulWidget {
  const FaceNameMemoryGame({super.key});

  @override
  State<FaceNameMemoryGame> createState() => _FaceNameMemoryGameState();
}

class _FaceNameMemoryGameState extends State<FaceNameMemoryGame> {
  int _score = 0;
  bool _finished = false;

  final List<Map<String, dynamic>> _profiles = [
    {
      'name': 'Meena',
      'relation': 'Granddaughter',
      'avatar': '👧',
      'question': 'Who is Meena?',
      'choices': [
        {'text': '👧 Granddaughter', 'correct': true},
        {'text': '👵 Neighbor', 'correct': false},
        {'text': '👩 Doctor', 'correct': false},
      ]
    },
    {
      'name': 'Farhan',
      'relation': 'Son',
      'avatar': '👨',
      'question': 'What is your son\'s name?',
      'choices': [
        {'text': '👨 Farhan', 'correct': true},
        {'text': '👨 Vikram', 'correct': false},
        {'text': '👨 Rajesh', 'correct': false},
      ]
    },
  ];

  int _currentIndex = 0;

  void _choose(bool correct) {
    if (correct) _score += 40;
    if (_currentIndex < _profiles.length - 1) {
      setState(() => _currentIndex++);
    } else {
      setState(() => _finished = true);
      _saveSession();
    }
  }

  Future<void> _saveSession() async {
    final patientId = AuthService.instance.patientId ?? 'ifra_01';
    final session = GameSessionModel(
      patientId: patientId,
      gameId: 'face_name_memory',
      category: 'memory',
      level: 1,
      score: _score,
      accuracy: 95.0,
      attempts: 2,
      mistakes: 0,
      responseTimeMs: 1400,
      durationSeconds: 20,
      completed: true,
      offlineCreated: true,
    );
    await DatabaseHelper.instance.insertSession(session);
  }

  @override
  Widget build(BuildContext context) {
    final cur = _profiles[_currentIndex];
    final choices = cur['choices'] as List<Map<String, dynamic>>;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF4FF),
      appBar: AppBar(
        title: const Text('Face & Name Memory', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
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
                        const Text('🌸', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 8),
                        const Text('Family Faces Remembered!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text('Score: $_score points', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {
                            _currentIndex = 0;
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
                    Text('Profile ${_currentIndex + 1} of ${_profiles.length}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFC026D3))),
                    const SizedBox(height: 14),
                    Text(cur['question'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    const SizedBox(height: 20),

                    Container(
                      width: 130,
                      height: 130,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                      child: Center(child: Text(cur['avatar'] as String, style: const TextStyle(fontSize: 64))),
                    ),
                    const SizedBox(height: 10),
                    Text(cur['name'] as String, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    const SizedBox(height: 28),

                    ...choices.map((c) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _choose(c['correct'] as bool),
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
                            child: Text(c['text'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
