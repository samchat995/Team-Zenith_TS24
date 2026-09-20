import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/voice_service.dart';
import '../../database/database_helper.dart';
import '../../models/onboarding_model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentIndex = 0;
  String? _selectedOption;
  bool _isCompleted = false;

  final List<OnboardingQuestion> _questions = const [
    OnboardingQuestion(
      id: 1,
      category: 'routine',
      questionEn: 'What is your favorite time of the day?',
      questionHi: 'दिन का कौन सा समय आपको सबसे अच्छा लगता है?',
      questionAs: 'দিনটোৰ কোনটো সময় আপোনাৰ আটাইতকৈ ভাল লাগে?',
      optionsEn: ['Morning sunshine', 'Quiet afternoon', 'Gentle evening', 'Starry night'],
      optionsHi: ['सुबह की धूप', 'शांत दोपहर', 'सुहावनी शाम', 'तारों भरी रात'],
      optionsAs: ['পুৱাৰ ৰʼদ', 'শান্ত দুপৰীয়া', 'মনোৰম গধূলি', 'তৰাভৰা ৰাতি'],
    ),
    OnboardingQuestion(
      id: 2,
      category: 'activity',
      questionEn: 'What kind of activity brings you the most joy?',
      questionHi: 'किस गतिविधि से आपको सबसे अधिक प्रसन्नता मिलती है?',
      questionAs: 'কোনটো কাম কৰি আপুনি আটাইতকৈ বেছি আনন্দ পায়?',
      optionsEn: ['Walking in the garden', 'Listening to music', 'Reading stories', 'Chatting with family'],
      optionsHi: ['बगीचे में टहलना', 'मधुर संगीत सुनना', 'कहानियां पढ़ना', 'परिवार से बातें करना'],
      optionsAs: ['ফুলনিত খোজ কঢ়া', 'গান শুনা', 'সাধু পঢ়া', 'পৰিয়ালৰ লগত কথা পতা'],
    ),
    OnboardingQuestion(
      id: 3,
      category: 'comfort',
      questionEn: 'Which comforting warm drink do you enjoy most?',
      questionHi: 'आपको कौन सा गर्म पेय सबसे अधिक पसंद है?',
      questionAs: 'কোনটো গৰম পানীয় আপোনাৰ আটাইতকৈ প্ৰিয়?',
      optionsEn: ['Cardamom tea', 'Warm milk', 'Herbal water', 'Fresh ginger tea'],
      optionsHi: ['इलायची वाली चाय', 'हल्का गर्म दूध', 'हर्बल पानी', 'अदरक वाली चाय'],
      optionsAs: ['ইলাচি দিয়া চাহ', 'কুহুমীয়া গাখীৰ', 'তুলসীৰ পানী', 'আদা দিয়া চাহ'],
    ),
    OnboardingQuestion(
      id: 4,
      category: 'music',
      questionEn: 'What type of sounds or music comfort your mind?',
      questionHi: 'किस प्रकार का संगीत आपके मन को शांति देता है?',
      questionAs: 'কেনেকুৱা গীত বা শব্দই আপোনাৰ মন শান্ত কৰে?',
      optionsEn: ['Devotional songs', 'Classic melodies', 'Acoustic instruments', 'Sounds of birds and rain'],
      optionsHi: ['भक्ति गीत', 'पुराने मधुर गाने', 'शांत वाद्य संगीत', 'पक्षियों और बारिश की आवाज़'],
      optionsAs: ['ভক্তিগীত', 'পুৰণি সুৰীয়া গীত', 'শান্ত বাদ্যযন্ত্ৰৰ সুৰ', 'চৰাই আৰু বৰষুণৰ শব্দ'],
    ),
    OnboardingQuestion(
      id: 5,
      category: 'memory',
      questionEn: 'What is a cherished memory with your loved ones?',
      questionHi: 'अपने प्रियजनों के साथ आपकी सबसे प्यारी याद कौन सी है?',
      questionAs: 'আপোনাৰ আপোন মানুহৰ লগত কটোৱা কোনটো স্মৃতি আটাইতকৈ প্রিয়?',
      optionsEn: ['Festival celebrations', 'Cooking meals together', 'Sharing stories at tea time', 'Walks in nature'],
      optionsHi: ['त्योहारों का उल्लास', 'साथ मिलकर खाना बनाना', 'चाय पर बातें करना', 'प्रकृति में सैर'],
      optionsAs: ['উৎসৱৰ আনন্দ', 'লগ হৈ ৰন্ধা-বঢ়া', 'চাহ খাই কথা পতা', 'প্ৰকৃতিৰ বুকুত খোজ কঢ়া'],
    ),
    OnboardingQuestion(
      id: 6,
      category: 'nature',
      questionEn: 'Which flowers or plants do you find most lovely?',
      questionHi: 'आपको कौन से फूल या पौधे सबसे प्यारे लगते हैं?',
      questionAs: 'কোনবিধ ফুল বা গছ আপোনাৰ আটাইতকৈ ভাল লাগে?',
      optionsEn: ['Yellow marigolds', 'Sweet jasmine', 'Red hibiscus', 'Green veranda plants'],
      optionsHi: ['गेंदे के पीले फूल', 'सुगंधित चमेली', 'गुड़हल के लाल फूल', 'बरामदे के हरे पौधे'],
      optionsAs: ['হালধীয়া নাৰ্জী ফুল', 'সুগন্ধি খৰিকাজাই', 'ৰঙা জবা ফুল', 'বাৰান্দাৰ সেউজীয়া গছ'],
    ),
    OnboardingQuestion(
      id: 7,
      category: 'morning',
      questionEn: 'What morning habit gives you peace of mind?',
      questionHi: 'सुबह की कौन सी आदत आपको सुकून देती है?',
      questionAs: 'ৰাতিপুৱাৰ কোনটো নিয়মে আপোনাক মানসিক শান্তি দিয়ে?',
      optionsEn: ['Gentle veranda stroll', 'Deep calm breathing', 'Listening to the radio', 'A warm cup of water'],
      optionsHi: ['बरामदे में टहलना', 'गहरी सांस लेना', 'रेडियो सुनना', 'गुनगुना पानी पीना'],
      optionsAs: ['বাৰান্দাত অলপ খোজ কঢ়া', 'দীঘলকৈ উশাহ লোৱা', 'ৰেডিঅʼ শুনা', 'কুহুমীয়া পানী খোৱা'],
    ),
    OnboardingQuestion(
      id: 8,
      category: 'language',
      questionEn: 'Which language feels most natural for daily conversation?',
      questionHi: 'बातचीत के लिए कौन सी भाषा आपके सबसे करीब है?',
      questionAs: 'দৈনন্দিন কথাবতৰাৰ বাবে কোনটো ভাষা আপোনাৰ আটাইতকৈ সহজ লাগে?',
      optionsEn: ['English', 'Hindi', 'Assamese', 'Comfortable in all'],
      optionsHi: ['अंग्रेज़ी', 'हिन्दी', 'অসমীয়া (असमिया)', 'सभी में सहज'],
      optionsAs: ['ইংৰাজী', 'হিন্দী', 'অসমীয়া', 'সকলোতে সহজ'],
    ),
    OnboardingQuestion(
      id: 9,
      category: 'household',
      questionEn: 'Which light household activity do you enjoy doing?',
      questionHi: 'घर का कौन सा छोटा काम करना आपको अच्छा लगता है?',
      questionAs: 'ঘৰৰ কোনটো সহজ কাম কৰি আপুনি ভাল পায়?',
      optionsEn: ['Arranging flowers', 'Watering small plants', 'Folding soft linens', 'Organizing photo albums'],
      optionsHi: ['फूलदान सजाना', 'पौधों को पानी देना', 'कपड़े तह करना', 'फोटो एल्बम देखना'],
      optionsAs: ['ফুলদানি সজোৱা', 'ফুলত পানী দিয়া', 'কাপোৰ জপোৱা', 'পুৰণি ফটো চোৱা'],
    ),
    OnboardingQuestion(
      id: 10,
      category: 'smile',
      questionEn: 'What is something that always brings a gentle smile?',
      questionHi: 'ऐसी कौन सी बात है जो आपके चेहरे पर हमेशा मुस्कान लाती है?',
      questionAs: 'কোনটো কথাই আপোনাৰ মুখত সদায় এটি হাঁহি আনি দিয়ে?',
      optionsEn: ['Children playing happily', 'Birds chirping outside', 'A kind greeting from a friend', 'A familiar sweet melody'],
      optionsHi: ['बच्चों की हँसी', 'सुबह चिड़ियों की चहचहाहट', 'अपनों का स्नेह भरा नमस्कार', 'पुरानी मीठी धुन'],
      optionsAs: ['লʼৰা-ছোৱালীৰ হাঁহি', 'চৰাইৰ সুললিত মাত', 'আপোন মানুহৰ মৰমৰ মাত', 'এটি চিনাকি মিঠা গান'],
    ),
  ];

  void _speakQuestion(String text) {
    VoiceService.instance.speak(text);
  }

  void _nextQuestion({bool skipped = false}) async {
    final q = _questions[_currentIndex];
    final answerText = skipped ? 'Skipped' : (_selectedOption ?? 'Skipped');

    await DatabaseHelper.instance.saveOnboardingAnswer(
      OnboardingAnswer(
        questionId: q.id,
        answer: answerText,
        skipped: skipped,
      ),
    );

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
      });
    } else {
      setState(() {
        _isCompleted = true;
      });
      DatabaseHelper.instance.rewardsState.addXp(30);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AuthService.instance.currentLanguage;

    if (_isCompleted) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0FDF4),
        appBar: AppBar(
          title: Text(context.tr('app_name'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
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
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                  const Text(
                    "You're Done!",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Thank you for sharing about yourself.\nYour personalized profile has been safely saved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('⭐ +30 XP Points Earned!', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFB45309))),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(context.tr('btn_return_home'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final currentQ = _questions[_currentIndex];
    final questionText = currentQ.getQuestion(lang);
    final options = currentQ.getOptions(lang);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Get to Know You', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Question ${_currentIndex + 1} of ${_questions.length}',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2563EB), fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF0D9488), size: 28),
                    tooltip: 'Read Aloud',
                    onPressed: () => _speakQuestion(questionText),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Progress bar
              LinearProgressIndicator(
                value: (_currentIndex + 1) / _questions.length,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
                minHeight: 6,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 24),

              // Question text
              Text(
                questionText,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.3),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose what feels best, or skip anytime.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),

              // Options list
              Expanded(
                child: ListView.separated(
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final opt = options[idx];
                    final isSelected = _selectedOption == opt;
                    return InkWell(
                      onTap: () => setState(() => _selectedOption = opt),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Center(child: Icon(Icons.check, size: 16, color: Colors.white))
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                opt,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Action buttons: Skip & Continue
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: OutlinedButton(
                      onPressed: () => _nextQuestion(skipped: true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(context.tr('btn_skip'), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: ElevatedButton(
                      onPressed: _selectedOption != null ? () => _nextQuestion(skipped: false) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(context.tr('btn_next'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
