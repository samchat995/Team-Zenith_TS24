import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../database/database_helper.dart';
import '../../models/mood_model.dart';
import '../../games/remember_objects_game.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  String? _selectedMood;
  bool _submitted = false;

  final List<Map<String, String>> _moods = [
    {'key': 'mood_happy', 'label': 'Happy', 'emoji': '😊', 'desc': 'Joyful & bright'},
    {'key': 'mood_calm', 'label': 'Calm', 'emoji': '🙂', 'desc': 'Peaceful & relaxed'},
    {'key': 'mood_okay', 'label': 'Okay', 'emoji': '😐', 'desc': 'Steady & quiet'},
    {'key': 'mood_tired', 'label': 'Tired', 'emoji': '😴', 'desc': 'Need a short rest'},
    {'key': 'mood_worried', 'label': 'Worried', 'emoji': '😟', 'desc': 'A little anxious'},
  ];

  Future<void> _submitMood(String mood) async {
    setState(() {
      _selectedMood = mood;
      _submitted = true;
    });

    final patientId = AuthService.instance.patientId ?? 'ifra_01';
    await DatabaseHelper.instance.insertMood(
      MoodModel(patientId: patientId, mood: mood, loggedAt: DateTime.now()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        title: Text(context.tr('mood_title'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Text(
                context.tr('mood_subtitle'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('mood_prompt'),
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // 5 Large Mood Cards
              Expanded(
                child: ListView.separated(
                  itemCount: _moods.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final m = _moods[index];
                    final isSelected = _selectedMood == m['label'];
                    final label = context.tr(m['key']!);

                    return Material(
                      color: isSelected ? const Color(0xFFDCFCE7) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      elevation: 1,
                      child: InkWell(
                        onTap: () => _submitMood(m['label']!),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Row(
                            children: [
                              Text(m['emoji']!, style: const TextStyle(fontSize: 36)),
                              const SizedBox(width: 18),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    m['desc']!,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 26),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              if (_submitted) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${context.tr('mood_saved_success')} 🌸\n${context.tr('play_a_game')}?',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF14532D)),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RememberObjectsGame()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(context.tr('btn_confirm'), style: const TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF475569),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(context.tr('btn_cancel'), style: const TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
