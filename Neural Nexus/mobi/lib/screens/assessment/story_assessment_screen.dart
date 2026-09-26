import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/voice_service.dart';
import '../../database/database_helper.dart';
import '../../models/assessment_model.dart';

class StoryAssessmentScreen extends StatefulWidget {
  const StoryAssessmentScreen({super.key});

  @override
  State<StoryAssessmentScreen> createState() => _StoryAssessmentScreenState();
}

class _StoryAssessmentScreenState extends State<StoryAssessmentScreen> {
  int _currentIndex = 0;
  int _correctCount = 0;
  int _skippedCount = 0;
  bool _isCompleted = false;

  final List<StoryQuestion> _stories = const [
    StoryQuestion(
      id: 1,
      titleEn: 'Story 1: The Yellow Marigolds',
      titleHi: 'कहानी 1: पीले गेंदे के फूल',
      titleAs: 'সাধু ১: হালধীয়া নাৰ্জী ফুল',
      storyEn: 'Mrs. Sharma watered her bright yellow marigolds this morning before drinking her warm cardamom tea.',
      storyHi: 'श्रीमती शर्मा ने आज सुबह इलायची वाली चाय पीने से पहले अपने खिले हुए पीले गेंदे के फूलों में पानी दिया।',
      storyAs: 'মিচেচ শৰ্মাই আজি পুৱা ইলাচি চাহ খোৱাৰ আগতে তেওঁৰ হালধীয়া নাৰ্জী ফুলবোৰত পানী দিলে।',
      questionEn: 'Did Mrs. Sharma water marigolds this morning?',
      questionHi: 'क्या श्रीमती शर्मा ने आज सुबह गेंदे के फूलों में पानी दिया?',
      questionAs: 'মিচেচ শৰ্মাই আজি পুৱা নাৰ্জী ফুলত পানী দিছিলনে?',
      expectedYes: true,
    ),
    StoryQuestion(
      id: 2,
      titleEn: 'Story 2: Grandfather’s Umbrella',
      titleHi: 'कहानी 2: दादाजी की छतरी',
      titleAs: 'সাধু ২: ককাৰ ছাতিটো',
      storyEn: 'Rohan forgot his umbrella at school. Grandfather walked to the bus stop holding his favorite black umbrella.',
      storyHi: 'रोहन अपनी छतरी स्कूल में भूल गया था। दादाजी अपनी पसंदीदा काली छतरी लेकर बस स्टॉप तक गए।',
      storyAs: 'ৰহনে স্কুলত ছাতিটো পাহৰি আহিছিল। ককায়ে নিজৰ প্ৰিয় কʼলা ছাতিটো লৈ বাছ আস্থানলৈ খোজ কাঢ়িলে।',
      questionEn: 'Was grandfather’s umbrella red?',
      questionHi: 'क्या दादाजी की छतरी लाल रंग की थी?',
      questionAs: 'ককাৰ ছাতিটো ৰঙা ৰঙৰ আছিলনে?',
      expectedYes: false,
    ),
    StoryQuestion(
      id: 3,
      titleEn: 'Story 3: Sweet Tea Time',
      titleHi: 'कहानी 3: शाम की मीठी चाय',
      titleAs: 'সাধু ৩: গধূলিৰ চাহৰ সময়',
      storyEn: 'In the afternoon, grandmother read a cookbook and baked warm sweet jalebis to enjoy with evening tea.',
      storyHi: 'दोपहर में दादी ने एक पुरानी किताब पढ़ी और शाम की चाय के साथ खाने के लिए गरमा-गरम मीठी जलेबियां बनाईं।',
      storyAs: 'দুপৰীয়া আইতাই এখন কিতাপ পঢ়ি গধূলি চাহৰ লগত খাবলৈ মিঠা জেলেপী বনালে।',
      questionEn: 'Did grandmother make sweet jalebis?',
      questionHi: 'क्या दादी ने मीठी जलेबियां बनाई थीं?',
      questionAs: 'আইতাই মিঠা জেলেপী বনাইছিলনে?',
      expectedYes: true,
    ),
    StoryQuestion(
      id: 4,
      titleEn: 'Story 4: The Sparrow by the Veranda',
      titleHi: 'कहानी 4: बरामदे की चिड़िया',
      titleAs: 'সাধু ৪: বাৰান্দাৰ চৰাইজনী',
      storyEn: 'A tiny brown sparrow landed softly on the wooden railing and bathed joyfully in the small earthen bowl of water.',
      storyHi: 'एक छोटी सी भूरी चिड़िया बरामदे की लकड़ी की रेलिंग पर आई और मिट्टी के छोटे कटोरे के पानी में नहाने लगी।',
      storyAs: 'এজনী সৰু চৰাই বাৰান্দাৰ ৰেলিংখনত পৰি মাটিৰ বাটিত থকা পানীত আনন্দৰে গা ধুলে।',
      questionEn: 'Was the bird bathing in an earthen bowl?',
      questionHi: 'क्या चिड़िया मिट्टी के कटोरे में नहा रही थी?',
      questionAs: 'চৰাইজনীয়ে মাটিৰ বাটিৰ পানীত গা ধুইছিলনে?',
      expectedYes: true,
    ),
    StoryQuestion(
      id: 5,
      titleEn: 'Story 5: Sunday Market Stroll',
      titleHi: 'कहानी 5: इतवार का बाज़ार',
      titleAs: 'সাধু ৫: দেওবৰীয়া বজাৰ',
      storyEn: 'Father visited the Sunday morning farmers market and bought fresh green apples and sweet ripe bananas.',
      storyHi: 'पिताजी रविवार की सुबह बाज़ार गए और ताज़ा हरे सेब तथा पके हुए मीठे केले खरीद कर लाए।',
      storyAs: 'দেউতাই দেওবাৰে ৰাতিপুৱা বজাৰলৈ গৈ সতেজ আপেল আৰু পকা কল কিনি আনিলে।',
      questionEn: 'Did father buy mangoes at the market?',
      questionHi: 'क्या पिताजी बाज़ार से आम खरीद कर लाए थे?',
      questionAs: 'দেউতাই বজাৰৰ পৰা আম কিনি আনিছিলনে?',
      expectedYes: false,
    ),
    StoryQuestion(
      id: 6,
      titleEn: 'Story 6: Meena’s Drawing',
      titleHi: 'कहानी 6: मीना का सुंदर चित्र',
      titleAs: 'সাধু ৬: মীনাৰ ছবি',
      storyEn: 'Little Meena brought a handmade drawing of a smiling sun and a blue river to show her grandparents.',
      storyHi: 'छोटी मीना ने एक हंसते हुए सूरज और नीली नदी का सुंदर चित्र बनाकर अपने दादा-दादी को दिखाया।',
      storyAs: 'সৰু মীনাই এটি হাঁহি থকা বেলি আৰু এখন নীলা নদীৰ ছবি আঁকি ককা-আইতাকক দেখুৱালে।',
      questionEn: 'Did Meena draw a smiling sun?',
      questionHi: 'क्या मीना ने मुस्कुराते हुए सूरज का चित्र बनाया था?',
      questionAs: 'মীনাই হাঁহি থকা বেলিৰ ছবি আঁকিছিলনে?',
      expectedYes: true,
    ),
    StoryQuestion(
      id: 7,
      titleEn: 'Story 7: Evening Radio Melodies',
      titleHi: 'कहानी 7: रेडियो के पुराने गीत',
      titleAs: 'সাধু ৭: ৰেডিঅʼৰ সুৰ',
      storyEn: 'At 6:00 PM, grandfather tuned the radio to listen to classical flute music while resting in his armchair.',
      storyHi: 'शाम 6 बजे दादाजी ने आरामकुर्सी पर बैठकर रेडियो पर बांसुरी की मधुर शास्त्रीय धुन सुनी।',
      storyAs: 'গধূলি ৬ বজাত ককায়ে আৰামী চকীত বহি ৰেডিঅʼত বাঁহীৰ সুৰ শুনিলে।',
      questionEn: 'Did grandfather listen to loud rock music?',
      questionHi: 'क्या दादाजी ने तेज़ रॉक संगीत सुना था?',
      questionAs: 'ককায়ে বৰ জোৰেৰে ৰক গান শুনিছিলনে?',
      expectedYes: false,
    ),
    StoryQuestion(
      id: 8,
      titleEn: 'Story 8: The Warm Shawl',
      titleHi: 'कहानी 8: ऊनी शॉल',
      titleAs: 'সাধু ৮: উমাল চাদৰখন',
      storyEn: 'When the cool breeze started blowing at sunset, mother wrapped a soft green woolen shawl around grandmother’s shoulders.',
      storyHi: 'शाम को ठंडी हवा चलने पर मां ने दादी के कंधों पर एक मुलायम हरी ऊनी शॉल ओढ़ा दी।',
      storyAs: 'গধূলি শীতল বতাহ জাক বলাত মাকে আইতাৰ গাত এখন সেউজীয়া উমাল চাদৰ মেৰিয়াই দিলে।',
      questionEn: 'Was the woolen shawl green?',
      questionHi: 'क्या ऊनी शॉल हरे रंग की थी?',
      questionAs: 'উমাল চাদৰখন সেউজীয়া আছিলনে?',
      expectedYes: true,
    ),
    StoryQuestion(
      id: 9,
      titleEn: 'Story 9: Letter from Cousin Kabir',
      titleHi: 'कहानी 9: कबीर का पत्र',
      titleAs: 'সাধু ৯: কবীৰৰ চিঠি',
      storyEn: 'The postman delivered a handwritten postcard from cousin Kabir sharing happy news about his university exam.',
      storyHi: 'डाकिया कबीर की ओर से एक पोस्टकार्ड लाया, जिसमें उसने विश्वविद्यालय की परीक्षा में सफलता का शुभ समाचार दिया था।',
      storyAs: 'ডাকোৱালে কবীৰৰ পৰা এখন চিঠি আনিলে, যʼত পৰীক্ষাত সফলতাৰ ভাল খবৰ লিখা আছিল।',
      questionEn: 'Was the news about an exam success?',
      questionHi: 'क्या समाचार परीक्षा की सफलता के बारे में था?',
      questionAs: 'চিঠিৰ খবৰটো পৰীক্ষাৰ সফলতাৰ বিষয়ে আছিলনে?',
      expectedYes: true,
    ),
    StoryQuestion(
      id: 10,
      titleEn: 'Story 10: The Moonlit Garden Walk',
      titleHi: 'कहानी 10: चांदनी रात की सैर',
      titleAs: 'সাধু ১০: জোনাক নিশাৰ খোজ',
      storyEn: 'After dinner, the family walked quietly on the garden pathway under the silvery full moon.',
      storyHi: 'रात के भोजन के बाद परिवार ने पूरे चांद की शीतल चांदनी में बगीचे के रास्ते पर शांति से टहला।',
      storyAs: 'ৰাতিৰ আহাৰৰ পিছত পৰিয়ালটোৱে জোনাক নিশা ফুলনিৰ বাটত অলপ সময় খোজ কাঢ়িলে।',
      questionEn: 'Did the family walk in the morning under hot sun?',
      questionHi: 'क्या परिवार दोपहर की चिलचिलाती धूप में टहलने गया था?',
      questionAs: 'পৰিয়ালটোৱে দুপৰীয়াৰ ৰʼদত খোজ কাঢ়িছিলনে?',
      expectedYes: false,
    ),
  ];

