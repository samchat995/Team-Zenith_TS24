import 'package:flutter_tts/flutter_tts.dart';

class VoicePlatform {
  static final FlutterTts _tts = FlutterTts();
  static bool _initialized = false;

  static Future<void> _init() async {
    if (_initialized) return;
    try {
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
      _initialized = true;
    } catch (_) {}
  }

  static Future<void> speak(String text, String lang) async {
    try {
      await _init();
      await _tts.stop();
      String speechLang = "en-US";
      if (lang == "hi") {
        speechLang = "hi-IN";
      } else if (lang == "as") {
        try {
          final isSupported = await _tts.isLanguageAvailable("as-IN");
          speechLang = (isSupported == true || isSupported == 1) ? "as-IN" : "hi-IN";
        } catch (_) {
          speechLang = "hi-IN";
        }
      }
      await _tts.setLanguage(speechLang);
      await _tts.speak(text);
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  static bool get isSpeechSupported => true;
}
