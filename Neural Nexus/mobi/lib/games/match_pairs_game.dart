import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/game_session_model.dart';
import '../../services/auth_service.dart';

class MatchPairsGame extends StatefulWidget {
  const MatchPairsGame({super.key});

  @override
  State<MatchPairsGame> createState() => _MatchPairsGameState();
}

class _MatchPairsGameState extends State<MatchPairsGame> {
  int _score = 0;
  int _round = 1;
  bool _finished = false;

  final List<Map<String, dynamic>> _pairs = [
    {
      'item': '☕ Teacup',
      'question': 'What goes naturally with a Teacup?',
      'choices': [
        {'text': '🍽️ Saucer', 'correct': true},
        {'text': '🔑 House Key', 'correct': false},
        {'text': '🧦 Sock', 'correct': false},
      ]
    },
    {
      'item': '🔒 Lock',
      'question': 'What goes naturally with a Lock?',
      'choices': [
        {'text': '🔑 Key', 'correct': true},
        {'text': '🪑 Chair', 'correct': false},
        {'text': '🍎 Apple', 'correct': false},
      ]
    },
    {
      'item': '🪥 Toothbrush',
      'question': 'What goes naturally with a Toothbrush?',
      'choices': [
        {'text': '🫧 Toothpaste', 'correct': true},
        {'text': '☕ Teacup', 'correct': false},
        {'text': '📖 Book', 'correct': false},
      ]
    },
  ];

  void _choose(bool correct) {
    if (correct) _score += 30;
    if (_round < _pairs.length) {
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
      gameId: 'match_pairs',
      category: 'pattern',
      level: 1,
      score: _score,
      accuracy: 95.0,
      attempts: 3,
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
    final cur = _pairs[_round - 1];
    final choices = cur['choices'] as List<Map<String, dynamic>>;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Match Related Pairs', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
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
                        const Text('☕🍽️', style: TextStyle(fontSize: 42)),
                        const SizedBox(height: 8),
                        const Text('Pairs Connected!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
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
                    Text('Pair $_round of ${_pairs.length}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
                    const SizedBox(height: 14),
                    Text(cur['question'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
                      child: Text(cur['item'] as String, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                    ),
                    const SizedBox(height: 36),

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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5)),
                              elevation: 0,
                            ),
                            child: Text(c['text'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
