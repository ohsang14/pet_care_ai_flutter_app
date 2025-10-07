import 'package:flutter/material.dart';
// 1. 방금 만든 login_screen.dart 파일을 가져옵니다.

import 'login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // 2. home을 LoginScreen()으로 변경합니다.
      home: LoginScreen(),
    );
  }
}