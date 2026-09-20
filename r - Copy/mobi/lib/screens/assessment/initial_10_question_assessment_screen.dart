import 'package:flutter/material.dart';
import '../../models/assessment_model.dart';
import '../../services/auth_service.dart';
import '../../services/voice_service.dart';
import '../../database/database_helper.dart';
import '../patient/patient_home_screen.dart';

class Initial10QuestionAssessmentScreen extends StatefulWidget {
  final bool isRetake;
  const Initial10QuestionAssessmentScreen({super.key, this.isRetake = false});

  @override
  State<Initial10QuestionAssessmentScreen> createState() =>
      _Initial10QuestionAssessmentScreenState();
}

class _Initial10QuestionAssessmentScreenState
    extends State<Initial10QuestionAssessmentScreen> {
  int _currentIndex = 0;
  String? _selectedAnswer; // 'Yes' or 'No'
  bool _isPlayingAudio = false;
  final Map<int, String> _responses = {};
  bool _isSubmitting = false;

  final List<StoryQuestion> _questions = kInitial10Questions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakCurrentQuestionFlow();
    });
  }

  @override
  void dispose() {
    VoiceService.instance.stop();
    super.dispose();
  }

  String get _currentLang => AuthService.instance.currentLanguage;

  void _speakCurrentQuestionFlow() {
    final q = _questions[_currentIndex];
    final lang = _currentLang;
    final story = q.getStory(lang);
    final question = q.getQuestion(lang);

    String script = '';
    if (lang == 'hi') {
      script =
          'प्रश्न ${_currentIndex + 1} कुल 10 में से। अब मैं कहानी पढ़ूँगा। $story। अब प्रश्न सुनिए। $question। कृपया हाँ या ना में उत्तर दें। विकल्प एक: हाँ। विकल्प दो: ना।';
    } else if (lang == 'as') {
      script =
          'প্ৰশ্ন ${_currentIndex + 1}, ১০ টাৰ ভিতৰত। মই সাধুটো পঢ়িম। $story। এতিয়া প্ৰশ্নটো শুনক। $question। অনুগ্ৰহ কৰি হয় বা নহয় বাচক। বিকল্প ১: হয়। বিকল্প ২: নহয়।';
    } else {
      script =
          'Question ${_currentIndex + 1} of 10. I will now read the story. $story. Now I will read the question. $question. Please choose Yes or No. Option 1: Yes. Option 2: No.';
    }

    setState(() => _isPlayingAudio = true);
    VoiceService.instance.speak(script);
  }

  void _onPlayPauseTap() {
    if (_isPlayingAudio) {
      VoiceService.instance.stop();
      setState(() => _isPlayingAudio = false);
      VoiceService.instance.speakAudioControl('Pause');
    } else {
      setState(() => _isPlayingAudio = true);
      VoiceService.instance.speakAudioControl('Play');
      final q = _questions[_currentIndex];
      final story = q.getStory(_currentLang);
      VoiceService.instance.speak(story);
    }
  }

  void _onReplayTap() {
    VoiceService.instance.stop();
    VoiceService.instance.speakAudioControl('Replay');
    _speakCurrentQuestionFlow();
  }

  void _onAnswerSelected(String answer) {
    setState(() {
      _selectedAnswer = answer;
      _responses[_questions[_currentIndex].id] = answer;
    });

    if (answer == 'Yes') {
      if (_currentLang == 'hi') {
        VoiceService.instance.speak('आपने हाँ चुना है।');
      } else if (_currentLang == 'as') {
        VoiceService.instance.speak('আপুনি হয় বাচি লৈছে।');
      } else {
        VoiceService.instance.speak('You selected Yes.');
      }
    } else {
      if (_currentLang == 'hi') {
        VoiceService.instance.speak('आपने ना चुना है।');
      } else if (_currentLang == 'as') {
        VoiceService.instance.speak('আপুনি নহয় বাচি লৈছে।');
      } else {
        VoiceService.instance.speak('You selected No.');
      }
    }
  }

  void _onNextQuestion() {
    if (_selectedAnswer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _currentLang == 'hi'
                ? 'कृपया आगे बढ़ने से पहले हाँ या ना चुनें।'
                : (_currentLang == 'as'
                    ? 'অনুগ্ৰহ কৰি আগবাঢ়িবলৈ হয় বা নহয় বাচক।'
                    : 'Please choose Yes or No to proceed.'),
          ),
          backgroundColor: const Color(0xFF0F766E),
        ),
      );
      return;
    }

    VoiceService.instance.stop();

    if (_currentIndex < _questions.length - 1) {
      final nextNum = _currentIndex + 2;
      if (_currentLang == 'hi') {
        VoiceService.instance.speak('प्रश्न $nextNum पर जा रहे हैं।');
      } else if (_currentLang == 'as') {
        VoiceService.instance.speak('প্ৰশ্ন $nextNum লৈ আগবাঢ়িছো।');
      } else {
        VoiceService.instance.speak('Moving to Question $nextNum of 10.');
      }

      setState(() {
        _currentIndex++;
        _selectedAnswer = _responses[_questions[_currentIndex].id];
        _isPlayingAudio = false;
      });

      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _speakCurrentQuestionFlow();
      });
    } else {
      _completeAssessment();
    }
  }

  Future<void> _completeAssessment() async {
    setState(() => _isSubmitting = true);
    VoiceService.instance.stop();

    final patientId = AuthService.instance.patientId ?? 'patient_new';

    final responseItems = _questions.map((q) {
      final ans = _responses[q.id] ?? 'No';
      return InitialAssessmentResponseItem(
        questionId: q.id,
        characterName: q.characterName,
        location: q.location,
        questionText: q.getQuestion(_currentLang),
        storySummary: q.getStory(_currentLang),
        answer: ans,
        language: _currentLang,
      );
    }).toList();

    await DatabaseHelper.instance.insertInitialAssessment(
      patientId: patientId,
      language: _currentLang,
      notes: '10-Question Initial Onboarding Screening',
      responses: responseItems,
    );

    await AuthService.instance.markInitialAssessmentCompleted(pId: patientId);

    if (!mounted) return;

    _showThankYouPopup();
  }

  void _showThankYouPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: const [
              Text('🎉 ', style: TextStyle(fontSize: 28)),
              Expanded(
                child: Text(
                  'Thank You',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentLang == 'hi'
                    ? 'शुरुआती मूल्यांकन पूरा करने के लिए धन्यवाद। आपके उत्तर सुरक्षित रूप से सहेज लिए गए हैं और आपके देखभालकर्ता के साथ साझा कर दिए गए हैं।'
                    : (_currentLang == 'as'
                        ? 'প্ৰাৰম্ভিক মূল্যায়ন সম্পূৰ্ণ কৰাৰ বাবে ধন্যবাদ। আপোনাৰ সঁহাৰিসমূহ সুৰক্ষিতভাৱে সংৰক্ষণ কৰা হৈছে আৰু আপোনাৰ সেৱাকৰ্তাৰ লগত ভাগ-বতৰা কৰা হৈছে।'
                        : 'Thank you for completing your initial assessment. Your responses have been saved and shared with your caregiver. Let\'s continue to your home page.'),
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.stars_rounded, color: Color(0xFF16A34A), size: 24),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '+50 XP Welcome Bonus Earned!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const PatientHomeScreen()),
                  );
                },
                child: Text(
                  _currentLang == 'hi'
                      ? 'होम स्क्रीन पर जाएं'
                      : (_currentLang == 'as' ? 'ঘৰলৈ যাওক' : 'Continue to Home'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getAvatarColor(int id) {
    const colors = [
      Color(0xFF0F766E),
      Color(0xFFB45309),
      Color(0xFF1D4ED8),
      Color(0xFF7E22CE),
      Color(0xFFBE185D),
      Color(0xFF047857),
      Color(0xFFC2410C),
      Color(0xFF4338CA),
      Color(0xFF0F766E),
      Color(0xFF854D0E),
    ];
    return colors[(id - 1) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;
    final lang = _currentLang;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () {
            VoiceService.instance.stop();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          lang == 'hi'
              ? 'प्रारंभिक मूल्यांकन'
              : (lang == 'as' ? 'প্ৰাৰম্ভিক মূল্যায়ন' : 'Initial Assessment'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        actions: [
          // Language Switcher Pills
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLangPill('en', 'EN'),
                  _buildLangPill('hi', 'हि'),
                  _buildLangPill('as', 'অস'),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Progress Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang == 'hi'
                            ? 'प्रश्न ${_currentIndex + 1} / 10'
                            : (lang == 'as'
                                ? 'প্ৰশ্ন ${_currentIndex + 1} / ১০'
                                : 'Question ${_currentIndex + 1} of 10'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0F766E)),
                    ),
                  ),
                ],
              ),
            ),

            // Main Scrollable Assessment Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Character & Location Card (Matches Template)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          // Regional Avatar Badge
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: _getAvatarColor(q.id),
                            child: Text(
                              q.characterName.substring(0, 1),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${q.characterName}, ${q.age}',
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFCCFBF1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.location_on_rounded,
                                              size: 14, color: Color(0xFF0F766E)),
                                          const SizedBox(width: 4),
                                          Text(
                                            q.locationBadge,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0F766E),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 2. Story Narrative Box (with left teal accent border)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                            children: const [
                              Icon(Icons.menu_book_rounded,
                                  color: Color(0xFF0F766E), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Story',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F766E),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.only(left: 12),
                            decoration: const BoxDecoration(
                              border: Border(
                                left: BorderSide(color: Color(0xFF0D9488), width: 4),
                              ),
                            ),
                            child: Text(
                              q.getStory(lang),
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 3. Audio Controls Section ("Listen to this story")
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDFA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF99F6E4)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isPlayingAudio
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_fill_rounded,
                              size: 40,
                              color: const Color(0xFF0F766E),
                            ),
                            onPressed: _onPlayPauseTap,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang == 'hi'
                                      ? 'इस कहानी को सुनें'
                                      : (lang == 'as'
                                          ? 'সাধুটো শুনক'
                                          : 'Listen to this story'),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F766E),
                                  ),
                                ),
                                Text(
                                  _isPlayingAudio
                                      ? (lang == 'hi' ? 'चल रहा है...' : (lang == 'as' ? 'বাজি আছে...' : 'Playing narration...'))
                                      : (lang == 'hi' ? 'टैप करके सुनें' : (lang == 'as' ? 'ট্যাপ কৰি শুনক' : 'Tap play to listen')),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF115E59),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.replay_rounded, color: Color(0xFF0F766E)),
                            onPressed: _onReplayTap,
                            tooltip: 'Replay audio',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 4. Question Section Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.help_outline_rounded,
                                  color: Color(0xFF1D4ED8), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Question',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            q.getQuestion(lang),
                            style: const TextStyle(
                              fontSize: 17,
                              height: 1.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 5. Elderly-Friendly Large YES / NO Response Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildAnswerButton(
                            label: lang == 'hi' ? 'हाँ' : (lang == 'as' ? 'হয়' : 'YES'),
                            subLabel: 'Yes',
                            value: 'Yes',
                            isSelected: _selectedAnswer == 'Yes',
                            activeColor: const Color(0xFF16A34A),
                            activeBg: const Color(0xFFDCFCE7),
                            icon: Icons.check_circle_rounded,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildAnswerButton(
                            label: lang == 'hi' ? 'ना' : (lang == 'as' ? 'নহয়' : 'NO'),
                            subLabel: 'No',
                            value: 'No',
                            isSelected: _selectedAnswer == 'No',
                            activeColor: const Color(0xFFDC2626),
                            activeBg: const Color(0xFFFEE2E2),
                            icon: Icons.cancel_rounded,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 6. Navigation Next / Submit Button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 3,
                        ),
                        onPressed: _isSubmitting ? null : _onNextQuestion,
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _currentIndex == _questions.length - 1
                                        ? (lang == 'hi'
                                            ? 'मूल्यांकन पूरा करें'
                                            : (lang == 'as'
                                                ? 'মূল্যায়ন সম্পূৰ্ণ কৰক'
                                                : 'Complete Assessment'))
                                        : (lang == 'hi'
                                            ? 'अगला प्रश्न'
                                            : (lang == 'as'
                                                ? 'পৰৱৰ্তী প্ৰশ্ন'
                                                : 'Next Question')),
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded, size: 20),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerButton({
    required String label,
    required String subLabel,
    required String value,
    required bool isSelected,
    required Color activeColor,
    required Color activeBg,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () => _onAnswerSelected(value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFCBD5E1),
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 36,
              color: isSelected ? activeColor : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isSelected ? activeColor : const Color(0xFF1E293B),
              ),
            ),
            if (label != subLabel) ...[
              const SizedBox(height: 2),
              Text(
                subLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? activeColor : const Color(0xFF64748B),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLangPill(String code, String label) {
    final isSelected = _currentLang == code;
    return InkWell(
      onTap: () {
        VoiceService.instance.stop();
        AuthService.instance.switchLanguage(code);
        setState(() {});
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _speakCurrentQuestionFlow();
        });
      },
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
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
