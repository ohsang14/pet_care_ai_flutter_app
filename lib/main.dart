import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'login_screen.dart';

void main() {
  KakaoSdk.init(nativeAppKey: '9b11ffc9a57e419c6f691d892ca997aa');

  runApp(const PetCareApp());
}

class PetCareApp extends StatelessWidget {
  const PetCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetCare AI',
      debugShowCheckedModeBanner: false, // 디버그 띠 제거
      theme: ThemeData(
        useMaterial3: true,
        // 1. 배경색: 눈이 편안한 아주 연한 회색
        scaffoldBackgroundColor: const Color(0xFFF8F9FD),

        // 2. 메인 색상: 세련된 퍼플/블루 계열
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          background: const Color(0xFFF8F9FD),
        ),

        // 3. 앱바 테마: 흰색 배경 + 검은 글씨
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
              color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),

        // 4. 카드 테마: 흰색 + 부드러운 그림자
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0, // 기본 그림자 제거 (BoxShadow로 직접 제어하기 위해)
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}