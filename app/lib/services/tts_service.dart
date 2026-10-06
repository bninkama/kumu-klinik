import 'package:flutter_tts/flutter_tts.dart';

// Text-to-speech. There is no dedicated Tok Pisin voice; we use an
// English voice slowed down, which PNG users generally understand well.
class TtsService {
  static final FlutterTts _tts = FlutterTts();
  static bool _ready = false;

  static Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.42); // slower for field use
    await _tts.setVolume(1.0);
    _ready = true;
  }

  static Future<void> speak(String text) async {
    if (!_ready) await init();
    await _tts.stop();
    await _tts.speak(text);
  }

  static Future<void> stop() => _tts.stop();
}
