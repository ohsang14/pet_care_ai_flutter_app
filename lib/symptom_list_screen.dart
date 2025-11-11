import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'models/dog.dart';             // Dog 모델
import 'models/symptom_log.dart';    // SymptomLog 모델
import 'add_symptom_screen.dart';  // 👈 (다음 단계에 만들) 증상 추가 화면

class SymptomListScreen extends StatefulWidget {
  final Dog dog; // 👈 HealthCheckScreen에서 전달받은 반려견 객체
  const SymptomListScreen({super.key, required this.dog});

  @override
  State<SymptomListScreen> createState() => _SymptomListScreenState();
}

class _SymptomListScreenState extends State<SymptomListScreen> {
  List<SymptomLog> _symptomLogs = [];
  bool _isLoading = true;

  // Spring Boot 서버 URL (Android 에뮬레이터 기준)
  final String _baseUrl = "http://10.0.2.2:8080";
  // (만약 iOS 또는 데스크탑을 사용 중이라면 "http://localhost:8080"로 변경)

  @override
  void initState() {
    super.initState();
    _fetchSymptoms(); // 화면이 열릴 때 증상 기록을 불러옵니다.
  }

  // API 호출: GET /api/dogs/{dogId}/symptoms
  Future<void> _fetchSymptoms() async {
    setState(() {
      _isLoading = true; // 로딩 시작
    });

    final url = Uri.parse('$_baseUrl/api/dogs/${widget.dog.id}/symptoms');
    try {
      final response = await http.get(url);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> responseData =
        jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _symptomLogs =
              responseData.map((data) => SymptomLog.fromJson(data)).toList();
          _isLoading = false; // 로딩 완료
        });
      } else {
        print('증상 목록 로드 실패: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('증상 기록을 불러오는 데 실패했습니다.')),
        );
        setState(() {
          _isLoading = false; // 로딩 완료 (에러)
        });
      }
    } catch (e) {
      print('증상 목록 로드 에러: $e');
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

  // 증상 추가 화면으로 이동하는 함수
  void _navigateToAddSymptom() {
    Navigator.push(
      context,
      MaterialPageRoute(
        // 👈 새 증상을 추가할 반려견(dog) 객체를 전달합니다.
        builder: (context) => AddSymptomScreen(dog: widget.dog),
      ),
    ).then((result) {
      // 👈 증상 추가 화면에서 '저장'에 성공하여 true를 반환하면
      if (result == true) {
        _fetchSymptoms(); // 목록을 새로고침합니다.
      }
    });
  }

  // 날짜 형식을 'YYYY년 MM월 DD일 HH:mm'로 간단히 변환
  String _formatDateTime(DateTime dt) {
    return "${dt.year}년 ${dt.month.toString().padLeft(2, '0')}월 ${dt.day.toString().padLeft(2, '0')}일 "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text("'${widget.dog.name}'의 증상 기록"), // 👈 타이틀에 강아지 이름 표시
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: _buildSymptomList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddSymptom, // 👈 '+' 버튼 클릭 시
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSymptomList() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }

    if (_symptomLogs.isEmpty) {
      return const Center(
        child: Text(
          '기록된 증상이 없습니다.\n[+] 버튼을 눌러 첫 기록을 추가해보세요.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    // 불러온 증상 기록을 리스트로 표시 (서버에서 이미 최신순 정렬)
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _symptomLogs.length,
      itemBuilder: (context, index) {
        final log = _symptomLogs[index];
        return Card(
          color: Colors.grey[800],
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            // 1. 주요 증상
            title: Text(
              log.symptom,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            // 2. 상세 메모 (메모가 있을 때만 표시)
            subtitle: (log.memo != null && log.memo!.isNotEmpty)
                ? Text(
              log.memo!,
              style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
                : null,
            // 3. 기록 날짜
            trailing: Text(
              _formatDateTime(log.logDate),
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}