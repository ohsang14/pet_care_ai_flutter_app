class AnalysisResult {
  final String breedNameEn;
  final String breedNameKo; // 한글 이름
  final String? imageUrl; // 👈 이미지 URL 필드 추가
  final double score; // 확률 (0.0 ~ 1.0)
  final String? temperament;
  final String? lifeSpan;

  AnalysisResult({
    required this.breedNameEn,
    required this.breedNameKo,
    this.imageUrl, // 👈 생성자에 추가
    required this.score,
    this.temperament,
    this.lifeSpan,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      breedNameEn: json['breedNameEn'],
      breedNameKo: json['breedNameKo'],
      imageUrl: json['imageUrl'], // 👈 JSON 매핑 추가 (서버에서 이 키로 보낸다고 가정)
      score: json['score'],
      temperament: json['temperament'],
      lifeSpan: json['lifeSpan'],
    );
  }
}