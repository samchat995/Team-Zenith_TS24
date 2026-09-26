import 'dart:async';
import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../database/database_helper.dart';
import '../../models/game_session_model.dart';
import '../../services/auth_service.dart';

class RememberObjectsGame extends StatefulWidget {
  const RememberObjectsGame({super.key});

  @override
  State<RememberObjectsGame> createState() => _RememberObjectsGameState();
}

class _RememberObjectsGameState extends State<RememberObjectsGame> {
  int _level = 2; // Level 1=3 items, Level 2=4 items, Level 3=5 items
  bool _showingObjects = true;
  int _secondsLeft = 6;
  Timer? _timer;

  final List<Map<String, String>> _allPool = [
    {'name': 'Apple', 'emoji': '🍎'},
    {'name': 'Teacup', 'emoji': '☕'},
    {'name': 'Glasses', 'emoji': '👓'},
    {'name': 'Clock', 'emoji': '🕰️'},
    {'name': 'Flower', 'emoji': '🌸'},
    {'name': 'Book', 'emoji': '📖'},
    {'name': 'Key', 'emoji': '🔑'},
    {'name': 'Water', 'emoji': '🥛'},
  ];

  late List<Map<String, String>> _targetObjects;
  late List<Map<String, String>> _choiceOptions;
  final Set<String> _selectedItems = {};
  int _score = 0;
  int _mistakes = 0;
  bool _gameOver = false;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  void _startRound() {
    _showingObjects = true;
    _secondsLeft = 6;
    _selectedItems.clear();
    _gameOver = false;
    _mistakes = 0;

    final count = _level == 1 ? 3 : (_level == 2 ? 4 : 5);
    final shuffled = List<Map<String, String>>.from(_allPool)..shuffle();
    _targetObjects = shuffled.take(count).toList();

    // Prepare 6 choices
    _choiceOptions = List<Map<String, String>>.from(shuffled.take(6))..shuffle();

    _stopwatch.reset();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        t.cancel();
        setState(() {
          _showingObjects = false;
          _stopwatch.start();
        });
      }
    });
  }

  void _toggleChoice(String name) {
    if (_gameOver) return;

    setState(() {
      if (_selectedItems.contains(name)) {
        _selectedItems.remove(name);
      } else {
        _selectedItems.add(name);
      }
    });

    final targetNames = _targetObjects.map((o) => o['name']).toSet();
    if (_selectedItems.length == _targetObjects.length) {
      _stopwatch.stop();
      int correct = _selectedItems.intersection(targetNames).length;
      int wrong = _selectedItems.difference(targetNames).length;
      _mistakes = wrong;
      double accuracy = (correct / _targetObjects.length) * 100.0;
      int roundScore = (correct * 25) - (wrong * 10);
      _score = roundScore > 0 ? roundScore : 10;
      _gameOver = true;

      _saveSession(accuracy, _stopwatch.elapsedMilliseconds);
    }
  }

  Future<void> _saveSession(double accuracy, int reactionMs) async {
    final patientId = AuthService.instance.patientId ?? 'ifra_01';
    final session = GameSessionModel(
      patientId: patientId,
      gameId: 'remember_objects',
      category: 'memory',
      level: _level,
      score: _score,
      accuracy: accuracy,
      attempts: 1,
      mistakes: _mistakes,
      responseTimeMs: reactionMs,
      durationSeconds: (_stopwatch.elapsedMilliseconds / 1000).ceil() + 6,
      completed: true,
      offlineCreated: true,
    );
    await DatabaseHelper.instance.insertSession(session);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        title: Text(context.tr('game_remember_objects_title'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
                    child: Text('${context.tr('level_label')} $_level', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF166534))),
                  ),
                  if (_showingObjects)
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Color(0xFFD97706), size: 18),
                        const SizedBox(width: 4),
                        Text('Memorize: $_secondsLeft s', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFD97706), fontSize: 15)),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 20),

              if (_showingObjects) ...[
                Text(
                  context.tr('game_remember_objects_inst'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: _targetObjects.map((obj) {
                    return Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBBF7D0), width: 2),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(obj['emoji']!, style: const TextStyle(fontSize: 34)),
                          const SizedBox(height: 4),
                          Text(obj['name']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ] else if (!_gameOver) ...[
                Text(
                  'Which ${_targetObjects.length} objects did you see?\nTap them below:',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  alignment: WrapAlignment.center,
                  children: _choiceOptions.map((obj) {
                    final isSelected = _selectedItems.contains(obj['name']);
                    return InkWell(
                      onTap: () => _toggleChoice(obj['name']!),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFDBEAFE) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0), width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(obj['emoji']!, style: const TextStyle(fontSize: 36)),
                            const SizedBox(height: 4),
                            Text(obj['name']!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isSelected ? const Color(0xFF1E40AF) : const Color(0xFF334155))),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ] else ...[
                // Game Over Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    children: [
                      const Text('🌟', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 8),
                      Text(context.tr('dialog_activity_complete'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      const SizedBox(height: 6),
                      Text('${context.tr('score_label')}: $_score', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                      const SizedBox(height: 12),
                      Text(
                        context.tr('feedback_good_effort'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _startRound,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(context.tr('btn_play_again'), style: const TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(context.tr('btn_return_home')),
                            ),
                          ),
                        ],
                      ),
                    ],
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
