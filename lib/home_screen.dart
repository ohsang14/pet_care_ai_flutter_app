import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PetCare AI 홈'),
      ),
      body: const Center(
        child: Text(
          '🎉 로그인에 성공했습니다! 🎉',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}