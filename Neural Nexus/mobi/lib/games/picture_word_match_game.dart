import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/game_session_model.dart';
import '../../services/auth_service.dart';

class PictureWordMatchGame extends StatefulWidget {
  const PictureWordMatchGame({super.key});

  @override
  State<PictureWordMatchGame> createState() => _PictureWordMatchGameState();
}

class _PictureWordMatchGameState extends State<PictureWordMatchGame> {
  int _score = 0;
  int _round = 1;
  bool _finished = false;

  final List<Map<String, dynamic>> _rounds = [
    {
      'emoji': '🍎',
      'options': [
        {'word': 'APPLE', 'correct': true},
        {'word': 'CHAIR', 'correct': false},
        {'word': 'BOOK', 'correct': false},
      ]
    },
    {
      'emoji': '📖',
      'options': [
        {'word': 'GLASSES', 'correct': false},
        {'word': 'BOOK', 'correct': true},
        {'word': 'CLOCK', 'correct': false},
      ]
    },
    {
      'emoji': '☕',
      'options': [
        {'word': 'WATER', 'correct': false},
        {'word': 'TEACUP', 'correct': true},
        {'word': 'TABLE', 'correct': false},
      ]
    },
  ];

  void _choose(bool correct) {
    if (correct) _score += 30;
    if (_round < _rounds.length) {
      setState(() => _round++);
    } else {
      setState(() => _finished = true);
      _saveSession();
    }
  }

  Future<void> _saveSession() async {
    final patientId = AuthService.instance.patientId ?? 'ifra_01';
    final session = GameSessionModel(
      patientId: patientId,
      gameId: 'picture_word_match',
      category: 'language',
      level: 1,
      score: _score,
      accuracy: 95.0,
      attempts: 3,
      mistakes: 0,
      responseTimeMs: 1200,
      durationSeconds: 18,
      completed: true,
      offlineCreated: true,
    );
    await DatabaseHelper.instance.insertSession(session);
  }

  @override
  Widget build(BuildContext context) {
    final cur = _rounds[_round - 1];
    final options = cur['options'] as List<Map<String, dynamic>>;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Picture & Word Match', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
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
                        const Text('🍎📖☕', style: TextStyle(fontSize: 36)),
                        const SizedBox(height: 8),
                        const Text('Great Matching!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
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
                    Text('Item $_round of ${_rounds.length}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
                    const SizedBox(height: 14),
                    const Text('Which word matches this picture?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 24),

                    Container(
                      width: 140,
                      height: 140,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                      child: Center(child: Text(cur['emoji'] as String, style: const TextStyle(fontSize: 72))),
                    ),
                    const SizedBox(height: 36),

                    ...options.map((opt) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _choose(opt['correct'] as bool),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0F172A),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE2E8F0), width: 2)),
                              elevation: 0,
                            ),
                            child: Text(opt['word'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
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
