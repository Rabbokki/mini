import 'package:flutter/material.dart';
import 'app.dart';
import 'theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diary App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,  // CSS 스타일이 적용된 라이트 테마
      darkTheme: AppTheme.darkTheme,  // CSS 스타일이 적용된 다크 테마
      themeMode: ThemeMode.system,  // 시스템 설정에 따라 자동 전환
      home: const App(),  // App 위젯 사용
    );
  }
}

 