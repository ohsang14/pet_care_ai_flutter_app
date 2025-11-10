// lib/analysis_result.dart

class AnalysisResult {
  final String breedNameEn;
  final String breedNameKo;
  final String? imageUrl;   // 👈 1. String -> String? (nullable로 변경)
  final double score;

  AnalysisResult({
    required this.breedNameEn,
    required this.breedNameKo,
    this.imageUrl, // 👈 2. required 키워드 제거
    required this.score,
  });

  // JSON(Map)을 AnalysisResult 객체로 변환
  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      // 3. JSON key는 Spring Boot DTO의 필드명(camelCase)과 일치해야 함
      breedNameEn: json['breedNameEn'],
      breedNameKo: json['breedNameKo'],
      imageUrl: json['imageUrl'], // 👈 4. 'imageUrl' 키로 오는 null 값을 허용
      score: json['score'],
    );
  }
}