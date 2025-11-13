import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'models/dog.dart';
import 'models/health_check.dart';       // 👈 1. HealthCheck 모델 import
import 'models/health_check_data.dart';
import 'questionnaire_screen.dart';

class HealthResultScreen extends StatefulWidget {
  final Dog dog;

  // 2. '새로운 결과'를 받을 때 사용
  final int? totalScore;
  final List<HealthCheckResultItem>? analysisItems;
  final List<String>? allAnswerTexts;

  // 3. '과거 기록'을 받을 때 사용
  final HealthCheck? pastCheck;

  const HealthResultScreen({
    super.key,
    required this.dog,
    // 생성자를 유연하게 변경
    this.totalScore,
    this.analysisItems,
    this.allAnswerTexts,
    this.pastCheck,
  }) : assert( // 👈 둘 중 하나는 반드시 값이 있어야 함
  (totalScore != null && analysisItems != null && allAnswerTexts != null) || (pastCheck != null),
  '새 결과 데이터 또는 과거 HealthCheck 객체 둘 중 하나는 제공되어야 합니다.'
  );

  @override
  State<HealthResultScreen> createState() => _HealthResultScreenState();
}

class _HealthResultScreenState extends State<HealthResultScreen> {
  bool _isLoading = false;

  // 4. 화면에 표시될 최종 데이터를 담을 상태 변수
  late int _totalScore;
  late List<HealthCheckResultItem> _analysisItems;
  late List<String> _allAnswerTexts;
  late bool _isViewingPastRecord; // '저장' 버튼 등을 숨기기 위한 플래그

  final String _baseUrl = "http://10.0.2.2:8080";

  @override
  void initState() {
    super.initState();

    // 5. 'pastCheck' 객체가 넘어왔는지 확인
    if (widget.pastCheck != null) {
      // --- 과거 기록 보기 모드 ---
      _isViewingPastRecord = true;
      _totalScore = widget.pastCheck!.totalScore;

      // 'pastCheck' 객체에서 답변 목록을 재구성
      _allAnswerTexts = [
        widget.pastCheck!.answerStep1Appetite,
        widget.pastCheck!.answerStep2Activity,
        widget.pastCheck!.answerStep3Digestive,
        widget.pastCheck!.answerStep4Urinary,
        widget.pastCheck!.answerStep5Skin,
      ];

      // '상세 분석' 목록을 재구성 (점수가 0점 이상인 항목 찾기)
      _analysisItems = _reconstructAnalysisItems(_allAnswerTexts);

    } else {
      // --- 새로운 결과 보기 모드 ---
      _isViewingPastRecord = false;
      _totalScore = widget.totalScore!;
      _analysisItems = widget.analysisItems!;
      _allAnswerTexts = widget.allAnswerTexts!;
    }
  }

  // 6. [신규] 저장된 답변 텍스트를 기반으로 '상세 분석' 목록을 재구성하는 함수
  List<HealthCheckResultItem> _reconstructAnalysisItems(List<String> answers) {
    final List<QuestionnaireData> allQuestions = getQuestionnaireData();
    List<HealthCheckResultItem> items = [];

    for (int i = 0; i < allQuestions.length; i++) {
      final String currentAnswerText = answers[i];
      final QuestionnaireData questionData = allQuestions[i];

      try {
        // 'health_check_data.dart'에서 현재 답변과 일치하는 옵션을 찾음
        final QuestionOption matchedOption = questionData.options.firstWhere(
              (option) => option.text == currentAnswerText,
        );

        // 점수가 0보다 크면(나쁜 답변) '상세 분석' 리스트에 추가
        if (matchedOption.score > 0) {
          items.add(HealthCheckResultItem(
            question: questionData.questionTitle,
            answer: matchedOption.text,
          ));
        }
      } catch (e) {
        // (만약 health_check_data.dart의 문구를 수정해서 DB와 일치하지 않는 경우)
        print('일치하는 답변 옵션을 찾을 수 없습니다: $currentAnswerText');
      }
    }
    return items;
  }

  // '결과 저장하기' (수정 없음)
  Future<void> _saveResult() async {
    setState(() { _isLoading = true; });

    final url = Uri.parse('$_baseUrl/api/dogs/${widget.dog.id}/health-checks');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'totalScore': _totalScore, // 👈 상태 변수(_totalScore) 사용
          'answerStep1Appetite': _allAnswerTexts[0],
          'answerStep2Activity': _allAnswerTexts[1],
          'answerStep3Digestive': _allAnswerTexts[2],
          'answerStep4Urinary': _allAnswerTexts[3],
          'answerStep5Skin': _allAnswerTexts[4],
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('건강 기록이 성공적으로 저장되었습니다.')),
        );
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
        setState(() { _isLoading = false; });
      }
    }
  }

  // '다시 체크하기' (수정 없음)
  void _restartQuestionnaire() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionnaireScreen(dog: widget.dog),
      ),
    );
  }

  // (이하 점수/태그 관련 헬퍼 함수들은 수정 없음)
  String _getScoreTag(int score) {
    if (score <= 5) return '좋음';
    if (score <= 15) return '관찰 필요';
    return '병원 방문 권유';
  }

  Color _getScoreTagColor(int score) {
    if (score <= 5) return Colors.green;
    if (score <= 15) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    // 7. widget.totalScore 대신 상태 변수 _totalScore 사용
    String scoreTag = _getScoreTag(_totalScore);
    Color scoreColor = _getScoreTagColor(_totalScore);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        // 8. 모드에 따라 제목 변경
        title: Text(_isViewingPastRecord ? '과거 기록 상세' : '건강 체크 결과'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        // 9. '과거 기록' 모드일 때만 '뒤로가기' 버튼 표시
        automaticallyImplyLeading: _isViewingPastRecord,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. 건강 점수 카드 ---
            Card(
              // ... (내부는 _totalScore, scoreColor 등을 사용하므로 수정 없음) ...
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
                      '${_totalScore}점', // 👈 상태 변수 사용
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
              // 10. _analysisItems 상태 변수 사용
              child: _analysisItems.isEmpty
                  ? const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  '특별히 나쁜 징후가 없습니다. 아주 건강해요!',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              )
                  : Column(
                children: _analysisItems.map((item) {
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
                children: _buildRecommendationItems(_totalScore), // 👈 상태 변수 사용
              ),
            ),
            const SizedBox(height: 40),

            // --- 4. 하단 버튼 ---
            // 11. [핵심] '과거 기록' 모드가 아닐 때만 버튼들 표시
            if (!_isViewingPastRecord)
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _saveResult,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('결과 저장하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            if (!_isViewingPastRecord)
              TextButton(
                onPressed: _restartQuestionnaire,
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

  // (이하 _buildSectionCard, _buildAnalysisItem, _buildRecommendationItems 헬퍼 함수들은 수정 없음)

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
                  question,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  answer,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
      if (_analysisItems.length > 1) { // 👈 widget.analysisItems -> _analysisItems
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