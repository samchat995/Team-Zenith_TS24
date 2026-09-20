// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

class VoicePlatform {
  static void speak(String text, String lang) {
    try {
      if (js.context.hasProperty('speechSynthesis')) {
        final speechLang = lang == 'hi' ? 'hi-IN' : (lang == 'as' ? 'bn-IN' : 'en-US');
        js.context.callMethod('eval', [
          '''
          (function() {
            try {
              window.speechSynthesis.cancel();
              var utterance = new SpeechSynthesisUtterance(${js.context['JSON'].callMethod('stringify', [text])});
              utterance.lang = '$speechLang';
              utterance.rate = 0.88;
              utterance.pitch = 1.0;
              window.speechSynthesis.speak(utterance);
            } catch(e) {
              console.warn("SpeechSynthesis error:", e);
            }
          })();
          '''
        ]);
      }
    } catch (_) {}
  }

  static void stop() {
    try {
      if (js.context.hasProperty('speechSynthesis')) {
        js.context.callMethod('eval', ['window.speechSynthesis.cancel();']);
      }
    } catch (_) {}
  }

  static bool get isSpeechSupported {
    try {
      return js.context.hasProperty('speechSynthesis');
    } catch (_) {
      return false;
    }
  }
}
