class SymptomLog {
  final int id;
  final DateTime logDate; // 서버의 LocalDateTime은 JSON에서 ISO 문자열로 옵니다.
  final String symptom;
  final String? memo;      // DB에서 NULL을 허용하므로 nullable(String?)로 선언

  SymptomLog({
    required this.id,
    required this.logDate,
    required this.symptom,
    this.memo,
  });

  // JSON에서 SymptomLog 객체로 변환하는 factory 생성자
  factory SymptomLog.fromJson(Map<String, dynamic> json) {
    return SymptomLog(
      id: json['id'],
      logDate: DateTime.parse(json['logDate']), // ISO 문자열을 DateTime 객체로 변환
      symptom: json['symptom'],
      memo: json['memo'],
    );
  }
}