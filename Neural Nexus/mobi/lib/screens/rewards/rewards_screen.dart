import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/rewards_model.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final List<BadgeItem> _allBadges = const [
    BadgeItem(
      id: 'first_game',
      titleKey: 'First Game',
      descKey: 'Played your very first cognitive exercise',
      icon: '🏅',
    ),
    BadgeItem(
      id: 'memory_explorer',
      titleKey: 'Memory Explorer',
      descKey: 'Matched 10+ memory card pairs successfully',
      icon: '🧠',
    ),
    BadgeItem(
      id: 'activity_explorer',
      titleKey: 'Activity Explorer',
      descKey: 'Completed meaningful daily activities',
      icon: '🌱',
    ),
    BadgeItem(
      id: 'daily_streak',
      titleKey: 'Consistent Rhythm',
      descKey: 'Maintained a 4-day learning streak',
      icon: '🔥',
    ),
    BadgeItem(
      id: 'heart_champion',
      titleKey: 'Mindful Spirit',
      descKey: 'Checked in on well-being for 3 consecutive days',
      icon: '❤️',
    ),
  ];

  void _showDailyRewardDialog() {
    final rewards = DatabaseHelper.instance.rewardsState;
    if (rewards.dailyRewardUnlockedToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Today's reward is already unlocked! Come back tomorrow.")),
      );
      return;
    }

    int? selectedIndex;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: const [
              Text('🎉', style: TextStyle(fontSize: 28)),
              SizedBox(width: 8),
              Text('Daily Reward!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Answer 1 quick question to unlock today’s 25 XP reward:',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              const Text(
                'What is a wonderful way to keep your memory sharp and happy?',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              ...[
                'Daily gentle practice and restful sleep',
                'Staying stressed and worried',
                'Skipping water and staying inside all day',
              ].asMap().entries.map((e) {
                final isSelected = selectedIndex == e.key;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => setDialogState(() => selectedIndex = e.key),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              e.value,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Not Now', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: selectedIndex == 0
                  ? () {
                      Navigator.pop(ctx);
                      rewards.unlockDailyReward();
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('🎉 Awesome! +25 XP Added to your Rewards!')),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Claim 25 XP ⭐', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rewards = DatabaseHelper.instance.rewardsState;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Rewards', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Top Stats Banner (XP, Level, Streak)
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0284C7)]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF0D9488).withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('⭐', style: TextStyle(fontSize: 28)),
                          const SizedBox(height: 4),
                          Text('${rewards.xp} XP', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                          const SizedBox(height: 2),
                          const Text('Points Earned', style: TextStyle(fontSize: 11, color: Color(0xFFCCFBF1), fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Container(height: 50, width: 1, color: Colors.white24),
                      Column(
                        children: [
                          const Text('🏆', style: TextStyle(fontSize: 28)),
                          const SizedBox(height: 4),
                          Text('Level ${rewards.gamificationLevel}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                          const SizedBox(height: 2),
                          const Text('Gamification Rank', style: TextStyle(fontSize: 11, color: Color(0xFFCCFBF1), fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Container(height: 50, width: 1, color: Colors.white24),
                      Column(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 28)),
                          const SizedBox(height: 4),
                          Text('${rewards.streakDays} Days', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                          const SizedBox(height: 2),
                          const Text('Daily Streak', style: TextStyle(fontSize: 11, color: Color(0xFFCCFBF1), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Daily Reward Action Card
            InkWell(
              onTap: _showDailyRewardDialog,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('🎁', style: TextStyle(fontSize: 36)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Daily Reward Challenge',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rewards.dailyRewardUnlockedToday
                                ? '✓ Today’s reward claimed! Come back tomorrow.'
                                : 'Answer 1 quick question to unlock +25 XP today.',
                            style: const TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: rewards.dailyRewardUnlockedToday ? const Color(0xFFFDE68A) : const Color(0xFFD97706),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        rewards.dailyRewardUnlockedToday ? 'Done' : 'Unlock',
                        style: TextStyle(
                          color: rewards.dailyRewardUnlockedToday ? const Color(0xFF92400E) : Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Badges Section
            const Text(
              'Your Achievements & Badges',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _allBadges.length,
              itemBuilder: (context, idx) {
                final b = _allBadges[idx];
                final isUnlocked = rewards.unlockedBadgeIds.contains(b.id);
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUnlocked ? Colors.white : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isUnlocked ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(b.icon, style: const TextStyle(fontSize: 28)),
                          if (isUnlocked)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                              child: const Text('✓ UNLOCKED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF166534))),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        b.titleKey,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isUnlocked ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        b.descKey,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: isUnlocked ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
