import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserSettingsService {
  static const String baseUrl = 'http://localhost:8000/api';
  
  // 사용자 설정 모델
  static Map<String, dynamic> defaultSettings = {
    'emoticon_enabled': true,
    'voice_enabled': true,
    'voice_volume': 50,
    'emoticon_categories': {
      'shape': ['⭐', '🔶', '🔷', '⚫', '🔺'],
      'fruit': ['🍎', '🍊', '🍌', '🍇', '🍓'],
      'animal': ['🐶', '🐱', '🐰', '🐸', '🐼'],
      'weather': ['☀️', '🌧️', '⛈️', '🌈', '❄️']
    },
    'last_selected_emotion_category': 'shape'
  };

  // 사용자 설정 가져오기
  static Future<Map<String, dynamic>> getUserSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token == null) {
        throw Exception('토큰이 없습니다');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user-settings/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? '설정을 가져오는데 실패했습니다');
        }
      } else if (response.statusCode == 401) {
        throw Exception('인증에 실패했습니다');
      } else {
        throw Exception('서버 오류가 발생했습니다');
      }
    } catch (e) {
      print('사용자 설정 가져오기 오류: $e');
      // 오류 발생 시 기본 설정 반환
      return defaultSettings;
    }
  }

  // 사용자 설정 업데이트
  static Future<Map<String, dynamic>> updateUserSettings({
    bool? emoticonEnabled,
    bool? voiceEnabled,
    int? voiceVolume,
    Map<String, List<String>>? emoticonCategories,
    String? lastSelectedEmotionCategory,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token == null) {
        throw Exception('토큰이 없습니다');
      }

      final updateData = <String, dynamic>{};
      if (emoticonEnabled != null) updateData['emoticon_enabled'] = emoticonEnabled;
      if (voiceEnabled != null) updateData['voice_enabled'] = voiceEnabled;
      if (voiceVolume != null) updateData['voice_volume'] = voiceVolume;
      if (emoticonCategories != null) updateData['emoticon_categories'] = emoticonCategories;
      if (lastSelectedEmotionCategory != null) updateData['last_selected_emotion_category'] = lastSelectedEmotionCategory;

      final response = await http.put(
        Uri.parse('$baseUrl/user-settings/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? '설정 업데이트에 실패했습니다');
        }
      } else if (response.statusCode == 401) {
        throw Exception('인증에 실패했습니다');
      } else {
        throw Exception('서버 오류가 발생했습니다');
      }
    } catch (e) {
      print('사용자 설정 업데이트 오류: $e');
      throw e;
    }
  }

  // 이모티콘 카테고리 업데이트
  static Future<Map<String, dynamic>> updateEmoticonCategories(
    Map<String, List<String>> categories,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token == null) {
        throw Exception('토큰이 없습니다');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/user-settings/emoticon-categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(categories),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? '이모티콘 카테고리 업데이트에 실패했습니다');
        }
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['detail'] ?? '잘못된 요청입니다');
      } else if (response.statusCode == 401) {
        throw Exception('인증에 실패했습니다');
      } else {
        throw Exception('서버 오류가 발생했습니다');
      }
    } catch (e) {
      print('이모티콘 카테고리 업데이트 오류: $e');
      throw e;
    }
  }

  // 사용자 설정 초기화
  static Future<Map<String, dynamic>> resetUserSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token == null) {
        throw Exception('토큰이 없습니다');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/user-settings/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? '설정 초기화에 실패했습니다');
        }
      } else if (response.statusCode == 401) {
        throw Exception('인증에 실패했습니다');
      } else {
        throw Exception('서버 오류가 발생했습니다');
      }
    } catch (e) {
      print('사용자 설정 초기화 오류: $e');
      throw e;
    }
  }

  // 로컬에 설정 저장 (오프라인 대응)
  static Future<void> saveSettingsLocally(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_settings', json.encode(settings));
    } catch (e) {
      print('로컬 설정 저장 오류: $e');
    }
  }

  // 로컬에서 설정 불러오기 (오프라인 대응)
  static Future<Map<String, dynamic>> loadSettingsLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('user_settings');
      if (settingsJson != null) {
        return json.decode(settingsJson);
      }
    } catch (e) {
      print('로컬 설정 불러오기 오류: $e');
    }
    return defaultSettings;
  }
} 