import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  static const String baseUrl = 'http://10.0.2.2:8002';

  /// 일기 내용을 분석하고 위로 메시지 생성
  static Future<String?> analyzeDiary(String date, String content) async {
    try {
      print('일기 분석 요청: $date - ${content.substring(0, content.length > 50 ? 50 : content.length)}...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/diary/analyze'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'date': date,
          'text': content,
        }),
      );

      print('일기 분석 응답 상태: ${response.statusCode}');
      print('일기 분석 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['message'];
      } else {
        print('일기 분석 실패: ${response.statusCode}');
        print('응답 내용: ${response.body}');
        return null;
      }
    } catch (e) {
      print('일기 분석 중 오류 발생: $e');
      return null;
    }
  }

  /// 서비스 상태 확인
  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      print('OpenAI 서비스 연결 오류: $e');
      return false;
    }
  }
} 