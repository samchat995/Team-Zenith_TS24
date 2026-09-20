import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/game_session_model.dart';
import '../../services/auth_service.dart';

class WordRecallGame extends StatefulWidget {
  const WordRecallGame({super.key});

  @override
  State<WordRecallGame> createState() => _WordRecallGameState();
}

class _WordRecallGameState extends State<WordRecallGame> {
  bool _showing = true;
  int _score = 0;
  bool _finished = false;

  final List<String> _words = ['APPLE', 'HOUSE', 'GARDEN', 'WATER'];

  void _choose(String word) {
    bool correct = _words.contains(word);
    _score = correct ? 80 : 30;
    setState(() => _finished = true);
    _saveSession(correct);
  }

  Future<void> _saveSession(bool correct) async {
    final patientId = AuthService.instance.patientId ?? 'ifra_01';
    final session = GameSessionModel(
      patientId: patientId,
      gameId: 'word_recall',
      category: 'language',
      level: 1,
      score: _score,
      accuracy: correct ? 100.0 : 50.0,
      attempts: 1,
      mistakes: correct ? 0 : 1,
      responseTimeMs: 1600,
      durationSeconds: 18,
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
        title: const Text('Word Recall', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
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
                        const Text('📝', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 8),
                        const Text('Word Recalled!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text('Score: $_score points', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {
                            _showing = true;
                            _finished = false;
                          }),
                          child: const Text('Play Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _showing
                  ? Column(
                      children: [
                        const Text('Memorize these 4 words:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 24),
                        ..._words.map((w) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              width: double.infinity,
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                              child: Center(child: Text(w, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)))),
                            )),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => setState(() => _showing = false),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(vertical: 14)),
                            child: const Text('READY →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        const Text('Which word was in the list?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 24),
                        _buildChoice('GARDEN', true),
                        _buildChoice('TRAIN', false),
                        _buildChoice('BICYCLE', false),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildChoice(String word, bool isCorrect) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _choose(word),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F172A),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5)),
            elevation: 0,
          ),
          child: Text(word, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}
