import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/game_session_model.dart';
import '../../services/auth_service.dart';

class SoundMemoryGame extends StatefulWidget {
  const SoundMemoryGame({super.key});

  @override
  State<SoundMemoryGame> createState() => _SoundMemoryGameState();
}

class _SoundMemoryGameState extends State<SoundMemoryGame> {
  final List<Map<String, String>> _soundSequence = [
    {'name': 'Bell Chime', 'icon': '🔔'},
    {'name': 'Water Drop', 'icon': '💧'},
    {'name': 'Birdsong', 'icon': '🐦'},
  ];

  final List<String> _userTaps = [];
  bool _finished = false;
  int _score = 0;

  void _tapSound(String name) {
    if (_finished) return;
    setState(() => _userTaps.add(name));

    if (_userTaps.length == _soundSequence.length) {
      bool correct = true;
      for (int i = 0; i < _soundSequence.length; i++) {
        if (_userTaps[i] != _soundSequence[i]['name']) {
          correct = false;
          break;
        }
      }
      _score = correct ? 90 : 45;
      setState(() => _finished = true);
      _saveSession(correct);
    }
  }

  Future<void> _saveSession(bool correct) async {
    final patientId = AuthService.instance.patientId ?? 'ifra_01';
    final session = GameSessionModel(
      patientId: patientId,
      gameId: 'sound_memory',
      category: 'auditory',
      level: 1,
      score: _score,
      accuracy: correct ? 100.0 : 60.0,
      attempts: 1,
      mistakes: correct ? 0 : 1,
      responseTimeMs: 1900,
      durationSeconds: 20,
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
        title: const Text('Sound Sequence Memory', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
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
                        const Text('🎵', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 8),
                        const Text('Melody Recalled!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text('Score: $_score points', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {
                            _userTaps.clear();
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
                    const Text('Listen & recall the calm sound sequence:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),

                    // Target sequence
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFBFDBFE))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _soundSequence.map((s) {
                          return Column(
                            children: [
                              Text(s['icon']!, style: const TextStyle(fontSize: 36)),
                              const SizedBox(height: 4),
                              Text(s['name']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 28),

                    Text('Tap in order (${_userTaps.length} / ${_soundSequence.length}):', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                    const SizedBox(height: 16),

                    // Sound options
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSoundButton('Bell Chime', '🔔'),
                        _buildSoundButton('Water Drop', '💧'),
                        _buildSoundButton('Birdsong', '🐦'),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSoundButton(String name, String icon) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: InkWell(
        onTap: () => _tapSound(name),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 96,
          height: 100,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 6),
              Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            ],
          ),
        ),
      ),
    );
  }
}
