import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_state.dart';

class DiaryService {
  static const String baseUrl = 'http://192.168.43.129:8001'; // FastAPI 서버 주소

  // 토큰 가져오기 헬퍼 함수
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // 모든 일기 목록 조회
  static Future<List<Map<String, dynamic>>> getDiaryEntries() async {
    try {
      print('일기 목록 조회 API 호출 시작');
      
      final token = await _getToken();
      if (token == null) {
        throw Exception('토큰이 없습니다');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/posts/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('API 응답 상태 코드: ${response.statusCode}');
      print('API 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => {
          'date': item['created_at']?.toString().split('T')[0] ?? '',
          'emotion': item['emotion'] ?? 'shape',
          'emoji': item['emoji'] ?? '⭐',
          'entry': item['content'] ?? '',
          'images': item['images'],
        }).toList();
      } else if (response.statusCode == 401) {
        throw Exception('인증에 실패했습니다');
      } else {
        print('일기 목록 조회 실패: ${response.body}');
        return [];
      }
    } catch (e) {
      print('API 호출 중 에러 발생: $e');
      return [];
    }
  }

  Future<String> createDiary({
    required String content,
    required Emotion emotion,
    List<String>? images,
  }) async {
    try {
      print('일기 저장 API 호출 시작');
      
      final token = await _getToken();
      if (token == null) {
        throw Exception('토큰이 없습니다');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/posts/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'content': content,
          'status': 'published',
          'emotion': emotion.name,  // 감정 정보 추가
          'images': images ?? [],
        }),
      );

      print('API 응답 상태 코드: ${response.statusCode}');
      print('API 응답 내용: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['post_id'];
      } else if (response.statusCode == 401) {
        throw Exception('인증에 실패했습니다');
      } else {
        throw Exception('일기 저장에 실패했습니다: ${response.body}');
      }
    } catch (e) {
      print('API 호출 중 에러 발생: $e');
      throw Exception('일기 저장 중 오류가 발생했습니다: $e');
    }
  }

  Future<Map<String, dynamic>?> getDiaryByDate(String date) async {
    try {
      print('일기 조회 API 호출 시작: $date');
      
      final token = await _getToken();
      if (token == null) {
        throw Exception('토큰이 없습니다');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/posts/date/$date'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('API 응답 상태 코드: ${response.statusCode}');
      print('API 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          // 해당 날짜의 첫 번째 일기 반환
          return {
            'content': data[0]['content'],
            'images': data[0]['images'],
            'created_at': data[0]['created_at'],
          };
        }
        return null; // 해당 날짜의 일기가 없음
      } else if (response.statusCode == 401) {
        throw Exception('인증에 실패했습니다');
      } else {
        throw Exception('일기 조회에 실패했습니다: ${response.body}');
      }
    } catch (e) {
      print('API 호출 중 에러 발생: $e');
      throw Exception('일기 조회 중 오류가 발생했습니다: $e');
    }
  }

  /// 이미지 업로드
  Future<String> uploadImage(File imageFile) async {
    try {
      print('이미지 업로드 API 호출 시작');
      
      final token = await _getToken();
      if (token == null) {
        throw Exception('토큰이 없습니다');
      }
      
      // multipart 요청 생성
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/posts/upload-image'),
      );

      // Authorization 헤더 추가
      request.headers['Authorization'] = 'Bearer $token';

      // 파일 추가
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('이미지 업로드 API 응답 상태 코드: ${response.statusCode}');
      print('이미지 업로드 API 응답 내용: $responseBody');

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return data['filename'];
      } else if (response.statusCode == 401) {
        throw Exception('인증에 실패했습니다');
      } else {
        throw Exception('이미지 업로드에 실패했습니다: $responseBody');
      }
    } catch (e) {
      print('이미지 업로드 API 호출 중 에러 발생: $e');
      throw Exception('이미지 업로드 중 오류가 발생했습니다: $e');
    }
  }

  /// 이미지 삭제
  Future<bool> deleteImage(String filename) async {
    try {
      print('이미지 삭제 API 호출 시작: $filename');
      
      final token = await _getToken();
      if (token == null) {
        throw Exception('토큰이 없습니다');
      }
      
      final response = await http.delete(
        Uri.parse('$baseUrl/api/posts/delete-image/$filename'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('이미지 삭제 API 응답 상태 코드: ${response.statusCode}');
      print('이미지 삭제 API 응답 내용: ${response.body}');

      if (response.statusCode == 401) {
        throw Exception('인증에 실패했습니다');
      }
      
      return response.statusCode == 200;
    } catch (e) {
      print('이미지 삭제 API 호출 중 에러 발생: $e');
      return false;
    }
  }

  /// 일기 수정(업데이트)
  Future<bool> updateDiary({
    required String postId,
    required String content,
    required Emotion emotion,
    List<String>? images,
  }) async {
    try {
      print('일기 수정 API 호출 시작: $postId');
      final token = await _getToken();
      if (token == null) {
        throw Exception('토큰이 없습니다');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/posts/$postId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'content': content,
          'emotion': emotion.name,
          'images': images ?? [],
        }),
      );

      print('일기 수정 API 응답 상태 코드: ${response.statusCode}');
      print('일기 수정 API 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('인증에 실패했습니다');
      } else {
        throw Exception('일기 수정에 실패했습니다: ${response.body}');
      }
    } catch (e) {
      print('일기 수정 API 호출 중 에러 발생: $e');
      throw Exception('일기 수정 중 오류가 발생했습니다: $e');
    }
  }
} 