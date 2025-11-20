import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_config.dart';
import 'models/dog.dart';
import 'models/health_check.dart';
import 'models/health_check_data.dart';
import 'questionnaire_screen.dart';

class HealthResultScreen extends StatefulWidget {
  final Dog dog;

  // 1. '새로운 결과' 모드
  final int? totalScore;
  final List<HealthCheckResultItem>? analysisItems;
  final List<String>? allAnswerTexts;

  // 2. '과거 기록' 모드
  final HealthCheck? pastCheck;

  const HealthResultScreen({
    super.key,
    required this.dog,
    this.totalScore,
    this.analysisItems,
    this.allAnswerTexts,
    this.pastCheck,
  }) : assert((totalScore != null && analysisItems != null && allAnswerTexts != null) || pastCheck != null,
  '새 결과 데이터 또는 과거 HealthCheck 객체 둘 중 하나는 제공되어야 합니다.');

  @override
  State<HealthResultScreen> createState() => _HealthResultScreenState();
}

class _HealthResultScreenState extends State<HealthResultScreen> {
  bool _isLoading = false;

  late int _totalScore;
  late List<HealthCheckResultItem> _analysisItems;
  late List<String> _allAnswerTexts;
  late bool _isViewingPastRecord;

  @override
  void initState() {
    super.initState();
    if (widget.pastCheck != null) {
      _isViewingPastRecord = true;
      _totalScore = widget.pastCheck!.totalScore;
      _allAnswerTexts = [
        widget.pastCheck!.answerStep1Appetite,
        widget.pastCheck!.answerStep2Activity,
        widget.pastCheck!.answerStep3Digestive,
        widget.pastCheck!.answerStep4Urinary,
        widget.pastCheck!.answerStep5Skin,
      ];
      _analysisItems = _reconstructAnalysisItems(_allAnswerTexts);
    } else {
      _isViewingPastRecord = false;
      _totalScore = widget.totalScore!;
      _analysisItems = widget.analysisItems!;
      _allAnswerTexts = widget.allAnswerTexts!;
    }
  }

  List<HealthCheckResultItem> _reconstructAnalysisItems(List<String> answers) {
    final List<QuestionnaireData> allQuestions = getQuestionnaireData();
    List<HealthCheckResultItem> items = [];
    for (int i = 0; i < allQuestions.length; i++) {
      final String currentAnswerText = answers[i];
      final QuestionnaireData questionData = allQuestions[i];
      try {
        final QuestionOption matchedOption = questionData.options.firstWhere((option) => option.text == currentAnswerText);
        if (matchedOption.score > 0) {
          items.add(HealthCheckResultItem(question: questionData.questionTitle, answer: matchedOption.text));
        }
      } catch (e) { /* 무시 */ }
    }
    return items;
  }

  Future<void> _saveResult() async {
    setState(() { _isLoading = true; });
    final url = Uri.parse('${AppConfig.baseUrl}/api/dogs/${widget.dog.id}/health-checks');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'totalScore': _totalScore,
          'answerStep1Appetite': _allAnswerTexts[0],
          'answerStep2Activity': _allAnswerTexts[1],
          'answerStep3Digestive': _allAnswerTexts[2],
          'answerStep4Urinary': _allAnswerTexts[3],
          'answerStep5Skin': _allAnswerTexts[4],
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('건강 기록이 저장되었습니다.')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장 실패')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('에러: $e')));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _restartQuestionnaire() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => QuestionnaireScreen(dog: widget.dog)),
    );
  }

  String _getScoreTag(int score) {
    if (score <= 5) return '좋음';
    if (score <= 15) return '관찰 필요';
    return '병원 방문 권유';
  }

  Color _getScoreTagColor(int score) {
    if (score <= 5) return Colors.green;
    if (score <= 15) return Colors.orange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    String scoreTag = _getScoreTag(_totalScore);
    Color scoreColor = _getScoreTagColor(_totalScore);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD), // 밝은 배경
      appBar: AppBar(
        title: Text(_isViewingPastRecord ? '과거 기록 상세' : '건강 체크 결과'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        automaticallyImplyLeading: _isViewingPastRecord, // 과거 기록일 때만 뒤로가기
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. 건강 점수 카드 ---
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: scoreColor.withOpacity(0.1),
                    child: Icon(Icons.favorite, color: scoreColor, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text('건강 점수', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 5),
                  Text(
                    '${_totalScore}점',
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: scoreColor),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: scoreColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(scoreTag, style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- 2. 상세 분석 카드 ---
            _buildSectionTitle('상세 분석'),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: _analysisItems.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(10.0),
                child: Center(child: Text('특별히 나쁜 징후가 없습니다. 아주 건강해요! 👏', style: TextStyle(color: Colors.black54, fontSize: 16))),
              )
                  : Column(
                children: _analysisItems.map((item) => _buildAnalysisItem(item)).toList(),
              ),
            ),
            const SizedBox(height: 30),

            // --- 3. 권장사항 카드 ---
            _buildSectionTitle('권장사항'),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(children: _buildRecommendationItems(_totalScore)),
            ),
            const SizedBox(height: 40),

            // --- 4. 하단 버튼 ---
            if (!_isViewingPastRecord)
              SizedBox(
                height: 55,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _saveResult,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF), // 포인트 컬러
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                    shadowColor: const Color(0xFF6C63FF).withOpacity(0.4),
                  ),
                  child: const Text('결과 저장하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            if (!_isViewingPastRecord)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: TextButton(
                  onPressed: _restartQuestionnaire,
                  child: const Text('다시 체크하기', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 5),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildAnalysisItem(HealthCheckResultItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.question, style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(item.answer, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRecommendationItems(int score) {
    List<String> recommendations = [];
    if (score <= 5) {
      recommendations.add('완벽한 건강 상태입니다! 지금처럼 잘 관리해주세요.');
    } else if (score <= 15) {
      recommendations.add('가벼운 징후입니다. 증상이 지속되는지 주의 깊게 관찰하세요.');
      recommendations.add('충분한 휴식과 신선한 물을 제공해주세요.');
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
            const Icon(Icons.check_circle, color: Color(0xFF6C63FF), size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(color: Colors.black87, fontSize: 15, height: 1.4))),
          ],
        ),
      );
    }).toList();
  }
}