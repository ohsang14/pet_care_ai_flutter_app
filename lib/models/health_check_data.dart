import 'package:flutter/material.dart';


// 1. 질문의 각 '답변' 항목을 정의하는 모델
class QuestionOption {
  final String text; // 예: "평소와 같이 잘 먹어요"
  final int score;   // 예: 0점 (좋음), 5점 (나쁨)

  QuestionOption({required this.text, required this.score});
}

// 2. '질문' 하나를 정의하는 모델 (제목, 아이콘, 질문 텍스트, 답변 목록)
class QuestionnaireData {
  final IconData icon;
  final String questionTitle;
  final String questionText;
  final List<QuestionOption> options;

  QuestionnaireData({
    required this.icon,
    required this.questionTitle,
    required this.questionText,
    required this.options,
  });
}

// 3. '상세 분석' 결과 항목을 정의하는 모델 (결과 화면에서 사용)
class HealthCheckResultItem {
  final String question; // 예: "식욕 및 음수량"
  final String answer;   // 예: "평소보다 적게 먹어요"

  HealthCheckResultItem({required this.question, required this.answer});
}


// --- ⬇️ 실제 설문조사 데이터 (여기서 수정) ⬇️ ---

// 4. 5단계 설문조사 데이터를 반환하는 함수
List<QuestionnaireData> getQuestionnaireData() {
  return [
    // --- 질문 1: 식욕 및 음수량 ---
    QuestionnaireData(
      icon: Icons.restaurant_menu,
      questionTitle: '식욕 및 음수량',
      questionText: '반려견의 식욕과 물 마시는 양은 어떤가요?',
      options: [
        QuestionOption(text: '평소와 같이 잘 먹고 잘 마셔요', score: 0),
        QuestionOption(text: '평소보다 밥/물을 적게 먹어요', score: 3),
        QuestionOption(text: '거의 먹거나 마시지 않아요', score: 5),
        QuestionOption(text: '평소보다 밥/물을 훨씬 많이 먹어요', score: 5), // (다음다뇨)
      ],
    ),

    // --- 질문 2: 전반적인 기력 및 행동 ---
    QuestionnaireData(
      icon: Icons.directions_run,
      questionTitle: '전반적인 기력 및 행동',
      questionText: '반려견의 활동량이나 평소 행동에 변화가 있나요?',
      options: [
        QuestionOption(text: '평소처럼 활발하고 특별한 통증이 없어 보여요', score: 0),
        QuestionOption(text: '산책/놀이를 거부하거나 기운이 없어요', score: 3),
        QuestionOption(text: '절뚝거리거나 특정 부위를 만지면 아파해요', score: 5),
        QuestionOption(text: '거의 움직이지 않거나 숨어 있어요', score: 5),
      ],
    ),

    // --- 질문 3: 소화기 상태 (구토 및 대변) ---
    QuestionnaireData(
      icon: Icons.ac_unit, // (가상 아이콘, Icons.bolt 등 다른 것으로 대체 가능)
      questionTitle: '소화기 상태',
      questionText: '반려견이 구토를 하거나, 대변 상태가 좋지 않나요?',
      options: [
        QuestionOption(text: '구토가 없고, 대변 상태가 좋아요 (딱딱하지도 무르지도 않음)', score: 0),
        QuestionOption(text: '오늘 1~2회 구토를 했어요 (거품, 사료 등)', score: 3),
        QuestionOption(text: '변이 평소보다 무르거나(설사), 딱딱해요(변비)', score: 3),
        QuestionOption(text: '지속적으로 구토를 하거나, 대변에 피나 점액이 섞여 있어요', score: 5),
      ],
    ),

    // --- 질문 4: 비뇨기 및 호흡기 상태 ---
    QuestionnaireData(
      icon: Icons.air,
      questionTitle: '비뇨기 및 호흡기',
      questionText: '반려견의 소변 상태나 호흡(기침/재채기)이 평소와 다른가요?',
      options: [
        QuestionOption(text: '소변 색이 맑고, 호흡이 안정적이에요', score: 0),
        QuestionOption(text: '소변 횟수가 너무 많거나 적고, 색이 탁해요', score: 3),
        QuestionOption(text: '마른 기침이나 재채기를 가끔 해요', score: 3),
        QuestionOption(text: '소변에 피가 섞여 나오거나, 호흡이 거칠고 힘들어 보여요', score: 5),
      ],
    ),

    // --- 질문 5: 피부 및 감각기 상태 ---
    QuestionnaireData(
      icon: Icons.visibility,
      questionTitle: '피부 및 감각기',
      questionText: '반려견의 털/피부나 눈/코/귀 상태는 어떤가요?',
      options: [
        QuestionOption(text: '피부가 깨끗하고, 눈/코/귀에 분비물이 거의 없어요', score: 0),
        QuestionOption(text: '평소보다 털이 많이 빠지거나, 몸을 자주 긁어요', score: 3),
        QuestionOption(text: '눈물/콧물이 많아졌거나, 귀에서 냄새가 나요', score: 3),
        QuestionOption(text: '피부에 발진/비듬이 생겼거나, 눈이 충혈되었어요', score: 5),
      ],
    ),
  ];
}