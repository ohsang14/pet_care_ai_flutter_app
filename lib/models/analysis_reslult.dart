class AnalysisResult {
  final String breedName;
  final double score;

  AnalysisResult({required this.breedName, required this.score});

  // JSON(Map)을 AnalysisResult 객체로 변환
  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      breedName: json['breed_name'],
      score: json['score'],
    );
  }
}