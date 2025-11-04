import 'package:flutter/material.dart';
import 'member.dart';

class HomeScreen extends StatelessWidget {
  // 1. HomeScreen이 Member 객체를 받도록 생성자 수정
  final Member member;
  const HomeScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PetCare AI 홈'),
      ),
      body: Center(
        child: Text(
          // 2. 임시 텍스트 대신, 로그인한 사용자의 이름을 보여줌
          '🎉 안녕하세요, ${member.name}님! 🎉',
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
