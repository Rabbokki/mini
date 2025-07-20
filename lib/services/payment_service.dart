import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../components/payment_webview.dart';

class PaymentService {
  // 포트원 REST API 키와 시크릿
  static const String _restApiKey = '8266201362865180';  // REST API 키
  static const String _restApiSecret = 'CO2ouD8rGkcOcUc99QTznben0b7fKBJAuJAIvoLUv8OkW0Yz0284Wg8bLnaDdBMLzSNKfju3JI2K05lF';  // REST API Secret
  static const String _baseUrl = 'https://api.iamport.kr';
  static const String _impCode = 'imp31685584';  // 고객사 식별코드

  // 결제 토큰 발급
  static Future<String> getAccessToken() async {
    try {
      print('토큰 발급 요청 시작...');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/users/getToken'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'imp_key': _restApiKey,
          'imp_secret': _restApiSecret,
        }),
      );

      print('토큰 발급 응답 상태: ${response.statusCode}');
      print('토큰 발급 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 0) {
          final accessToken = data['response']['access_token'];
          print('토큰 발급 성공: $accessToken');
          return accessToken;
        } else {
          print('토큰 발급 실패: ${data['message']}');
          throw Exception('토큰 발급 실패: ${data['message']}');
        }
      } else {
        print('토큰 발급 HTTP 오류: ${response.statusCode}');
        throw Exception('토큰 발급 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('토큰 발급 예외: $e');
      throw Exception('토큰 발급 중 오류: $e');
    }
  }

  // 결제 예약 (결제창 띄우기 전에 미리 예약)
  static Future<Map<String, dynamic>> preparePayment({
    required String merchantUid,
    required int amount,
    required String name,
    String? buyerEmail,
    String? buyerName,
  }) async {
    try {
      print('결제 예약 시작... merchant_uid: $merchantUid, amount: $amount');
      
      final accessToken = await getAccessToken();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/payments/prepare'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'merchant_uid': merchantUid,
          'amount': amount,
          'name': name,
        }),
      );

      print('결제 예약 응답 상태: ${response.statusCode}');
      print('결제 예약 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 0) {
          print('결제 예약 성공');
          return {
            'success': true,
            'merchant_uid': merchantUid,
            'amount': amount,
          };
        } else {
          print('결제 예약 실패: ${data['message']}');
          throw Exception('결제 예약 실패: ${data['message']}');
        }
      } else {
        print('결제 예약 HTTP 오류: ${response.statusCode}');
        throw Exception('결제 예약 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('결제 예약 예외: $e');
      throw Exception('결제 예약 중 오류: $e');
    }
  }

  // WebView로 결제창 띄우기
  static Future<Map<String, dynamic>> requestPayment({
    required BuildContext context,
    required String merchantUid,
    required int amount,
    required String name,
    required String buyerEmail,
    required String buyerName,
  }) async {
    try {
      print('WebView 결제창 시작... merchant_uid: $merchantUid, amount: $amount');
      
      // 1. 결제 예약 (실패해도 계속 진행)
      try {
        await preparePayment(
          merchantUid: merchantUid,
          amount: amount,
          name: name,
          buyerEmail: buyerEmail,
          buyerName: buyerName,
        );
        print('결제 예약 성공');
      } catch (e) {
        print('결제 예약 실패했지만 계속 진행: $e');
      }

      // 2. WebView로 결제창 띄우기
      if (!context.mounted) {
        throw Exception('Context가 더 이상 유효하지 않습니다.');
      }
      
      print('PaymentWebView 띄우기 시작...');
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) => PaymentWebView(
            name: name,
            amount: amount,
            buyerEmail: buyerEmail,
            buyerName: buyerName,
          ),
        ),
      );

      print('PaymentWebView 결과: $result');
      if (result == 'success') {
        return {
          'success': true,
          'merchant_uid': merchantUid,
          'amount': amount,
        };
      } else {
        return {
          'success': false,
          'error': '결제가 취소되었습니다.',
        };
      }
    } catch (e) {
      print('WebView 결제 예외: $e');
      throw Exception('WebView 결제 중 오류: $e');
    }
  }

  // 결제 검증 (결제 완료 후 서버에서 검증)
  static Future<Map<String, dynamic>> verifyPayment({
    required String impUid,
    required String merchantUid,
    required int amount,
  }) async {
    try {
      print('결제 검증 시작... imp_uid: $impUid, merchant_uid: $merchantUid');
      
      final accessToken = await getAccessToken();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/payments/$impUid'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('결제 검증 응답 상태: ${response.statusCode}');
      print('결제 검증 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 0) {
          final paymentData = data['response'];
          
          // 결제 검증
          if (paymentData['merchant_uid'] == merchantUid &&
              paymentData['amount'] == amount &&
              paymentData['status'] == 'paid') {
            print('결제 검증 성공');
            return {
              'success': true,
              'payment_data': paymentData,
            };
          } else {
            print('결제 검증 실패: 정보 불일치');
            throw Exception('결제 검증 실패: 정보 불일치');
          }
        } else {
          print('결제 조회 실패: ${data['message']}');
          throw Exception('결제 조회 실패: ${data['message']}');
        }
      } else {
        print('결제 조회 HTTP 오류: ${response.statusCode}');
        throw Exception('결제 조회 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('결제 검증 예외: $e');
      throw Exception('결제 검증 중 오류: $e');
    }
  }

  // 고유한 merchant_uid 생성
  static String generateMerchantUid() {
    final now = DateTime.now();
    final random = Random();
    final randomNum = random.nextInt(10000).toString().padLeft(4, '0');
    return '${now.millisecondsSinceEpoch}_$randomNum';
  }

  // 결제 취소
  static Future<bool> cancelPayment({
    required String impUid,
    required String reason,
  }) async {
    try {
      print('결제 취소 시작... imp_uid: $impUid');
      
      final accessToken = await getAccessToken();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/payments/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'imp_uid': impUid,
          'reason': reason,
        }),
      );

      print('결제 취소 응답 상태: ${response.statusCode}');
      print('결제 취소 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final success = data['code'] == 0;
        print('결제 취소 결과: $success');
        return success;
      } else {
        print('결제 취소 HTTP 오류: ${response.statusCode}');
        throw Exception('결제 취소 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('결제 취소 예외: $e');
      throw Exception('결제 취소 중 오류: $e');
    }
  }

  // WebView 결제를 위한 URL 생성 (나중에 WebView 구현 시 사용)
  static String generatePaymentUrl({
    required String merchantUid,
    required int amount,
    required String name,
    required String buyerEmail,
    required String buyerName,
  }) {
    // 포트원 결제창 URL 생성
    final params = {
      'imp_key': _restApiKey,
      'merchant_uid': merchantUid,
      'amount': amount.toString(),
      'name': name,
      'buyer_email': buyerEmail,
      'buyer_name': buyerName,
    };
    
    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return 'https://www.iamport.kr/payment?$queryString';
  }
} 