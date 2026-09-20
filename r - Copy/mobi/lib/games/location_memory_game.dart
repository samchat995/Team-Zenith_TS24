import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/game_session_model.dart';
import '../../services/auth_service.dart';

class LocationMemoryGame extends StatefulWidget {
  const LocationMemoryGame({super.key});

  @override
  State<LocationMemoryGame> createState() => _LocationMemoryGameState();
}

class _LocationMemoryGameState extends State<LocationMemoryGame> {
  bool _showing = true;
  int _score = 0;
  bool _finished = false;

  final List<Map<String, String>> _locations = [
    {'item': '🔑 House Keys', 'place': 'In the Wooden Drawer'},
    {'item': '☕ Tea Mug', 'place': 'On the Living Table'},
    {'item': '💊 Medicine Box', 'place': 'Inside the Cabinet'},
  ];

  void _answer(bool correct) {
    if (correct) _score = 80;
    setState(() => _finished = true);
    _saveSession();
  }

  Future<void> _saveSession() async {
    final patientId = AuthService.instance.patientId ?? 'ifra_01';
    final session = GameSessionModel(
      patientId: patientId,
      gameId: 'location_memory',
      category: 'memory',
      level: 1,
      score: _score,
      accuracy: 85.0,
      attempts: 1,
      mistakes: 0,
      responseTimeMs: 1800,
      durationSeconds: 22,
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
        title: const Text('Location Memory', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
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
                        const Text('🔑', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 8),
                        const Text('Found It!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
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
                        const Text('Memorize where each item is kept at home:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 20),
                        ..._locations.map((loc) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                            child: Row(
                              children: [
                                Text(loc['item']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                const Spacer(),
                                Text(loc['place']!, style: const TextStyle(fontSize: 14, color: Color(0xFF2563EB), fontWeight: FontWeight.w700)),
                              ],
                            ),
                          );
                        }).toList(),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => setState(() => _showing = false),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(vertical: 14)),
                            child: const Text('I REMEMBERED →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        const SizedBox(height: 20),
                        const Text('Where were the House Keys kept?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 28),
                        _buildChoice('In the Wooden Drawer', true),
                        _buildChoice('On the Living Table', false),
                        _buildChoice('Inside the Cabinet', false),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildChoice(String text, bool correct) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _answer(correct),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F172A),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5)),
            elevation: 0,
          ),
          child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
