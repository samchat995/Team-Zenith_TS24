import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/game_session_model.dart';
import '../../services/auth_service.dart';

class TwinShapesGame extends StatefulWidget {
  const TwinShapesGame({super.key});

  @override
  State<TwinShapesGame> createState() => _TwinShapesGameState();
}

class _TwinShapesGameState extends State<TwinShapesGame> {
  int _score = 0;
  int _round = 1;
  bool _finished = false;

  final List<Map<String, dynamic>> _questions = [
    {
      'instruction': 'Find the shape with the SAME COLOR as the target:',
      'target': {'shape': 'circle', 'color': Color(0xFFEF4444), 'name': 'Red Circle'},
      'options': [
        {'shape': 'square', 'color': Color(0xFFEF4444), 'name': 'Red Square', 'correct': true},
        {'shape': 'circle', 'color': Color(0xFF3B82F6), 'name': 'Blue Circle', 'correct': false},
        {'shape': 'triangle', 'color': Color(0xFF10B981), 'name': 'Green Triangle', 'correct': false},
      ],
    },
    {
      'instruction': 'Find the shape with the SAME SHAPE as the target:',
      'target': {'shape': 'square', 'color': Color(0xFF10B981), 'name': 'Green Square'},
      'options': [
        {'shape': 'circle', 'color': Color(0xFF10B981), 'name': 'Green Circle', 'correct': false},
        {'shape': 'square', 'color': Color(0xFFF59E0B), 'name': 'Amber Square', 'correct': true},
        {'shape': 'triangle', 'color': Color(0xFF3B82F6), 'name': 'Blue Triangle', 'correct': false},
      ],
    },
    {
      'instruction': 'Find the EXACT TWIN (Same Shape AND Same Color):',
      'target': {'shape': 'circle', 'color': Color(0xFF3B82F6), 'name': 'Blue Circle'},
      'options': [
        {'shape': 'circle', 'color': Color(0xFFEF4444), 'name': 'Red Circle', 'correct': false},
        {'shape': 'square', 'color': Color(0xFF3B82F6), 'name': 'Blue Square', 'correct': false},
        {'shape': 'circle', 'color': Color(0xFF3B82F6), 'name': 'Blue Circle', 'correct': true},
      ],
    },
  ];

  void _chooseOption(bool correct) {
    if (correct) {
      _score += 30;
      if (_round < _questions.length) {
        setState(() => _round++);
      } else {
        setState(() => _finished = true);
        _saveSession();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Take your time. Let us look at the shape and color carefully.')),
      );
    }
  }

  Future<void> _saveSession() async {
    final patientId = AuthService.instance.patientId ?? 'ifra_01';
    final session = GameSessionModel(
      patientId: patientId,
      gameId: 'twin_shapes',
      category: 'attention',
      level: 1,
      score: _score,
      accuracy: 90.0,
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
    final cur = _questions[_round - 1];
    final target = cur['target'] as Map<String, dynamic>;
    final options = cur['options'] as List<Map<String, dynamic>>;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Twin Shapes & Colors', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
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
                        const Text('🔴 🟢 🔵', style: TextStyle(fontSize: 36)),
                        const SizedBox(height: 12),
                        const Text('Shapes Matched!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
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
                    Text('Round $_round of ${_questions.length}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
                    const SizedBox(height: 12),
                    Text(
                      cur['instruction'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 20),

                    // Target Shape Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Column(
                        children: [
                          const Text('TARGET OBJECT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                          const SizedBox(height: 10),
                          _renderShape(target['shape'], target['color']),
                          const SizedBox(height: 8),
                          Text(target['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Options Grid
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: options.map((opt) {
                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            elevation: 2,
                            child: InkWell(
                              onTap: () => _chooseOption(opt['correct'] as bool),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 100,
                                height: 130,
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _renderShape(opt['shape'], opt['color']),
                                    const SizedBox(height: 10),
                                    Text(opt['name'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _renderShape(String shape, Color color) {
    if (shape == 'circle') {
      return Container(width: 50, height: 50, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
    } else if (shape == 'square') {
      return Container(width: 48, height: 48, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)));
    } else {
      return Icon(Icons.change_history_rounded, size: 54, color: color);
    }
  }
}
