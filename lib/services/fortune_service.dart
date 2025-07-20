import 'dart:convert';
import 'package:http/http.dart' as http;

class FortuneService {
  static const String baseUrl = 'http://localhost:5000'; // AI 서비스 URL

  /// OpenAI를 사용해서 개인화된 운세를 생성합니다.
  static Future<String?> generateFortune(String birthday) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fortune?birthday=$birthday'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['fortune'];
      } else {
        print('운세 생성 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('운세 생성 중 오류 발생: $e');
      return null;
    }
  }

  /// 오프라인용 기본 운세 (API 연결 실패 시 사용)
  static String getDefaultFortune(DateTime birthday) {
    final today = DateTime.now();
    final birthMonth = birthday.month;
    final birthDay = birthday.day;
    final todayNumber = today.day + birthMonth + birthDay;
    
    final fortunes = [
      "오늘은 새로운 기회가 찾아올 수 있는 날입니다. 열린 마음으로 하루를 시작해보세요! ✨",
      "소중한 사람과의 만남이나 연락이 있을 것 같아요. 따뜻한 마음으로 대화해보세요 💕",
      "창의적인 아이디어가 떠오르는 날이에요. 새로운 것을 시도해보는 것도 좋겠어요 🎨",
      "조금 조심스러운 하루가 될 수 있어요. 신중하게 판단하시고 무리하지 마세요 🤗",
      "행운이 함께하는 날입니다! 긍정적인 마음가짐으로 하루를 보내세요 🍀",
      "평온하고 안정적인 하루가 될 것 같아요. 여유로운 마음으로 하루를 즐겨보세요 🌸",
      "새로운 배움이나 깨달음이 있을 수 있는 날이에요. 호기심을 가지고 하루를 보내세요 📚",
      "주변 사람들과의 관계가 더욱 돈독해질 것 같아요. 감사하는 마음을 표현해보세요 💝"
    ];
    
    return fortunes[todayNumber % fortunes.length];
  }
} 