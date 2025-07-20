import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String baseUrl = 'http://localhost:8000/api';

  // 사용자 생일 정보 업데이트
  static Future<bool> updateUserBirthday(String userId, DateTime birthday) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/auth/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'birthday': '${birthday.year}-${birthday.month.toString().padLeft(2, '0')}-${birthday.day.toString().padLeft(2, '0')}',
        }),
      );

      if (response.statusCode == 200) {
        print('생일 정보 업데이트 성공');
        return true;
      } else {
        print('생일 정보 업데이트 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('생일 정보 업데이트 중 오류: $e');
      return false;
    }
  }

  // 사용자 정보 조회
  static Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/users/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('사용자 정보 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('사용자 정보 조회 중 오류: $e');
      return null;
    }
  }

  // 사용자 프로필 조회
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token == null) {
        print('액세스 토큰이 없습니다.');
        return null;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/auth/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('사용자 프로필 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('사용자 프로필 조회 중 오류: $e');
      return null;
    }
  }

  // 생일 문자열 파싱
  static DateTime? parseBirthday(String? birthdayStr) {
    if (birthdayStr == null || birthdayStr.isEmpty) {
      return null;
    }
    try {
      return DateTime.parse(birthdayStr);
    } catch (e) {
      print('생일 파싱 오류: $e');
      return null;
    }
  }

  // 생일 포맷팅
  static String formatBirthday(DateTime? birthday) {
    if (birthday == null) {
      return '';
    }
    return '${birthday.year}-${birthday.month.toString().padLeft(2, '0')}-${birthday.day.toString().padLeft(2, '0')}';
  }

  // 사용자 프로필 업데이트
  static Future<bool> updateUserProfile({
    String? name,
    String? email,
    DateTime? birthday,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token == null) {
        print('액세스 토큰이 없습니다.');
        return false;
      }

      final Map<String, dynamic> updateData = {};
      if (name != null) updateData['name'] = name;
      if (email != null) updateData['email'] = email;
      if (birthday != null) updateData['birthday'] = formatBirthday(birthday);

      final response = await http.put(
        Uri.parse('$baseUrl/auth/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        print('사용자 프로필 업데이트 성공');
        return true;
      } else {
        print('사용자 프로필 업데이트 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('사용자 프로필 업데이트 중 오류: $e');
      return false;
    }
  }
} 