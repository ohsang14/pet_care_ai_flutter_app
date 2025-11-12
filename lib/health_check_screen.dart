import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'member.dart'; // 👈 'models/member.dart'가 아닌 'member.dart'로 가정
import 'models/dog.dart';
import 'health_history_screen.dart'; // (이 파일은 다음 단계에 확인합니다)

class HealthCheckScreen extends StatefulWidget {
  final Member member;
  const HealthCheckScreen({super.key, required this.member});

  @override
  State<HealthCheckScreen> createState() => _HealthCheckScreenState();
}

class _HealthCheckScreenState extends State<HealthCheckScreen> {
  List<Dog> _dogList = [];
  bool _isLoading = true;

  // 안드로이드 에뮬레이터 기준
  final String _baseUrl = "http://10.0.2.2:8080";

  @override
  void initState() {
    super.initState();
    _fetchDogs();
  }

  Future<void> _fetchDogs() async {
    // API로 강아지 목록 가져오기
    final url = Uri.parse('$_baseUrl/api/members/${widget.member.id}/dogs');
    try {
      final response = await http.get(url);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> responseData =
        jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _dogList = responseData.map((data) => Dog.fromJson(data)).toList();
          _isLoading = false;
        });
      } else {
        setState(() { _isLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  // '과거 기록' 화면으로 이동
  void _navigateToHealthHistory(Dog dog) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthHistoryScreen(dog: dog),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('건강 체크'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: _buildDogList(),
    );
  }

  // 강아지 목록 UI
  Widget _buildDogList() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }

    if (_dogList.isEmpty) {
      return const Center(
        child: Text(
          '등록된 반려견이 없습니다.\n[홈] 탭에서 먼저 반려견을 등록해주세요.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    // 강아지 목록
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _dogList.length,
      itemBuilder: (context, index) {
        final dog = _dogList[index];
        return Card(
          color: Colors.grey[800],
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            leading: const CircleAvatar(
              backgroundColor: Colors.blueAccent,
              radius: 25,
              child: Icon(Icons.pets, color: Colors.white, size: 28),
            ),
            title: Text(
              dog.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              '과거 건강 기록 보기',
              style: TextStyle(color: Colors.white70),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
            onTap: () {
              _navigateToHealthHistory(dog);
            },
          ),
        );
      },
    );
  }
}