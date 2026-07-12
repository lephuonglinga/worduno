import 'package:flutter_tts/flutter_tts.dart';

class TtsHelper {
  TtsHelper._();

  static final FlutterTts _tts = FlutterTts();

  /// Speaks [text]. Returns `true` on success, `false` if TTS fails.
  static Future<bool> speak(String text) async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      final result = await _tts.speak(text);
      if (result is int) {
        return result == 1;
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
