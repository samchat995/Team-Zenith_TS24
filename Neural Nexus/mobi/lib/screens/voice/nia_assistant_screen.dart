import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/voice_service.dart';
import '../reminders/reminder_screen.dart';
import '../activities/meaningful_activities_screen.dart';
import '../memory/my_memory_screen.dart';
import '../rewards/rewards_screen.dart';
import '../patient/games_screen.dart';
import '../patient/progress_screen.dart';
import '../mood/mood_screen.dart';
import '../../games/memory_match_game.dart';

class NiaAssistantScreen extends StatefulWidget {
  final int pendingReminders;
  final double progress;

  const NiaAssistantScreen({
    super.key,
    this.pendingReminders = 2,
    this.progress = 48.0,
  });

  @override
  State<NiaAssistantScreen> createState() => _NiaAssistantScreenState();
}

class _NiaAssistantScreenState extends State<NiaAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<NiaMessage> _messages = [];
  bool _isListening = false;
  String? _currentlySpeakingId;

  @override
  void initState() {
    super.initState();
    _addInitialGreeting();
  }

  void _addInitialGreeting() {
    final lang = AuthService.instance.language;
    final name = AuthService.instance.patientName;

    String greeting;
    if (lang == 'hi') {
      greeting = 'नमस्ते $name! मैं निया हूँ, आपकी याददाश्त साथी। आज मैं आपकी क्या सहायता कर सकती हूँ?';
    } else if (lang == 'as') {
      greeting = 'নমস্কাৰ $name! মই নিয়া, আপোনাৰ স্মৃতি সংগী। আজি মই আপোনাক কিদৰে সহায় কৰিব পাৰোঁ?';
    } else {
      greeting = 'Hello $name! I am Nia, your memory companion. How can I help you today?';
    }

    _messages.add(
      NiaMessage(
        id: 'msg_welcome',
        text: greeting,
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _handleSend([String? presetText]) {
    final text = presetText ?? _textController.text.trim();
    if (text.isEmpty) return;

    if (presetText == null) {
      _textController.clear();
    }

    final userMsgId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final userMsg = NiaMessage(
      id: userMsgId,
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
    });
    _scrollToBottom();

    // Process via VoiceService
    final result = VoiceService.instance.processVoiceCommand(
      text,
      patientName: AuthService.instance.patientName,
      pendingReminders: widget.pendingReminders,
      progress: widget.progress,
      language: AuthService.instance.language,
    );

    final niaMsgId = 'nia_${DateTime.now().millisecondsSinceEpoch}';
    final responseText = result['response'] as String? ?? 'I am here to help you!';
    final action = result['action'] as String?;
    final actionLabel = result['actionLabel'] as String?;

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _messages.add(
          NiaMessage(
            id: niaMsgId,
            text: responseText,
            isUser: false,
            timestamp: DateTime.now(),
            action: action,
            actionLabel: actionLabel,
          ),
        );
      });
      _scrollToBottom();
    });
  }

  void _toggleSpeak(NiaMessage message) {
    if (_currentlySpeakingId == message.id) {
      VoiceService.instance.stopSpeaking();
      setState(() {
        _currentlySpeakingId = null;
      });
    } else {
      setState(() {
        _currentlySpeakingId = message.id;
      });
      VoiceService.instance.speak(message.text);
      // Auto reset speaking state after reasonable estimated time
      final estimatedSec = (message.text.length / 10).clamp(3, 14).toInt();
      Future.delayed(Duration(seconds: estimatedSec), () {
        if (mounted && _currentlySpeakingId == message.id) {
          setState(() {
            _currentlySpeakingId = null;
          });
        }
      });
    }
  }

  void _executeAction(String action) {
    switch (action) {
      case 'NAVIGATE_GAME':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MemoryMatchGame()));
        break;
      case 'NAVIGATE_REMINDERS':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderScreen()));
        break;
      case 'NAVIGATE_ACTIVITIES':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MeaningfulActivitiesScreen()));
        break;
      case 'NAVIGATE_PROGRESS':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen()));
        break;
      case 'NAVIGATE_REWARDS':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsScreen()));
        break;
      case 'NAVIGATE_MEMORY':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyMemoryScreen()));
        break;
      case 'NAVIGATE_MOOD':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MoodScreen()));
        break;
      default:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const GamesScreen()));
    }
  }

  void _triggerVoiceInput() {
    setState(() => _isListening = true);

    // Simulate speech-to-text with elderly-friendly prompt
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _isListening = false);

      // Web fallback reminder
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AuthService.instance.language == 'hi'
                ? 'माइक इनपुट उपलब्ध नहीं है। आप नीचे लिखकर संदेश भेज सकते हैं।'
                : (AuthService.instance.language == 'as'
                    ? 'মাইক্ৰফোন ইনপুট উপলব্ধ নহয়। আপুনি বাৰ্তা টাইপ কৰিব পাৰে।'
                    : 'Voice input isn\'t available on this browser. You can type your message below.'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF0F766E),
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    VoiceService.instance.stopSpeaking();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = AuthService.instance.language;

    final String title = lang == 'hi' ? 'निया साथी' : (lang == 'as' ? 'নিয়া সংগী' : 'NIA Assistant');
    final String subtitle = lang == 'hi' ? 'आपकी याददाश्त साथी' : (lang == 'as' ? 'আপোনাৰ স্মৃতি সংগী' : 'Your Memory Companion');
    final String placeholder = lang == 'hi' ? 'संदेश लिखें...' : (lang == 'as' ? 'বাৰ্তা লিখক...' : 'Type a message...');
    final String tryAsking = lang == 'hi' ? 'सुझाव:' : (lang == 'as' ? 'পৰামৰ্শ:' : 'Try asking:');

    final List<Map<String, String>> quickPrompts = [
      {
        'label': lang == 'hi' ? '💊 दवा व रिमाइंडर?' : (lang == 'as' ? '💊 কি সোঁৱৰণী আছে?' : '💊 What reminders do I have?'),
        'query': 'What reminders do I have?',
      },
      {
        'label': lang == 'hi' ? '🧠 कौन सा खेल खेलूँ?' : (lang == 'as' ? '🧠 কি খেল খেলিম?' : '🧠 What game should I play?'),
        'query': 'What game should I play?',
      },
      {
        'label': lang == 'hi' ? '🌱 गतिविधि क्या करूँ?' : (lang == 'as' ? '🌱 কি কাৰ্য্যকলাপ কৰিম?' : '🌱 What activity can I do?'),
        'query': 'What activity can I do?',
      },
      {
        'label': lang == 'hi' ? '📊 मेरी प्रगति दिखाएं' : (lang == 'as' ? '📊 মোৰ প্ৰগতি দেখুৱাওক' : '📊 Show my progress'),
        'query': 'Show my progress',
      },
      {
        'label': lang == 'hi' ? '🎁 मेरे रिवार्ड्स' : (lang == 'as' ? '🎁 মোৰ পুৰস্কাৰ' : '🎁 Show my rewards'),
        'query': 'Show my rewards',
      },
      {
        'label': lang == 'hi' ? '💭 मीना कौन है?' : (lang == 'as' ? '💭 মিনা কোন?' : '💭 Who is Meena?'),
        'query': 'Who is Meena?',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: const Color(0xFF0F172A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF0284C7)],
                ),
              ),
              child: const Center(
                child: Text('🤖', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F766E)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Clear Chat',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            onPressed: () {
              setState(() {
                _messages.clear();
                _addInitialGreeting();
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status bar indicating local intelligence & non-diagnostic safety
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: const Color(0xFFCCFBF1),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF0F766E)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lang == 'hi'
                          ? 'सक्रिय: स्थानीय स्मृति सहायक (गोपनीय व सुरक्षित)'
                          : (lang == 'as'
                              ? 'সক্ৰিয়: স্থানীয় স্মৃতি সংগী (সুৰক্ষিত আৰু ব্যক্তিগত)'
                              : 'Active: Local Cognitive Companion (Private & Secure)'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F766E)),
                    ),
                  ),
                ],
              ),
            ),

            // Quick suggestion chips
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      tryAsking,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: quickPrompts.map((p) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(p['label']!),
                            backgroundColor: const Color(0xFFF1F5F9),
                            labelStyle: const TextStyle(
                              color: Color(0xFF0F766E),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: Color(0xFF99F6E4)),
                            ),
                            onPressed: () => _handleSend(p['query']),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Chat Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg.isUser;
                  final isSpeakingThis = _currentlySpeakingId == msg.id;

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.85,
                      ),
                      child: Column(
                        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isUser ? const Color(0xFF0F766E) : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
                                bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isUser) ...[
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('🤖 ', style: TextStyle(fontSize: 15)),
                                      const Text(
                                        'NIA',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F766E),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                ],
                                Text(
                                  msg.text,
                                  style: TextStyle(
                                    fontSize: 16,
                                    height: 1.4,
                                    fontWeight: FontWeight.w600,
                                    color: isUser ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Controls below Nia message: Speak button & Action navigation button
                          if (!isUser) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                InkWell(
                                  onTap: () => _toggleSpeak(msg),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSpeakingThis ? const Color(0xFFDC2626) : const Color(0xFFE0F2FE),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isSpeakingThis ? Icons.stop_rounded : Icons.volume_up_rounded,
                                          size: 16,
                                          color: isSpeakingThis ? Colors.white : const Color(0xFF0369A1),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isSpeakingThis
                                              ? (lang == 'hi' ? 'रोकें' : (lang == 'as' ? 'বন্ধ কৰক' : 'Stop'))
                                              : (lang == 'hi' ? 'सुनें' : (lang == 'as' ? 'শুনক' : 'Speak')),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isSpeakingThis ? Colors.white : const Color(0xFF0369A1),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (msg.action != null && msg.actionLabel != null)
                                  ElevatedButton.icon(
                                    onPressed: () => _executeAction(msg.action!),
                                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                                    label: Text(msg.actionLabel!),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0F766E),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Listening indicator
            if (_isListening)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFFFEF3C7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.mic, color: Color(0xFFD97706), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Listening... Please speak clearly',
                      style: TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
              ),

            // Bottom Input Bar
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Mic button
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _isListening ? const Color(0xFFDC2626) : const Color(0xFF0F766E),
                      size: 28,
                    ),
                    onPressed: _triggerVoiceInput,
                  ),

                  // Text input
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      decoration: InputDecoration(
                        hintText: placeholder,
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFF0F766E), width: 2),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F766E),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                      onPressed: () => _handleSend(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
