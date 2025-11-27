import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:mypet/service/storage_service.dart';
import 'models/member.dart';
import 'login_screen.dart';
import 'main_screen.dart';

void main() async { // 1. async 키워드 추가
  // 비동기 처리를 위해 바인딩 초기화 필수
  WidgetsFlutterBinding.ensureInitialized();

  // 카카오 SDK 초기화
  KakaoSdk.init(nativeAppKey: '9b11ffc9a57e419c6f691d892ca997aa');

  // ⭐️ 2. 앱 시작 전 저장된 로그인 정보 확인 (자동 로그인)
  final Member? savedMember = await StorageService.getMember();

  // 저장된 멤버 정보를 앱에 전달
  runApp(PetCareApp(initialMember: savedMember));
}

class PetCareApp extends StatelessWidget {
  final Member? initialMember; // 전달받은 초기 멤버 정보

  const PetCareApp({super.key, this.initialMember});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetCare AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FD),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          background: const Color(0xFFF8F9FD),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
              color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      // ⭐️ 3. 로그인 정보가 있으면 MainScreen, 없으면 LoginScreen으로 시작
      home: initialMember != null
          ? MainScreen(member: initialMember!)
          : const LoginScreen(),
    );
  }
}