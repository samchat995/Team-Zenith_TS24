import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/game_session_model.dart';
import '../../services/auth_service.dart';

class RoutineOrderGame extends StatefulWidget {
  const RoutineOrderGame({super.key});

  @override
  State<RoutineOrderGame> createState() => _RoutineOrderGameState();
}

class _RoutineOrderGameState extends State<RoutineOrderGame> {
  final List<Map<String, String>> _correctOrder = [
    {'title': 'Wake Up', 'icon': '🌅'},
    {'title': 'Brush Teeth', 'icon': '🪥'},
    {'title': 'Morning Medicine', 'icon': '💊'},
    {'title': 'Warm Breakfast', 'icon': '🥣'},
    {'title': 'Garden Walk', 'icon': '🚶'},
  ];

  late List<Map<String, String>> _currentOrder;
  bool _checked = false;
  bool _isCorrect = false;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  void _startRound() {
    _currentOrder = List.from(_correctOrder)..shuffle();
    _checked = false;
    _isCorrect = false;
    _stopwatch.reset();
    _stopwatch.start();
  }

  void _moveUp(int index) {
    if (index > 0) {
      setState(() {
        final item = _currentOrder.removeAt(index);
        _currentOrder.insert(index - 1, item);
      });
    }
  }

  void _moveDown(int index) {
    if (index < _currentOrder.length - 1) {
      setState(() {
        final item = _currentOrder.removeAt(index);
        _currentOrder.insert(index + 1, item);
      });
    }
  }

  Future<void> _checkOrder() async {
    _stopwatch.stop();
    bool correct = true;
    for (int i = 0; i < _correctOrder.length; i++) {
      if (_currentOrder[i]['title'] != _correctOrder[i]['title']) {
        correct = false;
        break;
      }
    }

    setState(() {
      _checked = true;
      _isCorrect = correct;
    });

    final patientId = AuthService.instance.patientId ?? 'ifra_01';
    final accuracy = correct ? 100.0 : 60.0;
    final session = GameSessionModel(
      patientId: patientId,
      gameId: 'routine_order',
      category: 'routine',
      level: 1,
      score: correct ? 80 : 40,
      accuracy: accuracy,
      attempts: 1,
      mistakes: correct ? 0 : 2,
      responseTimeMs: _stopwatch.elapsedMilliseconds,
      durationSeconds: (_stopwatch.elapsedMilliseconds / 1000).ceil(),
      completed: true,
      offlineCreated: true,
    );
    await DatabaseHelper.instance.insertSession(session);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Daily Routine Order', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Arrange your daily morning activities in the right order.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Use the large Up / Down buttons to rearrange:',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView.separated(
                  itemCount: _currentOrder.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _currentOrder[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFEFF6FF),
                            ),
                            child: Center(
                              child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(item['icon']!, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item['title']!,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            ),
                          ),
                          // Large Accessible Up / Down Buttons
                          IconButton(
                            onPressed: index > 0 ? () => _moveUp(index) : null,
                            icon: const Icon(Icons.arrow_upward_rounded),
                            color: const Color(0xFF2563EB),
                          ),
                          IconButton(
                            onPressed: index < _currentOrder.length - 1 ? () => _moveDown(index) : null,
                            icon: const Icon(Icons.arrow_downward_rounded),
                            color: const Color(0xFF2563EB),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              if (_checked) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isCorrect ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Text(_isCorrect ? '🌟' : '💡', style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isCorrect
                              ? 'Wonderful! That is the natural morning sequence.'
                              : 'Good try! Wake Up -> Brush Teeth -> Medicine -> Breakfast -> Walk.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _isCorrect ? const Color(0xFF166534) : const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _checked ? _startRound : _checkOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    _checked ? 'Try Again' : 'CHECK MY ORDER →',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