  void _speakStory(String text) {
    VoiceService.instance.speak(text);
  }

  void _answer(bool selectedYes) async {
    final q = _stories[_currentIndex];
    final isCorrect = selectedYes == q.expectedYes;

    if (isCorrect) {
      _correctCount++;
    }

    _nextStep();
  }

  void _skip() {
    _skippedCount++;
    _nextStep();
  }

  void _nextStep() async {
    if (_currentIndex < _stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      final scorePercent = (_correctCount / _stories.length) * 100;
      final session = AssessmentSession(
        id: 'assess_${DateTime.now().millisecondsSinceEpoch}',
        patientId: AuthService.instance.patientId ?? 'ifra_01',
        totalQuestions: _stories.length,
        correctAnswers: _correctCount,
        skippedCount: _skippedCount,
        scorePercent: scorePercent,
      );

      await DatabaseHelper.instance.insertAssessmentSession(session);

      setState(() {
        _isCompleted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AuthService.instance.currentLanguage;

    if (_isCompleted) {
      final scorePercent = ((_correctCount / _stories.length) * 100).round();
      return Scaffold(
        backgroundColor: const Color(0xFFFAF5FF),
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
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🧠', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                  const Text(
                    'Assessment Complete!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You recalled $_correctCount out of ${_stories.length} story details correctly ($scorePercent%).',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('⭐ +30 XP Points Added to Rewards!', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF166534))),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Great recall! Your short-term memory practice strengthens your neural pathways every day.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
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

    final currentStory = _stories[_currentIndex];
    final storyTitle = currentStory.getTitle(lang);
    final storyText = currentStory.getStory(lang);
    final questionText = currentStory.getQuestion(lang);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF4FF),
      appBar: AppBar(
        title: const Text('Memory Assessment', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
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
              // Story counter header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Story ${_currentIndex + 1} of ${_stories.length}',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF7C3AED), fontSize: 14),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF7C3AED), size: 28),
                    tooltip: 'Listen to Story',
                    onPressed: () => _speakStory('$storyText $questionText'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Progress bar
              LinearProgressIndicator(
                value: (_currentIndex + 1) / _stories.length,
                backgroundColor: const Color(0xFFE9D5FF),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF9333EA)),
                minHeight: 6,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 18),

              // Story Box Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE9D5FF)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('📖', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            storyTitle,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF581C87)),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: Color(0xFFF3E8FF)),
                    Text(
                      storyText,
                      style: const TextStyle(fontSize: 16, height: 1.45, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Question Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Question:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8))),
                    const SizedBox(height: 4),
                    Text(
                      questionText,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), height: 1.3),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // YES / NO Big Touch Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 62,
                      child: ElevatedButton(
                        onPressed: () => _answer(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 24),
                            SizedBox(width: 8),
                            Text('YES', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SizedBox(
                      height: 62,
                      child: ElevatedButton(
                        onPressed: () => _answer(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cancel_rounded, size: 24),
                            SizedBox(width: 8),
                            Text('NO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Skip button
              Center(
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    'Skip this story →',
                    style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
