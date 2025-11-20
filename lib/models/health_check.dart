class HealthCheck {
  final int id;
  final DateTime checkDate;
  final int totalScore;
  final String? dogProfileImageUrl;
  final String? dogName;

  // 5단계 답변 텍스트
  final String answerStep1Appetite;
  final String answerStep2Activity;
  final String answerStep3Digestive;
  final String answerStep4Urinary;
  final String answerStep5Skin;

  HealthCheck({
    required this.id,
    required this.checkDate,
    required this.totalScore,
    required this.answerStep1Appetite,
    required this.answerStep2Activity,
    required this.answerStep3Digestive,
    required this.answerStep4Urinary,
    required this.answerStep5Skin,
    this.dogProfileImageUrl,
    this.dogName,
  });

  // JSON(Map)을 HealthCheck 객체로 변환
  factory HealthCheck.fromJson(Map<String, dynamic> json) {
    return HealthCheck(
      id: json['id'],
      checkDate: DateTime.parse(json['checkDate']),
      // ISO 문자열을 DateTime으로
      totalScore: json['totalScore'],
      answerStep1Appetite: json['answerStep1Appetite'],
      answerStep2Activity: json['answerStep2Activity'],
      answerStep3Digestive: json['answerStep3Digestive'],
      answerStep4Urinary: json['answerStep4Urinary'],
      answerStep5Skin: json['answerStep5Skin'],
      dogProfileImageUrl: json['dogProfileImageUrl'],
      dogName: json['dogName'],
    );
  }
}
