import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/game_session_model.dart';
import '../../services/auth_service.dart';

class SequenceRecallGame extends StatefulWidget {
  const SequenceRecallGame({super.key});

  @override
  State<SequenceRecallGame> createState() => _SequenceRecallGameState();
}

class _SequenceRecallGameState extends State<SequenceRecallGame> {
  bool _showing = true;
  final List<String> _target = ['🍎', '🥛', '🍞'];
  final List<String> _userOrder = [];
  bool _finished = false;
  int _score = 0;

  void _tapItem(String item) {
    if (_finished) return;
    setState(() => _userOrder.add(item));

    if (_userOrder.length == _target.length) {
      bool correct = true;
      for (int i = 0; i < _target.length; i++) {
        if (_userOrder[i] != _target[i]) {
          correct = false;
          break;
        }
      }
      _score = correct ? 85 : 40;
      setState(() => _finished = true);
      _saveSession(correct);
    }
  }

  Future<void> _saveSession(bool correct) async {
    final patientId = AuthService.instance.patientId ?? 'ifra_01';
    final session = GameSessionModel(
      patientId: patientId,
      gameId: 'sequence_recall',
      category: 'memory',
      level: 1,
      score: _score,
      accuracy: correct ? 100.0 : 60.0,
      attempts: 1,
      mistakes: correct ? 0 : 1,
      responseTimeMs: 1500,
      durationSeconds: 16,
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
        title: const Text('Simple Sequence Recall', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
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
                        const Text('🍎🥛🍞', style: TextStyle(fontSize: 36)),
                        const SizedBox(height: 8),
                        const Text('Sequence Recalled!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text('Score: $_score points', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {
                            _showing = true;
                            _userOrder.clear();
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
                        const Text('Remember the sequence of these 3 items:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: _target.map((e) => Text(e, style: const TextStyle(fontSize: 48))).toList(),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => setState(() => _showing = false),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(vertical: 14)),
                            child: const Text('I GOT IT →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        const Text('Tap the items in the same sequence you saw:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _userOrder.map((e) => Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text(e, style: const TextStyle(fontSize: 36)))).toList(),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: ['🍞', '🍎', '🥛'].map((item) {
                            return Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              elevation: 2,
                              child: InkWell(
                                onTap: () => _tapItem(item),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 86,
                                  height: 86,
                                  alignment: Alignment.center,
                                  child: Text(item, style: const TextStyle(fontSize: 42)),
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
