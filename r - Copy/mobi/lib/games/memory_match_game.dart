import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../database/database_helper.dart';
import '../../models/game_session_model.dart';
import '../../services/auth_service.dart';

class MemoryMatchGame extends StatefulWidget {
  const MemoryMatchGame({super.key});

  @override
  State<MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends State<MemoryMatchGame> {
  int _level = 1; // Level 1=3 pairs, Level 2=4 pairs, Level 3=6 pairs
  late List<_CardItem> _cards;
  int? _firstFlippedIndex;
  bool _busy = false;
  int _matchesFound = 0;
  int _attempts = 0;
  int _mistakes = 0;
  bool _gameOver = false;
  final Stopwatch _stopwatch = Stopwatch();

  final List<String> _emojis = ['🍎', '☕', '👓', '🕰️', '🌸', '📖', '🔑', '🥛'];

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    final pairCount = _level == 1 ? 3 : (_level == 2 ? 4 : 6);
    final chosenEmojis = _emojis.take(pairCount).toList();
    final cardValues = [...chosenEmojis, ...chosenEmojis]..shuffle();

    _cards = cardValues.asMap().entries.map((e) => _CardItem(id: e.key, value: e.value)).toList();
    _firstFlippedIndex = null;
    _busy = false;
    _matchesFound = 0;
    _attempts = 0;
    _mistakes = 0;
    _gameOver = false;
    _stopwatch.reset();
    _stopwatch.start();
  }

  void _onCardTap(int index) {
    if (_busy || _cards[index].isFlipped || _cards[index].isMatched) return;

    setState(() => _cards[index].isFlipped = true);

    if (_firstFlippedIndex == null) {
      _firstFlippedIndex = index;
    } else {
      _attempts++;
      final first = _cards[_firstFlippedIndex!];
      final second = _cards[index];

      if (first.value == second.value) {
        setState(() {
          first.isMatched = true;
          second.isMatched = true;
          _matchesFound++;
          _firstFlippedIndex = null;
        });

        final targetPairs = _level == 1 ? 3 : (_level == 2 ? 4 : 6);
        if (_matchesFound == targetPairs) {
          _stopwatch.stop();
          setState(() => _gameOver = true);
          _saveSession();
        }
      } else {
        _mistakes++;
        _busy = true;
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) {
            setState(() {
              first.isFlipped = false;
              second.isFlipped = false;
              _firstFlippedIndex = null;
              _busy = false;
            });
          }
        });
      }
    }
  }

  Future<void> _saveSession() async {
    final patientId = AuthService.instance.patientId ?? 'ifra_01';
    final targetPairs = _level == 1 ? 3 : (_level == 2 ? 4 : 6);
    final double accuracy = (_attempts > 0) ? (targetPairs / _attempts) * 100.0 : 100.0;
    final score = (targetPairs * 30) - (_mistakes * 5);

    final session = GameSessionModel(
      patientId: patientId,
      gameId: 'memory_match',
      category: 'memory',
      level: _level,
      score: score > 10 ? score : 15,
      accuracy: accuracy.clamp(10.0, 100.0),
      attempts: _attempts,
      mistakes: _mistakes,
      responseTimeMs: (_stopwatch.elapsedMilliseconds / (_attempts > 0 ? _attempts : 1)).round(),
      durationSeconds: (_stopwatch.elapsedMilliseconds / 1000).ceil(),
      completed: true,
      offlineCreated: true,
    );
    await DatabaseHelper.instance.insertSession(session);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF2F8),
      appBar: AppBar(
        title: Text(context.tr('game_memory_match_title'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFFCE7F3), borderRadius: BorderRadius.circular(10)),
                    child: Text('${context.tr('level_label')} $_level', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFBE185D))),
                  ),
                  Text('Pairs: $_matchesFound / ${_level == 1 ? 3 : (_level == 2 ? 4 : 6)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 16),

              if (!_gameOver)
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _level == 3 ? 3 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: _cards.length,
                    itemBuilder: (context, index) {
                      final c = _cards[index];
                      return GestureDetector(
                        onTap: () => _onCardTap(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          decoration: BoxDecoration(
                            color: c.isMatched
                                ? const Color(0xFFDCFCE7)
                                : (c.isFlipped ? Colors.white : const Color(0xFF2563EB)),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
                            ],
                          ),
                          child: Center(
                            child: c.isFlipped || c.isMatched
                                ? Text(c.value, style: const TextStyle(fontSize: 40))
                                : const Icon(Icons.touch_app_rounded, color: Colors.white70, size: 36),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🎉', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 8),
                          Text(context.tr('dialog_congrats'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          Text(context.tr('feedback_excellent'), textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => setState(() => _initGame()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(context.tr('btn_play_again')),
                          ),
                        ],
                      ),
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

class _CardItem {
  final int id;
  final String value;
  bool isFlipped;
  bool isMatched;

  _CardItem({required this.id, required this.value})
      : isFlipped = false,
        isMatched = false;
}
