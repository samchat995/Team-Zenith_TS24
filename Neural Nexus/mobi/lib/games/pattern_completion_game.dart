import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/game_session_model.dart';
import '../../services/auth_service.dart';

class PatternCompletionGame extends StatefulWidget {
  const PatternCompletionGame({super.key});

  @override
  State<PatternCompletionGame> createState() => _PatternCompletionGameState();
}

class _PatternCompletionGameState extends State<PatternCompletionGame> {
  int _round = 1;
  int _score = 0;
  bool _finished = false;

  final List<Map<String, dynamic>> _patterns = [
    {
      'sequence': ['⚪', '🟦', '⚪', '🟦', '❓'],
      'choices': ['⚪', '🔺', '⭐'],
      'correct': '⚪',
      'hint': 'Circle follows Square, then Circle again!'
    },
    {
      'sequence': ['🍎', '🍌', '🍎', '🍌', '❓'],
      'choices': ['🍎', '🍇', '🍊'],
      'correct': '🍎',
      'hint': 'Apple follows Banana!'
    },
    {
      'sequence': ['🌞', '🌙', '🌞', '🌙', '❓'],
      'choices': ['🌞', '⭐', '☁️'],
      'correct': '🌞',
      'hint': 'Sun follows Moon!'
    },
  ];

  void _chooseAnswer(String choice) {
    final cur = _patterns[_round - 1];
    if (choice == cur['correct']) {
      _score += 30;
      if (_round < _patterns.length) {
        setState(() => _round++);
      } else {
        setState(() => _finished = true);
        _saveSession();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Let us try once more. ${cur['hint']}')),
      );
    }
  }

  Future<void> _saveSession() async {
    final patientId = AuthService.instance.patientId ?? 'ifra_01';
    final session = GameSessionModel(
      patientId: patientId,
      gameId: 'pattern_completion',
      category: 'pattern',
      level: 1,
      score: _score,
      accuracy: 90.0,
      attempts: 3,
      mistakes: 0,
      responseTimeMs: 1500,
      durationSeconds: 22,
      completed: true,
      offlineCreated: true,
    );
    await DatabaseHelper.instance.insertSession(session);
  }

  @override
  Widget build(BuildContext context) {
    final cur = _patterns[_round - 1];
    final seq = cur['sequence'] as List<String>;
    final choices = cur['choices'] as List<String>;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: const Text('Pattern Completion', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
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
                        const Text('🧩', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 8),
                        const Text('Pattern Solved!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
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
                    Text('Round $_round of ${_patterns.length}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF7C3AED))),
                    const SizedBox(height: 16),
                    const Text(
                      'Look at the pattern below.\nWhich shape completes the question mark?',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 24),

                    // Pattern Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFDDD6FE))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: seq.map((item) {
                          return Text(item, style: const TextStyle(fontSize: 34));
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 36),

                    const Text('Choose the next shape:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                    const SizedBox(height: 16),

                    // Choices
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: choices.map((c) {
                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          elevation: 2,
                          child: InkWell(
                            onTap: () => _chooseAnswer(c),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 84,
                              height: 84,
                              alignment: Alignment.center,
                              child: Text(c, style: const TextStyle(fontSize: 40)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
