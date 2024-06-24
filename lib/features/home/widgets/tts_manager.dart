import 'package:flutter_tts/flutter_tts.dart';

class TtsManager {
  final FlutterTts _flutterTts = FlutterTts();
  bool isSpeaking = false;

  TtsManager() {
    _flutterTts.setStartHandler(() {
      isSpeaking = true;
    });

    _flutterTts.setCompletionHandler(() {
      isSpeaking = false;
    });

    _flutterTts.setErrorHandler((msg) {
      isSpeaking = false;
    });
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  void setStartHandler(void Function() handler) {
    _flutterTts.setStartHandler(handler);
  }

  void setCompletionHandler(void Function() handler) {
    _flutterTts.setCompletionHandler(handler);
  }
}
