import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/index_page.dart';
import 'models/app_state.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const IndexPage(), // 직접 IndexPage를 반환
    );
  }
} 