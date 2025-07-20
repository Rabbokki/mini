import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme.dart';
import '../ui/button.dart';
import '../ui/card.dart';
import '../ui/input.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  bool showPassword = false;
  String email = '';
  String password = '';
  String confirmPassword = '';
  String name = '';
  String birthday = '';
  String errorMessage = '';

  final _formKey = GlobalKey<FormState>();

  Future<void> handleLogin() async {
    setState(() { errorMessage = ''; });
    try {
      print('로그인 시도: $email');
      print('API URL: http://192.168.0.12:8000/auth/login');
      
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      print('응답 상태 코드: ${response.statusCode}');
      print('응답 내용: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // JWT 토큰 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access_token']);
        
        // 사용자 정보 저장
        if (data['user_info'] != null) {
          await prefs.setString('user_id', data['user_info']['id'].toString());
          await prefs.setString('username', data['user_info']['username']);
          await prefs.setString('email', data['user_info']['email']);
          if (data['user_info']['birthday'] != null) {
            await prefs.setString('birthday', data['user_info']['birthday']);
          }
        }
        
        // AppState에 로그인 상태 업데이트
        final appState = Provider.of<AppState>(context, listen: false);
        appState.handleLogin();
      } else {
        final data = jsonDecode(response.body);
        setState(() { errorMessage = data['detail'] ?? '로그인 실패'; });
      }
    } catch (e) {
      print('로그인 에러: $e');
      setState(() { errorMessage = '서버 연결 실패: $e'; });
    }
  }

  Future<void> handleRegister() async {
    setState(() { errorMessage = ''; });
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': name,
          'email': email,
          'password': password,
          'birthday': birthday,
        }),
      );
      if (response.statusCode == 200) {
        // 회원가입 성공 시 자동 로그인 처리
        await handleLogin();
      } else {
        final data = jsonDecode(response.body);
        setState(() { errorMessage = data['detail'] ?? '회원가입 실패'; });
      }
    } catch (e) {
      print('회원가입 에러: $e');
      setState(() { errorMessage = '서버 연결 실패: $e'; });
    }
  }

  void handleSubmit() {
    if (_formKey.currentState!.validate()) {
      if (isLogin) {
        handleLogin();
      } else {
        handleRegister();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // bg-background
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // p-4
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448), // max-w-md
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Title
                Column(
                  children: [
                    Text(
                      '하루그램',
                      style: TextStyle(
                        fontSize: 30.0, // text-3xl
                        fontWeight: FontWeight.bold,
                        color: AppColors.foreground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8), // mb-2
                    Text(
                      '매일의 감정을 기록하고 분석해보세요',
                      style: TextStyle(
                        color: AppColors.mutedForeground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 32), // mb-8

                // Auth Form Card
                Container(
                  padding: const EdgeInsets.all(32.0), // p-8
                  decoration: BoxDecoration(
                    color: AppColors.calendarBg, // bg-calendar-bg
                    border: Border.all(color: AppColors.border), // border-border
                    borderRadius: BorderRadius.circular(24.0), // rounded-3xl
                  ),
                  child: Column(
                    children: [
                      // Toggle Buttons
                      Container(
                        padding: const EdgeInsets.all(4.0), // p-1
                        decoration: BoxDecoration(
                          color: AppColors.calendarDateBg, // bg-calendar-date-bg
                          borderRadius: BorderRadius.circular(16.0), // rounded-2xl
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => isLogin = true),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200), // transition-colors
                                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // py-2 px-4
                                  decoration: BoxDecoration(
                                    color: isLogin ? AppColors.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12.0), // rounded-xl
                                  ),
                                  child: Text(
                                    '로그인',
                                    style: TextStyle(
                                      fontSize: 14.0, // text-sm
                                      fontWeight: FontWeight.w500, // font-medium
                                      color: isLogin 
                                          ? AppColors.primaryForeground 
                                          : AppColors.mutedForeground,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => isLogin = false),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                  decoration: BoxDecoration(
                                    color: !isLogin ? AppColors.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Text(
                                    '회원가입',
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w500,
                                      color: !isLogin 
                                          ? AppColors.primaryForeground 
                                          : AppColors.mutedForeground,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24), // space-y-6

                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Name field for signup
                            if (!isLogin) ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '이름',
                                    style: TextStyle(
                                      color: AppColors.foreground,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8), // space-y-2
                                  TextFormField(
                                    onChanged: (value) => name = value,
                                    decoration: InputDecoration(
                                      hintText: '이름을 입력하세요',
                                      fillColor: AppColors.calendarDateBg, // bg-calendar-date-bg
                                      filled: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6.0),
                                        borderSide: BorderSide(color: AppColors.border), // border-border
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6.0),
                                        borderSide: BorderSide(color: AppColors.border),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6.0),
                                        borderSide: BorderSide(color: AppColors.border, width: 2.0),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return '이름을 입력해주세요';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16), // space-y-4
                            ],

                            // Birthday field for signup
                            if (!isLogin) ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '생일',
                                    style: TextStyle(
                                      color: AppColors.foreground,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(

                                    onChanged: (value) => birthday = value,
                                    decoration: InputDecoration(
                                      hintText: 'YYYY-MM-DD (예: 1990-01-01)',
                                      fillColor: AppColors.calendarDateBg,
                                      filled: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6.0),
                                        borderSide: BorderSide(color: AppColors.border),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6.0),
                                        borderSide: BorderSide(color: AppColors.border),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6.0),
                                        borderSide: BorderSide(color: AppColors.border, width: 2.0),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {

                                        return '생일을 입력해주세요';
                                      }
                                      // YYYY-MM-DD 형식 검증
                                      final RegExp dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                                      if (!dateRegex.hasMatch(value)) {
                                        return 'YYYY-MM-DD 형식으로 입력해주세요';
                                      }
                                      try {
                                        final date = DateTime.parse(value);
                                        final now = DateTime.now();
                                        if (date.isAfter(now)) {
                                          return '미래 날짜는 입력할 수 없습니다';
                                        }
                                        if (date.year < 1900) {
                                          return '1900년 이후의 날짜를 입력해주세요';
                                        }
                                      } catch (e) {
                                        return '올바른 날짜를 입력해주세요';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                            ],

                            // Email field
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '이메일',
                                  style: TextStyle(
                                    color: AppColors.foreground,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  onChanged: (value) => email = value,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    hintText: '이메일을 입력하세요',
                                    fillColor: AppColors.calendarDateBg,
                                    filled: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6.0),
                                      borderSide: BorderSide(color: AppColors.border),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6.0),
                                      borderSide: BorderSide(color: AppColors.border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6.0),
                                      borderSide: BorderSide(color: AppColors.border, width: 2.0),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '이메일을 입력해주세요';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Password field
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '비밀번호',
                                  style: TextStyle(
                                    color: AppColors.foreground,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  onChanged: (value) => password = value,
                                  obscureText: !showPassword,
                                  onFieldSubmitted: (_) => handleSubmit(),
                                  decoration: InputDecoration(
                                    hintText: '비밀번호를 입력하세요',
                                    fillColor: AppColors.calendarDateBg,
                                    filled: true,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        showPassword ? Icons.visibility_off : Icons.visibility,
                                        color: AppColors.mutedForeground,
                                        size: 16,
                                      ),
                                      onPressed: () => setState(() => showPassword = !showPassword),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6.0),
                                      borderSide: BorderSide(color: AppColors.border),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6.0),
                                      borderSide: BorderSide(color: AppColors.border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6.0),
                                      borderSide: BorderSide(color: AppColors.border, width: 2.0),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '비밀번호를 입력해주세요';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password field for signup
                            if (!isLogin) ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '비밀번호 확인',
                                    style: TextStyle(
                                      color: AppColors.foreground,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    onChanged: (value) => confirmPassword = value,
                                    obscureText: !showPassword,
                                    onFieldSubmitted: (_) => handleSubmit(),
                                    decoration: InputDecoration(
                                      hintText: '비밀번호를 다시 입력하세요',
                                      fillColor: AppColors.calendarDateBg,
                                      filled: true,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          showPassword ? Icons.visibility_off : Icons.visibility,
                                          color: AppColors.mutedForeground,
                                          size: 16,
                                        ),
                                        onPressed: () => setState(() => showPassword = !showPassword),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6.0),
                                        borderSide: BorderSide(color: AppColors.border),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6.0),
                                        borderSide: BorderSide(color: AppColors.border),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6.0),
                                        borderSide: BorderSide(color: AppColors.border, width: 2.0),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {

                                        return '비밀번호 확인을 입력해주세요';
                                      }
                                      if (value != password) {
                                        return '비밀번호가 일치하지 않습니다';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Submit Button
                            SizedBox(
                              width: double.infinity, // w-full
                              child: ElevatedButton(
                                onPressed: handleSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary, // bg-primary
                                  foregroundColor: AppColors.primaryForeground, // text-primary-foreground
                                  padding: const EdgeInsets.symmetric(vertical: 12.0), // py-3
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.0), // rounded-2xl
                                  ),
                                ),
                                child: Text(
                                  isLogin ? '로그인' : '회원가입',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500, // font-medium
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            errorMessage,
                            style: TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24), // mt-6

                // Footer
                Text(
                  '하루그램과 함께 건강한 마음 관리를 시작해보세요',
                  style: TextStyle(
                    fontSize: 14.0, // text-sm
                    color: AppColors.mutedForeground,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 