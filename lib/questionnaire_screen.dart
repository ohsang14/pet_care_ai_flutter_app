import 'package:flutter/material.dart';
import 'models/dog.dart';
import 'health_result_screen.dart';
import 'models/health_check_data.dart';

class QuestionnaireScreen extends StatefulWidget {
  final Dog dog;
  const QuestionnaireScreen({super.key, required this.dog});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // 질문 데이터 가져오기
  final List<QuestionnaireData> _questions = getQuestionnaireData();

  // 선택한 답변 인덱스 저장 (-1은 미선택)
  late List<int> _answers;

  @override
  void initState() {
    super.initState();
    _answers = List.filled(_questions.length, -1);
  }

  // 다음 페이지로 이동
  void _nextPage() {
    if (_answers[_currentPage] == -1) return; // 답변 선택 안 했으면 무시

    if (_currentPage < _questions.length - 1) {
      // 다음 질문으로
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease
      );
    } else {
      // 마지막 질문이면 결과 처리
      _finish();
    }
  }

  // ⭐️ [핵심] 결과 계산 및 화면 이동 (여기가 비어있어서 안 됐던 겁니다!)
  void _finish() {
    int totalScore = 0;
    List<String> selectedAnswerTexts = [];
    List<HealthCheckResultItem> analysisItems = [];

    for (int i = 0; i < _questions.length; i++) {
      int selectedIndex = _answers[i];
      QuestionOption selectedOption = _questions[i].options[selectedIndex];

      // 1. 총점 계산
      totalScore += selectedOption.score;

      // 2. 저장할 답변 텍스트 수집
      selectedAnswerTexts.add(selectedOption.text);

      // 3. 점수가 높은(나쁜) 항목은 상세 분석 리스트에 추가
      if (selectedOption.score > 0) {
        analysisItems.add(HealthCheckResultItem(
          question: _questions[i].questionTitle,
          answer: selectedOption.text,
        ));
      }
    }

    // 4. 결과 화면으로 이동 (HealthResultScreen)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthResultScreen(
          dog: widget.dog,
          totalScore: totalScore,
          analysisItems: analysisItems,
          allAnswerTexts: selectedAnswerTexts,
        ),
      ),
    ).then((result) {
      // 결과 화면에서 '저장'하고 돌아왔다면(true), 이 화면도 닫고 목록 화면으로 복귀
      if (result == true) {
        Navigator.pop(context, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('건강 체크'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Column(
        children: [
          // 상단 진행바
          LinearProgressIndicator(
            value: (_currentPage + 1) / _questions.length,
            backgroundColor: Colors.grey[200],
            color: const Color(0xFF6C63FF), // 포인트 컬러
            minHeight: 6,
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // 스와이프 금지 (버튼으로만 이동)
              itemCount: _questions.length,
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              itemBuilder: (ctx, idx) => _buildQuestionCard(_questions[idx], idx),
            ),
          ),
        ],
      ),
    );
  }

  // 질문 카드 UI
  Widget _buildQuestionCard(QuestionnaireData data, int index) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('질문 ${index + 1}', style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(data.questionTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 10),
          Text(data.questionText, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 30),

          // 답변 리스트 생성
          ...List.generate(data.options.length, (optIdx) {
            final option = data.options[optIdx];
            final isSelected = _answers[index] == optIdx;

            return GestureDetector(
              onTap: () => setState(() => _answers[index] = optIdx),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6C63FF) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? const Color(0xFF6C63FF) : Colors.grey.shade300),
                  boxShadow: [if(!isSelected) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)],
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(option.text, style: TextStyle(fontSize: 16, color: isSelected ? Colors.white : Colors.black87))),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 30),

          // 다음/결과보기 버튼
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              // 답변을 선택해야만 버튼 활성화
              onPressed: _answers[index] != -1 ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: Text(
                index == _questions.length - 1 ? '결과 보기' : '다음',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}