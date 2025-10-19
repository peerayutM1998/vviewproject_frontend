import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  Future<void> initializeTts(void Function(String) onError) async {
    _flutterTts = FlutterTts();
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
    });
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });
    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      onError('เกิดข้อผิดพลาดในการเล่นเสียง: $msg');
    });
  }

  bool isThai(String text) {
    final thaiRegex = RegExp(r'[\u0E00-\u0E7F]');
    return thaiRegex.hasMatch(text);
  }

  Future<void> speakText(String text, void Function(String) onError) async {
    if (text.isEmpty || text == 'ไม่พบข้อความ') {
      onError('ไม่มีข้อความให้อ่าน');
      return;
    }

    try {
      if (isThai(text)) {
        await _flutterTts.setLanguage("th-TH");
      } else {
        await _flutterTts.setLanguage("en-US");
      }
      await _flutterTts.speak(text);
    } catch (e) {
      onError('เกิดข้อผิดพลาดในการเล่นเสียง: $e');
    }
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
    _isSpeaking = false;
  }

  void dispose() {
    _flutterTts.stop();
  }
}