import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'member.dart';
import 'models/dog.dart';     // Dog 모델
import 'symptom_list_screen.dart'; // 👈 (다음 단계에 만들) 증상 목록 화면

class HealthCheckScreen extends StatefulWidget {
  final Member member;
  const HealthCheckScreen({super.key, required this.member});

  @override
  State<HealthCheckScreen> createState() => _HealthCheckScreenState();
}

class _HealthCheckScreenState extends State<HealthCheckScreen> {
  List<Dog> _dogList = [];
  bool _isLoading = true;

  // Spring Boot 서버 URL (Android 에뮬레이터 기준)
  final String _baseUrl = "http://10.0.2.2:8080";
  // (만약 iOS 또는 데스크탑을 사용 중이라면 "http://localhost:8080"로 변경)

  @override
  void initState() {
    super.initState();
    _fetchDogs();
  }

  // HomeScreen의 _fetchDogs와 100% 동일한 기능입니다.
  Future<void> _fetchDogs() async {
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
        print('반려견 목록 로드 실패: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('반려견 목록 로드 에러: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 특정 반려견을 탭했을 때 증상 기록 화면으로 이동하는 함수
  void _navigateToSymptomList(Dog dog) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // 👈 다음 화면으로 선택한 'dog' 객체를 전달합니다.
        builder: (context) => SymptomListScreen(dog: dog),
      ),
    ).then((_) {
      // (선택사항) 증상 기록 화면에서 돌아왔을 때 특별히 새로고침할 내용이 있다면
      // 여기에 작성할 수 있습니다. (지금은 비워둠)
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('건강 체크'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        // (참고: 홈 화면과 달리 반려견 추가(+) 버튼은 여기 없습니다.)
      ),
      body: _buildDogList(),
    );
  }

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

    // 등록된 반려견 목록을 리스트로 표시
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
              dog.name, // 반려견 이름
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '증상 기록 보러가기', // 부제
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
            onTap: () {
              _navigateToSymptomList(dog); // 👈 탭 기능
            },
          ),
        );
      },
    );
  }
}