import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/game_session_model.dart';
import '../../services/auth_service.dart';

class MissingObjectGame extends StatefulWidget {
  const MissingObjectGame({super.key});

  @override
  State<MissingObjectGame> createState() => _MissingObjectGameState();
}

class _MissingObjectGameState extends State<MissingObjectGame> {
  bool _showing = true;
  final List<String> _allFruits = ['🍎 Apple', '🍌 Banana', '🍊 Orange', '🍇 Grapes'];
  final List<String> _remaining = ['🍎 Apple', '🍊 Orange', '🍇 Grapes'];
  final String _missing = '🍌 Banana';
  int _score = 0;
  bool _finished = false;

  void _choose(String choice) {
    bool correct = choice == _missing;
    _score = correct ? 80 : 35;
    setState(() => _finished = true);
    _saveSession(correct);
  }

  Future<void> _saveSession(bool correct) async {
    final patientId = AuthService.instance.patientId ?? 'ifra_01';
    final session = GameSessionModel(
      patientId: patientId,
      gameId: 'missing_object',
      category: 'memory',
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
        title: const Text('Which One is Missing?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
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
                        const Text('🍌', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 8),
                        const Text('Missing Object Found!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
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
                        const Text('Memorize all 4 fruits carefully:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _allFruits.map((f) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                                child: Text(f, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                              )).toList(),
                        ),
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
                        const Text('One fruit was taken away! Remaining:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          children: _remaining.map((f) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                                child: Text(f, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                              )).toList(),
                        ),
                        const SizedBox(height: 32),
                        const Text('Which fruit is MISSING?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 20),
                        _buildChoice('🍌 Banana', true),
                        _buildChoice('🍎 Apple', false),
                        _buildChoice('🍇 Grapes', false),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildChoice(String fruit, bool isCorrect) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _choose(fruit),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F172A),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5)),
            elevation: 0,
          ),
          child: Text(fruit, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}
