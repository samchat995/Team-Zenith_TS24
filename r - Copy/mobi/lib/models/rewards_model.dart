class RewardsState {
  int xp;
  int gamificationLevel;
  int streakDays;
  List<String> unlockedBadgeIds;
  bool dailyRewardUnlockedToday;
  DateTime lastRewardDate;

  RewardsState({
    this.xp = 240,
    this.gamificationLevel = 3,
    this.streakDays = 4,
    List<String>? unlockedBadgeIds,
    this.dailyRewardUnlockedToday = false,
    DateTime? lastRewardDate,
  })  : unlockedBadgeIds = unlockedBadgeIds ?? ['first_game', 'memory_explorer', 'activity_explorer'],
        lastRewardDate = lastRewardDate ?? DateTime.now();

  void addXp(int amount) {
    xp += amount;
    // Level up every 100 XP
    gamificationLevel = (xp / 100).floor() + 1;
  }

  void unlockDailyReward() {
    dailyRewardUnlockedToday = true;
    addXp(25);
    lastRewardDate = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
    'xp': xp,
    'gamification_level': gamificationLevel,
    'streak_days': streakDays,
    'unlocked_badge_ids': unlockedBadgeIds,
    'daily_reward_unlocked_today': dailyRewardUnlockedToday,
    'last_reward_date': lastRewardDate.toIso8601String(),
  };
}

class BadgeItem {
  final String id;
  final String titleKey;
  final String descKey;
  final String icon;

  const BadgeItem({
    required this.id,
    required this.titleKey,
    required this.descKey,
    required this.icon,
  });
}
