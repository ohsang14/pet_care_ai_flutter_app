import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'health_result_screen.dart';
import 'models/dog.dart';             // Dog 모델
import 'models/health_check.dart';    // HealthCheck 모델
import 'questionnaire_screen.dart'; // 👈 (다음 단계에 만들) 설문조사 화면

class HealthHistoryScreen extends StatefulWidget {
  final Dog dog; // 👈 HealthCheckScreen에서 전달받은 반려견 객체
  const HealthHistoryScreen({super.key, required this.dog});

  @override
  State<HealthHistoryScreen> createState() => _HealthHistoryScreenState();
}

class _HealthHistoryScreenState extends State<HealthHistoryScreen> {
  List<HealthCheck> _healthChecks = [];
  bool _isLoading = true;

  // Spring Boot 서버 URL (Android 에뮬레이터 기준)
  final String _baseUrl = "http://10.0.2.2:8080";
  // (만약 iOS 또는 데스크탑을 사용 중이라면 "http://localhost:8080"로 변경)

  @override
  void initState() {
    super.initState();
    _fetchHealthChecks(); // 화면이 열릴 때 과거 기록을 불러옵니다.
  }

  // API 호출: GET /api/dogs/{dogId}/health-checks
  Future<void> _fetchHealthChecks() async {
    setState(() {
      _isLoading = true; // 로딩 시작
    });

    final url = Uri.parse('$_baseUrl/api/dogs/${widget.dog.id}/health-checks');
    try {
      final response = await http.get(url);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> responseData =
        jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _healthChecks =
              responseData.map((data) => HealthCheck.fromJson(data)).toList();
          _isLoading = false; // 로딩 완료
        });
      } else {
        print('건강 기록 로드 실패: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('과거 기록을 불러오는 데 실패했습니다.')),
        );
        setState(() {
          _isLoading = false; // 로딩 완료 (에러)
        });
      }
    } catch (e) {
      print('건강 기록 로드 에러: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('서버 통신 중 에러가 발생했습니다.')),
        );
        setState(() {
          _isLoading = false; // 로딩 완료 (에러)
        });
      }
    }
  }

  // '새 건강 체크' 설문조사 화면으로 이동하는 함수
  void _navigateToQuestionnaire() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionnaireScreen(dog: widget.dog),
      ),
    ).then((result) {
      // 👈 설문 완료 후 결과 저장에 성공(true)하면
      if (result == true) {
        _fetchHealthChecks(); // 이 화면(과거 기록)을 새로고침합니다.
      }
    });
  }

  // 날짜 형식을 간단히 변환
  String _formatDateTime(DateTime dt) {
    return "${dt.year}년 ${dt.month.toString().padLeft(2, '0')}월 ${dt.day.toString().padLeft(2, '0')}일";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text("'${widget.dog.name}'의 건강 기록"),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      // 1. 본문과 '새 체크' 버튼을 Column으로 감싸기
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 2. '새로운 건강 체크하기' 버튼
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _navigateToQuestionnaire,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('새로운 건강 상태 체크하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // 3. 과거 기록 리스트 (Expanded로 남은 공간 채우기)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_healthChecks.isEmpty) {
      return const Center(
        child: Text(
          '저장된 건강 기록이 없습니다.\n위의 버튼을 눌러 첫 기록을 시작하세요.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    // 불러온 과거 기록을 리스트로 표시 (서버에서 이미 최신순 정렬)
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _healthChecks.length,
      itemBuilder: (context, index) {
        final check = _healthChecks[index];
        return Card(
          color: Colors.grey[800],
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            leading: _buildScoreIcon(check.totalScore), // 점수에 따라 아이콘 표시
            title: Text(
              '${check.totalScore}점', // 👈 건강 점수
              style: TextStyle(
                color: _getScoreColor(check.totalScore), // 👈 점수에 따라 색상
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              _formatDateTime(check.checkDate), // 👈 검사 날짜
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
            onTap: () {Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HealthResultScreen(
                  dog: widget.dog,
                  pastCheck: check, // 👈 [핵심] 'pastCheck' 파라미터로 전달
                ),
              ),
            );
            },
          ),
        );
      },
    );
  }

  // 점수에 따라 아이콘 색상 변경
  Color _getScoreColor(int score) {
    if (score <= 5) return Colors.greenAccent; // 좋음
    if (score <= 15) return Colors.orangeAccent; // 관찰 필요
    return Colors.redAccent; // 나쁨
  }

  // 점수에 따라 아이콘 변경
  Widget _buildScoreIcon(int score) {
    IconData icon;
    Color color = _getScoreColor(score);
    if (score <= 5) {
      icon = Icons.check_circle; // 좋음
    } else if (score <= 15) {
      icon = Icons.warning_amber_rounded; // 관찰 필요
    } else {
      icon = Icons.dangerous_rounded; // 나쁨
    }
    return Icon(icon, color: color, size: 40);
  }
}