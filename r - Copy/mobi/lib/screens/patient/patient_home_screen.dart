import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/voice_service.dart';
import '../../database/database_helper.dart';
import '../reminders/reminder_screen.dart';
import '../mood/mood_screen.dart';
import '../memory/my_memory_screen.dart';
import '../voice/nia_assistant_screen.dart';
import '../assessment/onboarding_screen.dart';
import '../assessment/story_assessment_screen.dart';
import '../assessment/initial_10_question_assessment_screen.dart';
import '../activities/meaningful_activities_screen.dart';
import '../rewards/rewards_screen.dart';
import 'games_screen.dart';
import 'progress_screen.dart';
import 'caregiver_screen.dart';
import 'settings_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _currentTabIndex = 0;
  double _progressPercentage = 0.0;
  int _gamesCompleted = 0;
  final int _targetGames = 4;
  int _pendingReminders = 0;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
    VoiceService.instance.speakScreen('Home', 'Welcome to Neural Nexus.');
  }

  Future<void> _loadPatientData() async {
    final patientId = AuthService.instance.patientId ?? 'ifra_01';
    await DatabaseHelper.instance.loadRewards(patientId);
    final completedCount = await DatabaseHelper.instance.getCompletedGamesCount(patientId);
    final progress = await DatabaseHelper.instance.getDailyProgressPercentage(patientId, targetGames: _targetGames);
    final reminders = await DatabaseHelper.instance.getReminders(patientId);
    final pending = reminders.where((r) => !r.completed).length;

    if (mounted) {
      setState(() {
        _gamesCompleted = completedCount;
        _progressPercentage = progress;
        _pendingReminders = pending;
      });
    }
  }

  void _onLanguageSelected(String lang) {
    VoiceService.instance.speakTap(lang == 'hi' ? 'हिंदी' : (lang == 'as' ? 'অসমীয়া' : 'English'));
    AuthService.instance.switchLanguage(lang);
    setState(() {});
  }


  void _openNiaScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NiaAssistantScreen(
          pendingReminders: _pendingReminders,
          progress: _progressPercentage,
        ),
      ),
    );
  }

  void _showDailyRewardPopup() {
    final rewards = DatabaseHelper.instance.rewardsState;
    if (rewards.dailyRewardUnlockedToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AuthService.instance.language == 'hi'
                ? 'आज का रिवार्ड पहले ही अनलॉक हो चुका है!'
                : (AuthService.instance.language == 'as'
                    ? 'আজিৰ পুৰস্কাৰ ইতিমধ্যে লাভ কৰা হৈছে!'
                    : "Today's reward is already unlocked! Come back tomorrow."),
          ),
          backgroundColor: const Color(0xFF0F766E),
        ),
      );
      return;
    }

    final lang = AuthService.instance.language;
    final question = lang == 'hi'
        ? 'याददाश्त को खुश और तेज रखने का सबसे अच्छा तरीका क्या है?'
        : (lang == 'as'
            ? 'স্মৃতিশক্তি তীক্ষ্ণ আৰু ভাল ৰখাৰ উৎকৃষ্ট উপায় কি?'
            : 'What is a wonderful way to keep your memory sharp and happy?');
    final options = lang == 'hi'
        ? [
            'रोज़ाना आसान अभ्यास और अच्छी नींद',
            'चिंता और तनाव में रहना',
            'पानी न पीना और दिनभर कमरे में रहना',
          ]
        : (lang == 'as'
            ? [
                'দৈনিক সহজ অনুশীলন আৰু পৰ্যাপ্ত টোপনি',
                'চিন্তা আৰু অশান্তিত থকা',
                'পানী নোখোৱা আৰু বন্ধ কোঠাত থকা',
              ]
            : [
                'Daily gentle practice and restful sleep',
                'Staying stressed and worried',
                'Skipping water and staying inside all day',
              ]);

    int? selectedIndex;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: const [
              Text('🎉 ', style: TextStyle(fontSize: 26)),
              Expanded(
                child: Text(
                  'Daily Reward Challenge',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 16),
              ...List.generate(options.length, (idx) {
                final isSelected = selectedIndex == idx;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () => setDialogState(() => selectedIndex = idx),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFDCFCE7) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              options[idx],
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: const Color(0xFF0F172A),
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
              child: Text(context.tr('btn_cancel')),
            ),
            ElevatedButton(
              onPressed: selectedIndex == null
                  ? null
                  : () {
                      final isCorrect = selectedIndex == 0;
                      if (isCorrect) {
                        DatabaseHelper.instance.rewardsState.unlockDailyReward();
                        Navigator.pop(ctx);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("🎉 Correct! You unlocked +25 XP!"),
                            backgroundColor: Color(0xFF16A34A),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Nice try! Try once more to unlock your reward."),
                            backgroundColor: Color(0xFFD97706),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(context.tr('btn_confirm')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final patientName = auth.patientName;

    // 5 Working Tabs
    final List<Widget> screens = [
      _buildHomeContent(patientName),
      const GamesScreen(),
      const ProgressScreen(),
      const CaregiverScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      body: SafeArea(
        child: screens[_currentTabIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _currentTabIndex,
            onTap: (idx) => setState(() => _currentTabIndex = idx),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF0F766E),
            unselectedItemColor: const Color(0xFF64748B),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
            iconSize: 22,
            elevation: 0,
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.home_rounded), label: context.tr('nav_home')),
              BottomNavigationBarItem(icon: const Icon(Icons.sports_esports_rounded), label: context.tr('nav_games')),
              BottomNavigationBarItem(icon: const Icon(Icons.bar_chart_rounded), label: context.tr('nav_progress')),
              BottomNavigationBarItem(icon: const Icon(Icons.people_alt_rounded), label: context.tr('nav_caregiver')),
              BottomNavigationBarItem(icon: const Icon(Icons.settings_rounded), label: context.tr('nav_settings')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent(String patientName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOP HEADER (CLEAN NATURAL LOGO, TITLE, LANGUAGE SELECTOR, PATIENT BADGE)
          _buildHeader(patientName),
          const SizedBox(height: 14),

          // 2. GREETING & PROGRESS CARD
          _buildGreetingAndProgressCard(patientName),
          const SizedBox(height: 14),

          // 3. DAILY REWARD POPUP BANNER
          _buildDailyRewardBanner(),
          const SizedBox(height: 16),

          // 4. THE 8 CORE FEATURE TILES GRID (COGNITIVE GAMES, REWARDS, ASSESSMENT, ACTIVITIES, MEMORY, MOOD, REMINDERS, TALK TO NIA)
          _buildCoreFeaturesGrid(),
          const SizedBox(height: 18),

          // 5. DAY-1 ONBOARDING CARD: "GET TO KNOW YOU"
          _buildOnboardingCard(),
          const SizedBox(height: 14),

          // 6. 10-STORY MEMORY COGNITIVE ASSESSMENT CARD
          _buildStoryAssessmentCard(),
          const SizedBox(height: 14),

          // 7. MEANINGFUL ACTIVITIES CARD
          _buildMeaningfulActivitiesCard(),
          const SizedBox(height: 14),

          // 8. REWARDS & BADGES SUMMARY CARD
          _buildRewardsSummaryCard(),
          const SizedBox(height: 14),

          // 9. AI PERSONALIZATION & CONTINUOUS ADAPTATION LOOP
          _buildAIPersonalizationCard(),
          const SizedBox(height: 14),

          // 10. TALK TO NIA ASSISTANT CARD
          _buildNiaAssistantBanner(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 1. TOP HEADER (NATURAL UNMASKED LOGO + TRILINGUAL SWITCHER + PROFILE)
  Widget _buildHeader(String patientName) {
    final currentLang = AuthService.instance.language;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Brand & Subtitle with uncropped logo
        Expanded(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/neural_nexus_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.favorite, color: Color(0xFF0D9488)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'NEURAL NEXUS',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                        color: Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      context.tr('app_subtitle'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F766E),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 6),

        // Trilingual switcher pills
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLangPill('EN', 'en', currentLang == 'en'),
              _buildLangPill('हिं', 'hi', currentLang == 'hi'),
              _buildLangPill('অস', 'as', currentLang == 'as'),
            ],
          ),
        ),

        const SizedBox(width: 6),

        // Profile Avatar
        InkWell(
          onTap: () {
            VoiceService.instance.speakTap('Profile');
            setState(() => _currentTabIndex = 4);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildLangPill(String label, String code, bool isSelected) {
    return InkWell(
      onTap: () => _onLanguageSelected(code),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // 2. GREETING & PROGRESS CARD
  Widget _buildGreetingAndProgressCard(String patientName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF115E59)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hello, $patientName 👋',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle_outline, color: Color(0xFF6EE7B7), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Day 4',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('bubble_quote'),
            style: const TextStyle(fontSize: 13, color: Color(0xFFCCFBF1), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 14),

          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('todays_progress'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              Text(
                '${_progressPercentage.toInt()}%',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF6EE7B7)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _progressPercentage / 100.0,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$_gamesCompleted of $_targetGames ${context.tr('games_completed')}',
            style: const TextStyle(fontSize: 12, color: Color(0xFFCCFBF1), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // 3. DAILY REWARD BANNER
  Widget _buildDailyRewardBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('🎉', style: TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('daily_reward_title'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                ),
                Text(
                  context.tr('daily_reward_desc'),
                  style: const TextStyle(fontSize: 12, color: Color(0xFFB45309), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _showDailyRewardPopup,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              context.tr('daily_reward_btn'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  // 4. THE 8 CORE FEATURE TILES GRID
  Widget _buildCoreFeaturesGrid() {
    final List<Map<String, dynamic>> items = [
      {
        'title': context.tr('card_games'),
        'sub': context.tr('card_games_sub'),
        'icon': '🧠',
        'color': const Color(0xFFEFF6FF),
        'borderColor': const Color(0xFFBFDBFE),
        'textColor': const Color(0xFF1D4ED8),
        'onTap': () => setState(() => _currentTabIndex = 1),
      },
      {
        'title': context.tr('card_rewards'),
        'sub': context.tr('card_rewards_sub'),
        'icon': '🎁',
        'color': const Color(0xFFFEF3C7),
        'borderColor': const Color(0xFFFDE68A),
        'textColor': const Color(0xFFB45309),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsScreen())),
      },
      {
        'title': context.tr('card_assessment'),
        'sub': context.tr('card_assessment_sub'),
        'icon': '📝',
        'color': const Color(0xFFF3E8FF),
        'borderColor': const Color(0xFFE9D5FF),
        'textColor': const Color(0xFF7E22CE),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoryAssessmentScreen())),
      },
      {
        'title': context.tr('card_activities'),
        'sub': context.tr('card_activities_sub'),
        'icon': '🌱',
        'color': const Color(0xFFDCFCE7),
        'borderColor': const Color(0xFFBBF7D0),
        'textColor': const Color(0xFF15803D),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MeaningfulActivitiesScreen())),
      },
      {
        'title': context.tr('card_memory'),
        'sub': context.tr('card_memory_sub'),
        'icon': '💭',
        'color': const Color(0xFFFCE7F3),
        'borderColor': const Color(0xFFFBCFE8),
        'textColor': const Color(0xFFBE185D),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyMemoryScreen())),
      },
      {
        'title': context.tr('card_mood'),
        'sub': context.tr('card_mood_sub'),
        'icon': '😊',
        'color': const Color(0xFFE0F2FE),
        'borderColor': const Color(0xFFBAE6FD),
        'textColor': const Color(0xFF0369A1),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MoodScreen())),
      },
      {
        'title': context.tr('card_reminders'),
        'sub': context.tr('card_reminders_sub'),
        'icon': '⏰',
        'color': const Color(0xFFFFF7ED),
        'borderColor': const Color(0xFFFED7AA),
        'textColor': const Color(0xFFC2410C),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderScreen())),
      },
      {
        'title': context.tr('card_nia'),
        'sub': context.tr('card_nia_sub'),
        'icon': '🤖',
        'color': const Color(0xFFCCFBF1),
        'borderColor': const Color(0xFF99F6E4),
        'textColor': const Color(0xFF0F766E),
        'onTap': _openNiaScreen,
      },
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final it = items[index];
        return InkWell(
          onTap: it['onTap'] as VoidCallback,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: it['color'] as Color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: it['borderColor'] as Color, width: 1.5),
            ),
            child: Row(
              children: [
                Text(it['icon'] as String, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        it['title'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: it['textColor'] as Color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        it['sub'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 5. DAY-1 ONBOARDING CARD: "GET TO KNOW YOU"
  Widget _buildOnboardingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('📝', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('onboarding_card_title'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      'Day-1 Personal Questionnaire',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            context.tr('onboarding_card_desc'),
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w500, height: 1.3),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OnboardingScreen())),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(context.tr('onboarding_card_btn')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4338CA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 6. 10-STORY MEMORY COGNITIVE ASSESSMENT CARD
  Widget _buildStoryAssessmentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('🧠', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('assessment_card_title'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      '10 Stories • Audio & YES/NO',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF7E22CE)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            context.tr('assessment_card_desc'),
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w500, height: 1.3),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                VoiceService.instance.speakTap('Open 10 Questions Assessment');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Initial10QuestionAssessmentScreen(isRetake: true)),
                ).then((_) => _loadPatientData());
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(context.tr('assessment_card_btn')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7E22CE),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 7. MEANINGFUL ACTIVITIES CARD
  Widget _buildMeaningfulActivitiesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('🌱', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('activities_card_title'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      'Gardening, Painting, Music, Family Time',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            context.tr('activities_card_desc'),
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w500, height: 1.3),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MeaningfulActivitiesScreen())),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(context.tr('activities_card_btn')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF15803D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 8. REWARDS & BADGES SUMMARY CARD
  Widget _buildRewardsSummaryCard() {
    final rewards = DatabaseHelper.instance.rewardsState;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🎁 ', style: TextStyle(fontSize: 22)),
                  Text(
                    context.tr('rewards_card_title'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsScreen())),
                child: Text(
                  context.tr('view_all'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F766E)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stat Pills: XP, Level, Streak
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 2),
                      Text(
                        '${rewards.xp} XP',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                      ),
                      const Text(
                        'Points',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 2),
                      Text(
                        'Level ${rewards.gamificationLevel}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8)),
                      ),
                      const Text(
                        'Gamification',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Column(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 2),
                      Text(
                        '${rewards.streakDays} Days',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
                      ),
                      const Text(
                        'Streak',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF991B1B)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Badges preview row
          Row(
            children: const [
              Text('🏅 First Game', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
              SizedBox(width: 10),
              Text('🧠 Memory Explorer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
              SizedBox(width: 10),
              Text('🌱 Activity Hero', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            ],
          ),
        ],
      ),
    );
  }

  // 9. AI PERSONALIZATION & CONTINUOUS ADAPTIVE LOOP
  Widget _buildAIPersonalizationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(child: Text('🤖', style: TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr('ai_personalized_title'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('ai_personalized_desc'),
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),

          // Recommendations
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('ai_recommended'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F766E)),
                ),
                const SizedBox(height: 6),
                _buildRecItem('🧠', context.tr('ai_rec_1')),
                _buildRecItem('🌱', context.tr('ai_rec_2')),
                _buildRecItem('📖', context.tr('ai_rec_3')),
                const Divider(height: 16),
                Text(
                  context.tr('ai_why'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 4),
                _buildWhyItem('✓ ${context.tr('ai_reason_1')}'),
                _buildWhyItem('✓ ${context.tr('ai_reason_2')}'),
                _buildWhyItem('✓ ${context.tr('ai_reason_3')}'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Visual Continuous Adaptation Loop
          Text(
            context.tr('ai_pipeline_title'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Patient ➔ Games & Activities ➔ Performance Data ➔ AI Analysis ➔ Recommendations ➔ Caregiver Review ➔ Personalized Plan',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F766E), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildWhyItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
    );
  }

  // 10. TALK TO NIA ASSISTANT CARD
  Widget _buildNiaAssistantBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('talk_to_nia'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Your personal memory companion',
                  style: TextStyle(fontSize: 12, color: Color(0xFFE0F2FE), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _openNiaScreen,
            icon: const Icon(Icons.mic, size: 16),
            label: Text(context.tr('talk_to_nia')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0369A1),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
