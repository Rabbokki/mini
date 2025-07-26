import 'dart:convert';
import 'package:http/http.dart' as http;

class TTSService {
  static const String baseUrl = 'http://10.0.2.2:8002';

  /// 텍스트를 음성으로 변환
  static Future<String?> textToSpeech(String text) async {
    try {
      print('TTS 요청: $text');
      
      final response = await http.get(
        Uri.parse('$baseUrl/tts?text=${Uri.encodeComponent(text)}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('TTS 응답 상태: ${response.statusCode}');
      print('TTS 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final audioUrl = data['audio_url'];
        return '$baseUrl$audioUrl';
      } else {
        print('TTS 변환 실패: ${response.statusCode}');
        print('응답 내용: ${response.body}');
        return null;
      }
    } catch (e) {
      print('TTS 변환 중 오류 발생: $e');
      return null;
    }
  }

  /// 서비스 상태 확인
  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/'));
      return response.statusCode == 200;
    } catch (e) {
      print('TTS 서비스 연결 오류: $e');
      return false;
    }
  }
} 