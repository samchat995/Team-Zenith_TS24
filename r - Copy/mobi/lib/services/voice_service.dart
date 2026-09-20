import 'voice_platform.dart';
import 'auth_service.dart';

class NiaMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? action;
  final String? actionLabel;

  NiaMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.action,
    this.actionLabel,
  });
}

class VoiceService {
  static final VoiceService instance = VoiceService._internal();
  VoiceService._internal();

  bool isListening = false;
  bool isSpeaking = false;

  void speak(String text, {String? lang}) {
    final language = lang ?? AuthService.instance.language;
    isSpeaking = true;
    VoicePlatform.speak(text, language);
  }

  void stopSpeaking() {
    isSpeaking = false;
    VoicePlatform.stop();
  }

  void stop() => stopSpeaking();

  void speakTap(String feedback, {String? lang}) {
    speak(feedback, lang: lang);
  }

  void speakScreen(String screenTitle, String summary, {String? lang}) {
    final text = "$screenTitle. $summary";
    speak(text, lang: lang);
  }

  void speakAudioControl(String action, {String? lang}) {
    final language = lang ?? AuthService.instance.language;
    String text;
    final act = action.toLowerCase();
    if (act == 'play') {
      text = language == 'hi'
          ? "कहानी सुनाई जा रही है।"
          : (language == 'as' ? "সাধু শুনোৱা হৈছে।" : "Playing the story.");
    } else if (act == 'pause') {
      text = language == 'hi'
          ? "कहानी रोक दी गई है।"
          : (language == 'as' ? "সাধু স্থগিত কৰা হʼল।" : "Story paused.");
    } else if (act == 'replay') {
      text = language == 'hi'
          ? "कहानी फिर से शुरू हो रही है।"
          : (language == 'as' ? "পুনৰ আৰম্ভ কৰা হৈছে।" : "Playing again.");
    } else {
      text = action;
    }
    speak(text, lang: language);
  }

  bool get isTtsSupported => VoicePlatform.isSpeechSupported;

