import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/game_session_model.dart';
import '../../services/auth_service.dart';

class FindDifferentGame extends StatefulWidget {
  const FindDifferentGame({super.key});

  @override
  State<FindDifferentGame> createState() => _FindDifferentGameState();
}

class _FindDifferentGameState extends State<FindDifferentGame> {
  int _round = 1;
  int _score = 0;
  bool _finished = false;
  final Stopwatch _stopwatch = Stopwatch();

  final List<Map<String, dynamic>> _rounds = [
    {
      'common': '🍎',
      'different': '🍊',
      'common_name': 'Apple',
      'diff_name': 'Orange',
      'count': 6,
    },
    {
      'common': '☕',
      'different': '🥛',
      'common_name': 'Teacup',
      'diff_name': 'Water Glass',
      'count': 8,
    },
    {
      'common': '🌸',
      'different': '🌻',
      'common_name': 'Pink Flower',
      'diff_name': 'Sunflower',
      'count': 9,
    },
  ];

  late List<String> _currentGrid;
  late int _differentIndex;

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  void _startRound() {
    final cur = _rounds[_round - 1];
    final int count = cur['count'];
    final common = cur['common'] as String;
    final different = cur['different'] as String;

    _differentIndex = (count * 0.6).floor(); // pseudorandom placement
    _currentGrid = List.generate(count, (i) => i == _differentIndex ? different : common);

    _stopwatch.reset();
    _stopwatch.start();
  }

  void _selectItem(int index) {
    _stopwatch.stop();
    if (index == _differentIndex) {
      _score += 30;
      if (_round < _rounds.length) {
        setState(() {
          _round++;
          _startRound();
        });
      } else {
        setState(() => _finished = true);
        _saveSession();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Look closely for the one that looks different!')),
      );
    }
  }

  Future<void> _saveSession() async {
    final patientId = AuthService.instance.patientId ?? 'ifra_01';
    final session = GameSessionModel(
      patientId: patientId,
      gameId: 'find_different',
      category: 'attention',
      level: 1,
      score: _score,
      accuracy: 90.0,
      attempts: 3,
      mistakes: 0,
      responseTimeMs: 1600,
      durationSeconds: 25,
      completed: true,
      offlineCreated: true,
    );
    await DatabaseHelper.instance.insertSession(session);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      appBar: AppBar(
        title: const Text('Find the Different Object', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Round $_round of ${_rounds.length}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF2563EB))),
                  Text('Score: $_score', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 20),

              if (!_finished) ...[
                const Text(
                  'Tap the single object that looks different from the others:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 24),

                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: _currentGrid.length,
                    itemBuilder: (context, index) {
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        elevation: 2,
                        child: InkWell(
                          onTap: () => _selectItem(index),
                          borderRadius: BorderRadius.circular(20),
                          child: Center(
                            child: Text(_currentGrid[index], style: const TextStyle(fontSize: 44)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🎯', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 8),
                          const Text('Eagle Eyes!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          Text('You scored $_score points!', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _round = 1;
                                _score = 0;
                                _finished = false;
                                _startRound();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Play Again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
