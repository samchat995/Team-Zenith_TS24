import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../database/database_helper.dart';
import '../../models/meaningful_activity_model.dart';

class MeaningfulActivitiesScreen extends StatefulWidget {
  const MeaningfulActivitiesScreen({super.key});

  @override
  State<MeaningfulActivitiesScreen> createState() => _MeaningfulActivitiesScreenState();
}

class _MeaningfulActivitiesScreenState extends State<MeaningfulActivitiesScreen> {
  MeaningfulActivityItem? _activeActivity;
  int _secondsPassed = 0;
  Timer? _timer;
  String _selectedEngagement = 'Great';

  final List<MeaningfulActivityItem> _activities = const [
    MeaningfulActivityItem(
      id: 'act_garden',
      type: 'gardening',
      titleKey: '🌱 Gardening',
      emoji: '🌱',
      descKey: 'Water flowers, touch soft leaves, and enjoy fresh natural breezes in the garden.',
      defaultMinutes: 15,
    ),
    MeaningfulActivityItem(
      id: 'act_paint',
      type: 'painting',
      titleKey: '🎨 Painting & Colors',
      emoji: '🎨',
      descKey: 'Express yourself through cheerful colors and gentle brushstrokes on paper.',
      defaultMinutes: 20,
    ),
    MeaningfulActivityItem(
      id: 'act_read',
      type: 'reading',
      titleKey: '📖 Reading',
      emoji: '📖',
      descKey: 'Enjoy pleasant short stories, poetry, or spiritual verses at a peaceful pace.',
      defaultMinutes: 15,
    ),
    MeaningfulActivityItem(
      id: 'act_music',
      type: 'music',
      titleKey: '🎵 Soothing Music',
      emoji: '🎵',
      descKey: 'Listen to familiar melodies, acoustic instruments, or sing along to classic songs.',
      defaultMinutes: 20,
    ),
    MeaningfulActivityItem(
      id: 'act_household',
      type: 'household',
      titleKey: '🏠 Household Activity',
      emoji: '🏠',
      descKey: 'Light relaxing tasks: folding soft napkins, arranging flowers, or organizing tea sets.',
      defaultMinutes: 10,
    ),
    MeaningfulActivityItem(
      id: 'act_family',
      type: 'family',
      titleKey: '👨‍👩‍👧 Family Time',
      emoji: '👨‍👩‍👧',
      descKey: 'Share a cup of tea, look through photo albums, and talk with children or companions.',
      defaultMinutes: 25,
    ),
    MeaningfulActivityItem(
      id: 'act_story',
      type: 'storytelling',
      titleKey: '📚 Storytelling',
      emoji: '📚',
      descKey: 'Recount a happy childhood story, favorite festival, or memorable life voyage.',
      defaultMinutes: 15,
    ),
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startActivity(MeaningfulActivityItem item) {
    setState(() {
      _activeActivity = item;
      _secondsPassed = 0;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _secondsPassed++;
      });
    });
  }

  void _finishActivity() async {
    _timer?.cancel();
    final item = _activeActivity!;
    final minutes = (_secondsPassed / 60).ceil();

    final log = ActivityLog(
      id: 'act_${DateTime.now().millisecondsSinceEpoch}',
      patientId: AuthService.instance.patientId ?? 'ifra_01',
      activityType: item.type,
      durationMinutes: minutes > 0 ? minutes : 1,
      engagement: _selectedEngagement,
      xpEarned: 20,
    );

    await DatabaseHelper.instance.logMeaningfulActivity(log);

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text(
                'Activity Completed!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Text(
                'You spent ${_secondsPassed ~/ 60}m ${_secondsPassed % 60}s enjoying this peaceful activity.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
                child: const Text('⭐ +20 XP Points Earned!', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF166534))),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _activeActivity = null;
                      _secondsPassed = 0;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back to Activities'),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_activeActivity != null) {
      final minutes = _secondsPassed ~/ 60;
      final seconds = _secondsPassed % 60;
      final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

      return Scaffold(
        backgroundColor: const Color(0xFFF0FDF4),
        appBar: AppBar(
          title: Text(_activeActivity!.titleKey, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_activeActivity!.emoji, style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 12),
                  Text(
                    _activeActivity!.titleKey,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _activeActivity!.descKey,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 24),

                  // Timer clock
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      timeStr,
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF166534), letterSpacing: 2),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Engagement rating selector
                  const Text('How are you enjoying this?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: ['Great', 'Good', 'Calm'].map((rate) {
                      final isSelected = _selectedEngagement == rate;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ChoiceChip(
                          label: Text(rate),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedEngagement = rate),
                          selectedColor: const Color(0xFF10B981),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF334155),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _finishActivity,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Complete Activity ✓', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Meaningful Activities', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            const Text(
              'Choose Something You Enjoy',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Gentle everyday pastimes that spark joy and bring purpose to your day.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),

            ..._activities.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFDCFCE7)),
                      ),
                      child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 28))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.titleKey,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.descKey,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => _startActivity(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Start', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
