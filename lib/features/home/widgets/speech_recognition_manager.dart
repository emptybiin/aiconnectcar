import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:get/get.dart';
import '../../../theme_controller.dart';

class SpeechRecognitionManager {
  final DatabaseReference userRequestRef;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _currentSentence = '';
  bool _uploadState = false; // 앱 내 변수

  SpeechRecognitionManager(this.userRequestRef);

  Future<void> initialize(BuildContext context) async {
    print('Initializing SpeechRecognitionManager...');
    bool available = await _speech.initialize(
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
    );
    if (available) {
      print('Speech recognition available.');
      _startListening(); // 초기화 후 듣기 시작
    } else {
      print('Speech recognition not available.');
    }
  }

  void _startListening() {
    print('Starting to listen...');
    userRequestRef.child('standbyState').once().then((snapshot) {
      String standbyState = (snapshot.snapshot.value ?? '0') as String; // null인 경우 기본값 '0' 사용
      print('Standby state: $standbyState');
      final ThemeController themeController = Get.find();
      if (standbyState == '1') {
        themeController.changeTheme(Colors.blueAccent);
        print('Theme changed to blueAccent');
      } else {
        themeController.changeTheme(Colors.red);
        print('Theme changed to red');
      }

      _speech.listen(
        onResult: _onSpeechResult,
        listenFor: Duration(seconds: 20),
        pauseFor: Duration(seconds: 5),
        localeId: 'ko_KR',
      );
      _isListening = true;
      print('Listening...');
    }).catchError((error) {
      print('Error getting standbyState: $error');
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (result.finalResult) {
      String recognizedText = result.recognizedWords;
      print('Recognized text: $recognizedText');
      _currentSentence = recognizedText;
      _uploadState = true;
      _uploadText(_currentSentence.trim());
    }
  }

  void _onSpeechStatus(String status) {
    print('Speech status: $status');

    if (status == 'done') {
      _isListening = false;
      if (!_uploadState) {
        _startListening(); // 재시작
      }
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    print('Speech recognition error: ${error.errorMsg}');
    _isListening = false;
    if (!_uploadState) {
      _startListening(); // 재시작
    }
  }

  Future<void> _uploadText(String text) async {
    print('Uploading text: $text');
    await userRequestRef.update({'requestText': text}).then((_) {
      print('Text uploaded successfully');
      userRequestRef.child('requestState').once().then((snapshot) {
        String requestState = (snapshot.snapshot.value ?? '0') as String; // null인 경우 기본값 '0' 사용
        print('Request state: $requestState');
        if (requestState == '1') {
          _uploadState = false; // 업로드 상태 초기화
          userRequestRef.update({
            'standbyState': '0',
            'requestState': '0',
          }).then((_) {
            print('Upload state and standby state reset.');
            _startListening(); // 업로드 후 다시 듣기 시작
          }).catchError((error) {
            print('Error resetting states: $error');
            _startListening(); // 오류 발생 시에도 다시 리스닝 시작
          });
        } else {
          // requestState가 1이 아닌 경우에도 다시 리스닝을 시작하도록 추가
          _uploadState = false;
          _startListening();
        }
      }).catchError((error) {
        print('Error getting requestState: $error');
        _uploadState = false;
        _startListening(); // 오류 발생 시에도 다시 리스닝 시작
      });
    }).catchError((error) {
      print('Error uploading text: $error');
      _uploadState = false;
      _startListening(); // 오류 발생 시에도 다시 리스닝 시작
    });
  }

  void setUploadState(bool state) {
    print('Setting uploadState to: $state');
    _uploadState = state;
    print('_uploadState is now: $_uploadState');
    if (_uploadState) {
      _uploadText(_currentSentence.trim()); // 업로드 상태가 true인 경우 텍스트 업로드
    }
  }
}
