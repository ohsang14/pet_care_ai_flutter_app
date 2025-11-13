import 'package:flutter/material.dart';
import 'models/dog.dart';
import 'health_result_screen.dart'; // 👈 (다음 단계에 만들) 결과 화면
import 'models/health_check_data.dart'; // 👈 (바로 다음에 만들) 질문/답변 데이터 모델

class QuestionnaireScreen extends StatefulWidget {
  final Dog dog;
  const QuestionnaireScreen({super.key, required this.dog});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  // PageView를 제어하기 위한 컨트롤러
  final PageController _pageController = PageController();
  // 현재 페이지 인덱스
  int _currentPageIndex = 0;

  // 1. 5단계 질문/답변 데이터 리스트 (데이터는 별도 파일로 분리)
  final List<QuestionnaireData> _questions = getQuestionnaireData();

  // 2. 사용자가 선택한 답변 인덱스를 저장할 리스트 (초기값 -1)
  late List<int> _selectedAnswers;

  @override
  void initState() {
    super.initState();
    // 5개 질문에 대해 "아직 선택 안 함(-1)"으로 초기화
    _selectedAnswers = List<int>.filled(_questions.length, -1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // '다음' 버튼을 눌렀을 때
  void _nextPage() {
    // 3. 답변을 선택하지 않으면 다음으로 넘어가지 않음
    if (_selectedAnswers[_currentPageIndex] == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('답변을 선택해주세요.')),
      );
      return;
    }

    // 4. 마지막 질문(4번 인덱스)이 아니면 다음 페이지로
    if (_currentPageIndex < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      // 5. 마지막 질문이면 '결과 보기' 실행
      _showResultScreen();
    }
  }

  // '이전' 버튼을 눌렀을 때
  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
  }

  // 6. 결과 화면으로 이동 (계산 로직)
  void _showResultScreen() {
    int totalScore = 0;
    List<String> selectedAnswerTexts = [];
    List<HealthCheckResultItem> analysisItems = [];

    // 7. 점수 계산 및 답변 텍스트 취합
    for (int i = 0; i < _questions.length; i++) {
      int selectedOptionIndex = _selectedAnswers[i];
      QuestionOption selectedOption = _questions[i].options[selectedOptionIndex];

      // 총점 합산
      totalScore += selectedOption.score;

      // 답변 텍스트 (예: "평소보다 적게 먹어요")
      selectedAnswerTexts.add(selectedOption.text);

      // '상세 분석' 항목 추가 (점수가 0점보다 큰, 즉 '나쁜' 항목만)
      if (selectedOption.score > 0) {
        analysisItems.add(HealthCheckResultItem(
          question: _questions[i].questionTitle, // 예: "식욕 및 음수량"
          answer: selectedOption.text,
        ));
      }
    }

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
    ).then((resultFromHealthResult) {
      // 9. ⭐️ [추가] HealthResultScreen이 pop(true)로 닫혔다면,
      //    그 'true' 값을 QuestionnaireScreen도 pop하여 HistoryScreen으로 전달
      if (resultFromHealthResult == true) {
        Navigator.pop(context, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 현재 진행률 (예: 1/5 -> 20%)
    double progress = (_currentPageIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('건강 상태 체크'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. 상단 진행률 표시줄 (ProgressBar)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '질문 ${(_currentPageIndex + 1)} / ${_questions.length}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[700],
                  color: Colors.blueAccent,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),

          // 2. 질문 페이지 (PageView)
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _questions.length,
              // 👈 좌우 스와이프로 페이지 넘기기 비활성화
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                // 각 페이지 UI 생성
                return _buildQuestionPage(_questions[index], index);
              },
            ),
          ),

          // 3. 하단 네비게이션 버튼 (이전, 다음)
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  // 각 설문 페이지의 UI를 그리는 위젯
  Widget _buildQuestionPage(QuestionnaireData data, int pageIndex) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(data.icon, color: Colors.blueAccent, size: 28),
                const SizedBox(width: 10),
                Text(
                  data.questionTitle, // 예: "식욕 및 음수량"
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            Text(
              data.questionText, // 예: "반려견의 식욕과 물 마시는 양은..."
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.4
              ),
            ),
            const SizedBox(height: 20),

            // 4. 답변 선택 옵션 (RadioListTile)
            Expanded(
              child: ListView.builder(
                itemCount: data.options.length,
                itemBuilder: (context, optionIndex) {
                  final option = data.options[optionIndex];
                  return RadioListTile<int>(
                    title: Text(option.text, style: const TextStyle(fontSize: 16, height: 1.5)),
                    value: optionIndex, // 이 옵션의 인덱스
                    groupValue: _selectedAnswers[pageIndex], // 현재 페이지에서 선택된 인덱스
                    onChanged: (value) {
                      setState(() {
                        _selectedAnswers[pageIndex] = value!;
                      });
                    },
                    activeColor: Colors.blueAccent,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 하단 '이전' / '다음' 버튼 위젯
  Widget _buildNavigationButtons() {
    bool isLastPage = _currentPageIndex == _questions.length - 1;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          // '이전' 버튼 (첫 페이지가 아닐 때만 보임)
          if (_currentPageIndex > 0)
            Expanded(
              child: ElevatedButton(
                onPressed: _previousPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('이전', style: TextStyle(fontSize: 16)),
              ),
            ),

          if (_currentPageIndex > 0)
            const SizedBox(width: 10),

          // '다음' 또는 '결과 보기' 버튼
          Expanded(
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastPage ? Colors.green : Colors.blueAccent, // 마지막엔 초록색
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isLastPage ? '결과 보기' : '다음', // 👈 마지막 페이지에서 텍스트 변경
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}