import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'models/dog.dart';
import 'models/health_check_data.dart'; // HealthCheckResultItem
import 'questionnaire_screen.dart'; // '다시 체크하기'용

class HealthResultScreen extends StatefulWidget {
  final Dog dog;
  final int totalScore; // 1. 설문조사에서 계산된 총점
  final List<HealthCheckResultItem> analysisItems; // 2. 점수가 0보다 큰 '상세 분석' 항목
  final List<String> allAnswerTexts; // 3. 5개 답변 텍스트 (서버 저장용)

  const HealthResultScreen({
    super.key,
    required this.dog,
    required this.totalScore,
    required this.analysisItems,
    required this.allAnswerTexts,
  });

  @override
  State<HealthResultScreen> createState() => _HealthResultScreenState();
}

class _HealthResultScreenState extends State<HealthResultScreen> {
  bool _isLoading = false;

  // Spring Boot 서버 URL (Android 에뮬레이터 기준)
  final String _baseUrl = "http://10.0.2.2:8080";
  // (만약 iOS 또는 데스크탑을 사용 중이라면 "http://localhost:8080"로 변경)

  // '결과 저장하기' 버튼 클릭 시
  Future<void> _saveResult() async {
    setState(() {
      _isLoading = true;
    });

    // 1. API URL (POST /api/dogs/{dogId}/health-checks)
    final url = Uri.parse('$_baseUrl/api/dogs/${widget.dog.id}/health-checks');

    try {
      // 2. Spring Boot의 HealthCheckRequestDto와 일치하는 JSON 본문 생성
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'totalScore': widget.totalScore,
          'answerStep1Appetite': widget.allAnswerTexts[0], // 1번 답변
          'answerStep2Activity': widget.allAnswerTexts[1], // 2번 답변
          'answerStep3Digestive': widget.allAnswerTexts[2], // 3번 답변
          'answerStep4Urinary': widget.allAnswerTexts[3], // 4번 답변
          'answerStep5Skin': widget.allAnswerTexts[4],    // 5번 답변
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) { // 201 CREATED (저장 성공)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('건강 기록이 성공적으로 저장되었습니다.')),
        );
        // 3. 저장 성공 시, true 값을 반환하며 이전 화면(HealthHistoryScreen)으로 복귀
        Navigator.pop(context, true);
      } else {
        print('결과 저장 실패: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    } catch (e) {
      print('결과 저장 에러: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('서버 통신 중 에러가 발생했습니다.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // '다시 체크하기' 버튼 클릭 시
  void _restartQuestionnaire() {
    Navigator.pushReplacement( // 👈 현재 화면을 스택에서 제거하고 새 설문조사 시작
      context,
      MaterialPageRoute(
        builder: (context) => QuestionnaireScreen(dog: widget.dog),
      ),
    );
  }

  // 점수에 따른 '관찰 필요' 등 태그 반환
  String _getScoreTag(int score) {
    if (score <= 5) return '좋음';
    if (score <= 15) return '관찰 필요';
    return '병원 방문 권유';
  }

  // 점수에 따른 태그 색상 반환
  Color _getScoreTagColor(int score) {
    if (score <= 5) return Colors.green;
    if (score <= 15) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    String scoreTag = _getScoreTag(widget.totalScore);
    Color scoreColor = _getScoreTagColor(widget.totalScore);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('건강 체크 결과'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // 👈 뒤로가기 버튼 숨기기
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. 건강 점수 카드 ---
            Card(
              elevation: 4,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: scoreColor.withOpacity(0.1),
                      child: Icon(Icons.favorite, color: scoreColor, size: 40),
                    ),
                    const SizedBox(height: 16),
                    const Text('건강 점수', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.totalScore}점',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        scoreTag,
                        style: TextStyle(
                          color: scoreColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- 2. 상세 분석 카드 ---
            _buildSectionCard(
              title: '상세 분석',
              child: widget.analysisItems.isEmpty
                  ? const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  '특별히 나쁜 징후가 없습니다. 아주 건강해요!',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              )
                  : Column(
                children: widget.analysisItems.map((item) {
                  return _buildAnalysisItem(
                    question: item.question,
                    answer: item.answer,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 30),

            // --- 3. 권장사항 카드 ---
            _buildSectionCard(
              title: '권장사항',
              child: Column(
                children: _buildRecommendationItems(widget.totalScore),
              ),
            ),
            const SizedBox(height: 40),

            // --- 4. 하단 버튼 ---
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _saveResult, // 👈 저장 함수 연결
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent, // 저장 버튼
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('결과 저장하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _restartQuestionnaire, // 👈 다시 체크하기 함수 연결
              child: const Text(
                '다시 체크하기',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // '상세 분석', '권장사항' 섹션 카드 UI
  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      color: Colors.grey[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(color: Colors.white24, height: 24),
            child,
          ],
        ),
      ),
    );
  }

  // '상세 분석'의 각 항목 UI (피그마 2, 3번)
  Widget _buildAnalysisItem({required String question, required String answer}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question, // 예: "식욕 및 음수량"
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  answer, // 예: "평소보다 적게 먹어요"
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 점수에 따른 '권장사항' 목록 반환
  List<Widget> _buildRecommendationItems(int score) {
    List<String> recommendations = [];

    if (score == 0) {
      recommendations.add('완벽한 건강 상태입니다! 지금처럼 잘 관리해주세요.');
    } else if (score <= 5) {
      recommendations.add('가벼운 징후입니다. 증상이 지속되는지 주의 깊게 관찰하세요.');
      recommendations.add('충분한 휴식과 신선한 물을 제공해주세요.');
    } else if (score <= 15) {
      recommendations.add('증상이 지속되는지 주의 깊게 관찰하세요.');
      recommendations.add('응급 상황에 대비해 병원 연락처를 준비하세요.');
      if (widget.analysisItems.length > 1) {
        recommendations.add('여러 항목에서 이상 징후가 보입니다. 24시간 내 증상이 나아지지 않으면 병원 방문을 권장합니다.');
      }
    } else {
      recommendations.add('높은 위험 징후입니다. 즉시 수의사 진료를 받아보시길 강력히 권장합니다.');
      recommendations.add('응급 상황에 대비해 병원 연락처를 준비하세요.');
    }

    return recommendations.map((text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle, color: Colors.blueAccent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
            ),
          ],
        ),
      );
    }).toList();
  }
}