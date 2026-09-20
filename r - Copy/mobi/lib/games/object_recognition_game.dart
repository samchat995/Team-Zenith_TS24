import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/game_session_model.dart';
import '../../services/auth_service.dart';

class ObjectRecognitionGame extends StatefulWidget {
  const ObjectRecognitionGame({super.key});

  @override
  State<ObjectRecognitionGame> createState() => _ObjectRecognitionGameState();
}

class _ObjectRecognitionGameState extends State<ObjectRecognitionGame> {
  int _score = 0;
  int _index = 0;
  bool _finished = false;

  final List<Map<String, dynamic>> _items = [
    {
      'emoji': '🕰️',
      'question': 'What is this object?',
      'choices': [
        {'text': 'Clock (घड़ी / ঘড়ী)', 'correct': true},
        {'text': 'Radio (रेडियो / ৰেডিঅ\')', 'correct': false},
        {'text': 'Mirror (आईना / আইনা)', 'correct': false},
      ]
    },
    {
      'emoji': '👓',
      'question': 'What is this object?',
      'choices': [
        {'text': 'Spectacles (चश्मा / চশমা)', 'correct': true},
        {'text': 'Binoculars (दूरबीन / দুৰবীণ)', 'correct': false},
        {'text': 'Magnifier (लेंस / আতচী কাঁচ)', 'correct': false},
      ]
    },
  ];

  void _choose(bool correct) {
    if (correct) _score += 40;
    if (_index < _items.length - 1) {
      setState(() => _index++);
    } else {
      setState(() => _finished = true);
      _saveSession();
    }
  }

  Future<void> _saveSession() async {
    final patientId = AuthService.instance.patientId ?? 'ifra_01';
    final session = GameSessionModel(
      patientId: patientId,
      gameId: 'object_recognition',
      category: 'language',
      level: 1,
      score: _score,
      accuracy: 95.0,
      attempts: 2,
      mistakes: 0,
      responseTimeMs: 1200,
      durationSeconds: 15,
      completed: true,
      offlineCreated: true,
    );
    await DatabaseHelper.instance.insertSession(session);
  }

  @override
  Widget build(BuildContext context) {
    final cur = _items[_index];
    final choices = cur['choices'] as List<Map<String, dynamic>>;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Object Recognition', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
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
                        const Text('🕰️', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 8),
                        const Text('Objects Recognized!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text('Score: $_score points', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {
                            _index = 0;
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
                    Text('Item ${_index + 1} of ${_items.length}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
                    const SizedBox(height: 12),
                    Text(cur['question'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 24),

                    Container(
                      width: 140,
                      height: 140,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                      child: Center(child: Text(cur['emoji'] as String, style: const TextStyle(fontSize: 72))),
                    ),
                    const SizedBox(height: 32),

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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE2E8F0), width: 2)),
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