  Map<String, dynamic> processVoiceCommand(
    String rawQuery, {
    String? patientName,
    int pendingReminders = 2,
    double progress = 48.0,
    String? language,
  }) {
    final query = rawQuery.trim().toLowerCase();
    final lang = language ?? AuthService.instance.language;
    final name = patientName ?? AuthService.instance.patientName;

    // 1. Reminders
    if (query.contains('reminder') ||
        query.contains('medicine') ||
        query.contains('water') ||
        query.contains('pill') ||
        query.contains('bp') ||
        query.contains('दवा') ||
        query.contains('याद') ||
        query.contains('ওষুধ') ||
        query.contains('মনত')) {
      if (lang == 'hi') {
        return {
          'action': 'NAVIGATE_REMINDERS',
          'actionLabel': 'रिमाइंडर खोलें',
          'response': 'आज आपके $pendingReminders रिमाइंडर हैं। मुख्य रिमाइंडर दोपहर 2:00 बजे बीपी की दवा और 4:00 बजे गुनगुना पानी पीने का है।'
        };
      } else if (lang == 'as') {
        return {
          'action': 'NAVIGATE_REMINDERS',
          'actionLabel': 'সোঁৱৰণী খোলক',
          'response': 'আজি আপোনাৰ $pendingRemindersটা সোঁৱৰণী বাকী আছে। দুপৰীয়া ২:০০ বজাত ৰক্তচাপৰ ঔষধ আৰু আবেলি ৪:০০ বজাত কুহুমীয়া পানী খাব লাগিব।'
        };
      } else {
        return {
          'action': 'NAVIGATE_REMINDERS',
          'actionLabel': 'View Reminders',
          'response': 'You have $pendingReminders reminders today: Afternoon Blood Pressure Medicine at 2:00 PM, and Warm Water Hydration at 4:00 PM.'
        };
      }
    }

    // 2. Games / Cognitive Play
    if (query.contains('game') ||
        query.contains('play') ||
        query.contains('match') ||
        query.contains('cognitive') ||
        query.contains('खेल') ||
        query.contains('খেলা')) {
      if (lang == 'hi') {
        return {
          'action': 'NAVIGATE_GAME',
          'actionLabel': 'खेल शुरू करें',
          'response': 'आज मैं मेमोरी मैच (लेवल 3) खेलने की सलाह देती हूँ! हाल के खेलों में आपका प्रदर्शन बहुत अच्छा रहा है।'
        };
      } else if (lang == 'as') {
        return {
          'action': 'NAVIGATE_GAME',
          'actionLabel': 'খেল আৰম্ভ কৰক',
          'response': 'আজি মই মেমৰি মেচ (স্তৰ ৩) খেলিবলৈ পৰামৰ্শ দিছোঁ! আপোনাৰ প্ৰদৰ্শন বহুত ভাল আছিল।'
        };
      } else {
        return {
          'action': 'NAVIGATE_GAME',
          'actionLabel': 'Start Memory Game',
          'response': 'I recommend playing Memory Match (Level 3) today! Your recent accuracy in memory games has been wonderful.'
        };
      }
    }

    // 3. Meaningful Activities
    if (query.contains('activity') ||
        query.contains('activities') ||
        query.contains('garden') ||
        query.contains('paint') ||
        query.contains('music') ||
        query.contains('story') ||
        query.contains('गतिविधि') ||
        query.contains('काम') ||
        query.contains('বাগান') ||
        query.contains('ছবি')) {
      if (lang == 'hi') {
        return {
          'action': 'NAVIGATE_ACTIVITIES',
          'actionLabel': 'गतिविधियाँ देखें',
          'response': 'आपके लिए 7 सार्थक गतिविधियाँ हैं! आज 15 मिनट बागवानी या चित्रकारी करने का प्रयास करें।'
        };
      } else if (lang == 'as') {
        return {
          'action': 'NAVIGATE_ACTIVITIES',
          'actionLabel': 'কাৰ্য্যকলাপ খোলক',
          'response': 'আপোনাৰ বাবে ৭টা অৰ্থপূৰ্ণ কাৰ্য্যকলাপ আছে! আজি ১৫ মিনিট বাগানৰ কাম বা ছবি অঁকা আৰম্ভ কৰিব পাৰে।'
        };
      } else {
        return {
          'action': 'NAVIGATE_ACTIVITIES',
          'actionLabel': 'Explore Activities',
          'response': 'You have 7 meaningful activities available! I recommend trying 15 minutes of Gardening or gentle Painting today.'
        };
      }
    }

    // 4. Progress / How am I doing
    if (query.contains('progress') ||
        query.contains('how am i') ||
        query.contains('doing') ||
        query.contains('score') ||
        query.contains('performance') ||
        query.contains('प्रगति') ||
        query.contains('प্ৰগতি')) {
      if (lang == 'hi') {
        return {
          'action': 'NAVIGATE_PROGRESS',
          'actionLabel': 'प्रगति देखें',
          'response': 'शानदार! आपने आज की ${progress.toInt()}% गतिविधियाँ पूरी कर ली हैं और 2 गेम समाप्त किए हैं।'
        };
      } else if (lang == 'as') {
        return {
          'action': 'NAVIGATE_PROGRESS',
          'actionLabel': 'প্ৰগতি চাওক',
          'response': 'সুন্দৰ! আপুনি আজিৰ ${progress.toInt()}% কাম সম্পূৰ্ণ কৰিছে আৰু ২টা খেল সমাপ্ত কৰিছে।'
        };
      } else {
        return {
          'action': 'NAVIGATE_PROGRESS',
          'actionLabel': 'View Progress',
          'response': 'You have completed ${progress.toInt()}% of today\'s activities with 2 cognitive games finished! Your participation is very steady.'
        };
      }
    }

    // 5. Rewards / XP / Streak
    if (query.contains('reward') ||
        query.contains('xp') ||
        query.contains('badge') ||
        query.contains('streak') ||
        query.contains('पुरस्कार') ||
        query.contains('बँटा')) {
      if (lang == 'hi') {
        return {
          'action': 'NAVIGATE_REWARDS',
          'actionLabel': 'रिवार्ड्स देखें',
          'response': 'आपके पास 240 XP हैं! आपका गेमिफिकेशन स्तर 3 है और आप 4 दिनों के स्ट्रीक पर हैं।'
        };
      } else if (lang == 'as') {
        return {
          'action': 'NAVIGATE_REWARDS',
          'actionLabel': 'বঁটা চাওক',
          'response': 'আপোনাৰ ওচৰত ২৪০ XP আছে! আপুনি ৩ নম্বৰ স্তৰত আছে আৰু আপোনাৰ ৪ দিনৰ ধাৰাবাহিকতা আছে।'
        };
      } else {
        return {
          'action': 'NAVIGATE_REWARDS',
          'actionLabel': 'View Rewards',
          'response': 'You have earned 240 XP! Your gamification level is Level 3, and you have maintained a 4-day streak with 3 badges.'
        };
      }
    }

    // 6. Memory queries (Meena, tea, garden, memories)
    if (query.contains('meena') ||
        query.contains('मीना') ||
        query.contains('মিনা')) {
      if (lang == 'hi') {
        return {
          'action': 'NAVIGATE_MEMORY',
          'actionLabel': 'यादें देखें',
          'response': 'मीना आपकी प्यारी पोती हैं! वह आपके साथ कहानियों की किताबें पढ़ना पसंद करती हैं और बगीचे से सुंदर पीले गेंदे के फूल लाई थीं।'
        };
      } else if (lang == 'as') {
        return {
          'action': 'NAVIGATE_MEMORY',
          'actionLabel': 'স্মৃতি চাওক',
          'response': 'মিনা আপোনাৰ মৰমৰ নাতিনী! তাই আপোনাৰ লগত সাধুকথাৰ কিতাপ পঢ়িবলৈ ভাল পায় আৰু বাগানৰ পৰা হালধীয়া ফুল আনিছিল।'
        };
      } else {
        return {
          'action': 'NAVIGATE_MEMORY',
          'actionLabel': 'Open Memory Album',
          'response': 'Meena is your loving granddaughter! She loves reading storybooks with you and brought lovely yellow marigolds from the garden.'
        };
      }
    }

    if (query.contains('memory') ||
        query.contains('memories') ||
        query.contains('album') ||
        query.contains('याद') ||
        query.contains('স্মৃতি')) {
      if (lang == 'hi') {
        return {
          'action': 'NAVIGATE_MEMORY',
          'actionLabel': 'मेरी यादें',
          'response': 'आपकी यादों में मीना (पोती), असम इलायची चाय, सामने का बगीचा और शाम का रेडियो संगीत सहेजे गए हैं।'
        };
      } else if (lang == 'as') {
        return {
          'action': 'NAVIGATE_MEMORY',
          'actionLabel': 'মোৰ স্মৃতি',
          'response': 'আপোনাৰ স্মৃতিৰ এলবামত মিনা, অসম ইলাচি চাহ, বাৰান্দাৰ বাগান আৰু সন্ধিয়াৰ ৰেডিঅ’ সংগীত সাঁচি থোৱা আছে।'
        };
      } else {
        return {
          'action': 'NAVIGATE_MEMORY',
          'actionLabel': 'My Memory',
          'response': 'Your memory album has warm memories of Meena (Granddaughter), Assam Cardamom Tea, Front Porch Garden, and Evening Radio Music.'
        };
      }
    }

    // 7. Mood
    if (query.contains('mood') ||
        query.contains('feeling') ||
        query.contains('मूड') ||
        query.contains('मन')) {
      if (lang == 'hi') {
        return {
          'action': 'NAVIGATE_MOOD',
          'actionLabel': 'मूड ट्रैक करें',
          'response': 'आज आपका मूड शांत और प्रसन्न दर्ज किया गया है। गहरी और शांत साँसें लेते रहें।'
        };
      } else if (lang == 'as') {
        return {
          'action': 'NAVIGATE_MOOD',
          'actionLabel': 'মনৰ অৱস্থা',
          'response': 'আজি আপোনাৰ মন শান্ত বুলি চিহ্নিত কৰা হৈছে। প্ৰশান্তিৰে উশাহ লওক আৰু হাঁহি থাকক।'
        };
      } else {
        return {
          'action': 'NAVIGATE_MOOD',
          'actionLabel': 'Check Mood',
          'response': 'You recorded feeling Calm and Peaceful today. Gentle music and deep breaths will keep you refreshed!'
        };
      }
    }

    // 8. Routine / What should I do today
    if (query.contains('what should i do') ||
        query.contains('today') ||
        query.contains('routine') ||
        query.contains('schedule') ||
        query.contains('क्या करूँ') ||
        query.contains('কি কৰিম')) {
      if (lang == 'hi') {
        return {
          'action': 'NAVIGATE_GAME',
          'actionLabel': 'मेमोरी मैच खेलें',
          'response': 'नमस्ते $name! आज की योजना: मेमोरी मैच खेलें, 15 मिनट बागवानी करें, और दोपहर 2:00 बजे बीपी की दवा लें।'
        };
      } else if (lang == 'as') {
        return {
          'action': 'NAVIGATE_GAME',
          'actionLabel': 'খেল আৰম্ভ কৰক',
          'response': 'নমস্কাৰ $name! আজিৰ পৰিকল্পনা: মেমৰি মেচ খেলক, ১৫ মিনিট বাগানৰ কাম কৰক, আৰু দুপৰীয়া ২:০০ বজাত ঔষধ লওক।'
        };
      } else {
        return {
          'action': 'NAVIGATE_GAME',
          'actionLabel': 'Start Memory Match',
          'response': 'Hello $name! Here is your plan today: Play Memory Match (Level 3), enjoy 15 mins of Gardening, and take your 2:00 PM medicine.'
        };
      }
    }

    // 9. Non-diagnostic safety guard
    if (query.contains('dementia') ||
        query.contains('alzheimer') ||
        query.contains('sick') ||
        query.contains('illness') ||
        query.contains('डिमेंशिया') ||
        query.contains('अल्जाइमर')) {
      if (lang == 'hi') {
        return {
          'action': null,
          'response': 'मैं आपकी याददाश्त साथी हूँ और खुशियों भरे खेल कराती हूँ। स्वास्थ्य संबंधी प्रश्नों के लिए आपके देखभालकर्ता और चिकित्सक सदैव उपस्थित हैं।'
        };
      } else if (lang == 'as') {
        return {
          'action': null,
          'response': 'মই আপোনাৰ স্মৃতি সংগী। কোনো স্বাস্থ্য সম্বন্ধীয় প্ৰশ্নৰ বাবে আপোনাৰ পৰিচৰ্যা কৰোঁতা আৰু ডাক্তৰ সদায় সাজু আছে।'
        };
      } else {
        return {
          'action': null,
          'response': 'I am your memory companion here to support you with fun activities. For any medical questions, your caregiver and doctor are always here to support you.'
        };
      }
    }

    // Default friendly response
    if (lang == 'hi') {
      return {
        'action': null,
        'response': 'नमस्ते $name! मैं निया हूँ, आपकी याददाश्त साथी। आप मुझसे रिमाइंडर, खेल, गतिविधियाँ, या अपनी यादों के बारे में पूछ सकते हैं।'
      };
    } else if (lang == 'as') {
      return {
        'action': null,
        'response': 'নমস্কাৰ $name! মই নিয়া, আপোনাৰ স্মৃতি সংগী। আপুনি মোক সোঁৱৰণী, খেল, কাৰ্য্যকলাপ, বা স্মৃতিৰ বিষয়ে সুধিব পাৰে।'
      };
    } else {
      return {
        'action': null,
        'response': 'Hello $name! I am Nia, your memory companion. You can ask me "What reminders do I have?", "What game should I play?", or "Show my progress".'
      };
    }
  }
}
