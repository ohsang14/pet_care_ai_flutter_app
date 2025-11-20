import 'package:flutter/material.dart';
import 'models/analysis_reslult.dart';
import 'app_config.dart';
class AnalysisResultScreen extends StatelessWidget {
  final List<AnalysisResult> results;

  const AnalysisResultScreen({super.key, required this.results});

  // 이미지 URL 처리 헬퍼 함수 (중복 코드 제거)
  String? _getProcessedImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return null;
    if (rawUrl.startsWith('http')) {
      return rawUrl; // 외부 링크면 그대로 사용
    } else {
      return '${AppConfig.baseUrl}$rawUrl'; // 내부 파일이면 서버 주소 붙임
    }
  }

  @override
  Widget build(BuildContext context) {
    final topResult = results.isNotEmpty ? results.first : null;
    final otherResults = results.length > 1 ? results.sublist(1).take(2).toList() : [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('분석 결과', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (topResult != null) _buildTopCard(context, topResult),
            if (otherResults.isNotEmpty) ...[
              const SizedBox(height: 30),
              const Text('다른 가능성', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 15),
              ...otherResults.map((r) => _buildOtherItem(r)).toList(),
            ],
            if (topResult == null && otherResults.isEmpty)
              const Center(child: Text('분석 결과가 없습니다.', style: TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCard(BuildContext context, AnalysisResult result) {
    // 헬퍼 함수로 URL 처리
    final fullImageUrl = _getProcessedImageUrl(result.imageUrl);

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: fullImageUrl != null
                ? Image.network(
              fullImageUrl,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildErrorImage(height: 220),
            )
                : _buildPlaceholderImage(height: 220),
          ),
          const SizedBox(height: 25),
          Text(result.breedNameKo, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.black87)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFEEEDFF), borderRadius: BorderRadius.circular(20)),
            child: Text('${(result.score * 100).toStringAsFixed(1)}% 일치', style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherItem(AnalysisResult result) {
    // 헬퍼 함수로 URL 처리
    final fullImageUrl = _getProcessedImageUrl(result.imageUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Row(
        children: [
          // 하단 리스트에도 이미지 표시
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: fullImageUrl != null
                ? Image.network(
              fullImageUrl,
              width: 60, height: 60, fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildErrorImage(width: 60, height: 60, iconSize: 24),
            )
                : _buildPlaceholderImage(width: 60, height: 60, iconSize: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(result.breedNameKo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
          Text('${(result.score * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage({double? width, double? height, double iconSize = 50}) {
    return Container(width: width, height: height, color: Colors.grey[100], child: Icon(Icons.pets, size: iconSize, color: Colors.grey[300]));
  }

  Widget _buildErrorImage({double? width, double? height, double iconSize = 50}) {
    return Container(width: width, height: height, color: Colors.grey[100], child: Icon(Icons.broken_image_outlined, size: iconSize, color: Colors.grey[400]));
  }
}