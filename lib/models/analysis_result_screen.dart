// lib/analysis_result_screen.dart
import 'package:flutter/material.dart';
import 'analysis_reslult.dart';

class AnalysisResultScreen extends StatelessWidget {
  final List<AnalysisResult> results;

  const AnalysisResultScreen({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    // 1등 결과
    final topResult = results.first;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('AI 품종 분석 결과'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1등 결과 강조 카드
            _buildTopResultCard(topResult),
            const SizedBox(height: 24),

            // 기타 가능성
            const Text(
              '기타 가능성',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // 2등, 3등 결과 리스트
            Expanded(
              child: ListView.builder(
                itemCount: results.length - 1, // 1등은 제외
                itemBuilder: (context, index) {
                  final result = results[index + 1]; // 2등, 3등
                  return _buildOtherResultTile(result);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1등 결과를 보여줄 카드
  Widget _buildTopResultCard(AnalysisResult result) {
    return Card(
      color: Colors.white,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // --- 대표 이미지 표시 ---
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              // 이미지 URL이 유효한지 확인
              child: (result.imageUrl != null && result.imageUrl!.isNotEmpty)
                  ? Image.network(
                // result.imageUrl!,
                'https://placehold.co/150x150/EFEFEF/333333?text=Test',
                height: 150,
                width: 150,
                fit: BoxFit.cover,
                // 로딩 중 표시
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 150,
                    width: 150,
                    color: Colors.grey[200],
                    child:
                    const Center(child: CircularProgressIndicator()),
                  );
                },
                // 에러 발생 시 (URL이 잘못되었거나, 네트워크 문제)
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    width: 150,
                    color: Colors.grey[200],
                    child: const Icon(Icons.error,
                        color: Colors.red, size: 60),
                  );
                },
              )
                  : Container(
                // 이미지 URL이 null이거나 비어있을 때
                height: 150,
                width: 150,
                color: Colors.grey[200],
                child: const Icon(Icons.pets,
                    size: 60, color: Colors.blueAccent),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '가장 유력한 품종은...',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            // --- 한국어 이름 표시 ---
            Text(
              result.breedNameKo, // 한국어 이름
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '${(result.score * 100).toStringAsFixed(1)}% 확률',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2, 3등 결과를 보여줄 리스트 타일
  Widget _buildOtherResultTile(AnalysisResult result) {
    return Card(
      color: Colors.grey[800],
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        // --- 대표 이미지 표시 ---
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: (result.imageUrl != null && result.imageUrl!.isNotEmpty)
              ? Image.network(
            result.imageUrl!,
            height: 50,
            width: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 50,
                width: 50,
                color: Colors.grey[700],
                child: const Icon(Icons.pets, color: Colors.white60),
              );
            },
          )
              : Container(
            height: 50,
            width: 50,
            color: Colors.grey[700],
            child: const Icon(Icons.pets, color: Colors.white60),
          ),
        ),
        // --- 한국어 이름 표시 ---
        title: Text(
          result.breedNameKo, // 한국어 이름
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Text(
          '${(result.score * 100).toStringAsFixed(1)}%',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}