import 'package:firebase_database/firebase_database.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

// 음성 인식 관리자 클래스
class SpeechRecognitionManager {
  final DatabaseReference userRequestRef; // Firebase 데이터베이스 참조 변수
  final stt.SpeechToText _speech = stt.SpeechToText(); // SpeechToText 인스턴스 생성
  bool _isListening = false; // 현재 듣고 있는지 여부를 나타내는 변수
  String _currentSentence = ''; // 현재 인식된 문장을 저장하는 변수

  // 생성자 - Firebase 데이터베이스 참조를 받음
  SpeechRecognitionManager(this.userRequestRef);

  // 음성 인식 초기화 함수
  Future<void> initialize() async {
    // 음성 인식 초기화 및 상태와 오류 핸들러 등록
    bool available = await _speech.initialize(
      onStatus: _onSpeechStatus, // 음성 인식 상태 콜백 함수
      onError: _onSpeechError,   // 음성 인식 오류 콜백 함수
    );
    // 음성 인식이 가능한 경우 듣기 시작
    if (available) {
      _startListening();
    } else {
      print('음성 인식 사용 불가');
    }
  }

  // 음성 듣기 시작 함수
  void _startListening() {
    _speech.listen(
      listenFor: Duration(seconds: 20), // 20초 동안 듣기
      pauseFor: Duration(seconds: 3),   // 3초 동안 멈춤
      onResult: _onSpeechResult, // 결과를 처리할 콜백 함수 등록
      localeId: 'ko_KR',                // 한국어 설정
    );
    _isListening = true; // 듣기 상태 설정
  }

  // 음성 인식 결과를 처리하는 함수
  void _onSpeechResult(SpeechRecognitionResult result) {
    // 최종 결과가 나왔을 때만 처리
    if (result.finalResult) {
      String recognizedText = result.recognizedWords; // 인식된 텍스트 가져오기
      print('인식된 텍스트: $recognizedText');
      _currentSentence = recognizedText; // 인식된 텍스트를 현재 문장에 저장
      _uploadText(_currentSentence.trim()); // 텍스트를 Firebase에 업로드
      _currentSentence = ''; // 현재 문장 초기화
    }
  }

  // 음성 인식 상태를 처리하는 함수
  void _onSpeechStatus(String status) {
    print('음성 상태: $status');
    // 듣기 상태가 'done'인 경우 다시 듣기 시작
    if (status == 'done') {
      _isListening = false;
      _startListening();
    }
  }

  // 음성 인식 오류를 처리하는 함수
  void _onSpeechError(SpeechRecognitionError error) {
    // print('음성 인식 오류: ${error.errorMsg}');
    // 듣기 상태가 'false'인 경우 다시 듣기 시작
    if (_isListening) {
      _isListening = false;
      _startListening();
    }
  }

  // 인식된 텍스트를 Firebase 데이터베이스에 업로드하는 함수
  Future<void> _uploadText(String text) async {
    await userRequestRef.update({'requestText': text});
  }
}
