// lib/analysis_result.dart
class AnalysisResult {
  final String breedNameEn;
  final String breedNameKo;
  final String? imageUrl;
  final double score;

  AnalysisResult({
    required this.breedNameEn,
    required this.breedNameKo,
    this.imageUrl, // nullable
    required this.score,
  });

  // JSON(Map)을 AnalysisResult 객체로 변환
  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      breedNameEn: json['breed_name_en'],
      breedNameKo: json['breed_name_ko'],
      imageUrl: json['image_url'], // JSON에 'image_url'이 null일 수 있음
      score: json['score'],
    );
  }
}