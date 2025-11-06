import 'dart:convert'; // jsonDecode, utf8
import 'dart:io'; // File
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'models/analysis_reslult.dart';
import 'models/analysis_result_screen.dart'; // 1. image_picker import

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  // 4. 선택된 이미지 파일을 저장할 변수 (dart:io의 File)
  File? _imageFile;
  // 5. 로딩 상태를 관리할 변수
  bool _isLoading = false;
  // 6. image_picker 인스턴스 생성
  final ImagePicker _picker = ImagePicker();

  // 7. 갤러리 또는 카메라에서 이미지를 가져오는 함수
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        // .HEIC 파일을 .jpg로 변환하는 작업 (선택 사항이지만 권장)
        // 여기서는 우선 선택한 파일 그대로 사용합니다.
        // 만약 .jpg/.png가 아니면 Python 서버에서 에러가 날 수 있습니다.
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('이미지 선택 에러: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지를 가져오는 데 실패했습니다: $e')),
      );
    }
  }

  // 8. 이미지를 서버로 전송하고 분석을 요청하는 함수
  Future<void> _analyzeImage() async {
    if (_imageFile == null) return;

    // 9. 로딩 시작
    setState(() {
      _isLoading = true;
    });

    // 10. Spring Boot 서버의 '중계' API 주소
    final url = Uri.parse('http://10.0.2.2:8080/api/analysis/breed');

    try {
      // 11. 파일을 전송하기 위해 MultipartRequest 생성
      var request = http.MultipartRequest('POST', url);

      // 12. 'file'이라는 키로 이미지 파일 추가
      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // Spring Boot에서 @RequestParam("file")로 받을 키
          _imageFile!.path,
        ),
      );

      // 13. 요청 전송 및 응답 받기
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200) {
        // 14. 성공! (Python 서버가 보낸 JSON 배열이 도착)
        final List<dynamic> responseData =
        jsonDecode(utf8.decode(response.bodyBytes));

        // 15. JSON 배열을 List<AnalysisResult>로 변환
        final List<AnalysisResult> results =
        responseData.map((data) => AnalysisResult.fromJson(data)).toList();

        // 16. 결과 화면으로 이동 (결과 리스트 전달)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnalysisResultScreen(results: results),
          ),
        );
      } else {
        // 17. 실패
        print('분석 실패: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지 분석에 실패했습니다.')),
        );
      }
    } catch (e) {
      print('분석 요청 에러: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버 통신 중 에러가 발생했습니다.')),
      );
    } finally {
      // 18. 로딩 종료
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('AI 품종 분석'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      // 19. 로딩 중이면 스피너, 아니면 화면 표시
      body: _isLoading
          ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('AI가 사진을 분석하고 있습니다...\n잠시만 기다려주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ))
          : _buildImageUploader(),
    );
  }

  // 20. Figma 디자인과 유사한 이미지 업로더 UI
  Widget _buildImageUploader() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 21. 이미지 미리보기 또는 업로드 영역
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[700]!, width: 2),
            ),
            // 22. _imageFile 상태에 따라 다른 위젯 표시
            child: _imageFile == null
                ? const Center(
              child: Icon(Icons.pets, color: Colors.white54, size: 100),
            )
                : ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                _imageFile!,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 23. 갤러리에서 선택 버튼
          ElevatedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('갤러리에서 선택'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          // 24. 카메라로 촬영 버튼
          ElevatedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('카메라로 촬영'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.grey[700],
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 32),

          // 25. 분석하기 버튼 (이미지가 있을 때만 활성화)
          ElevatedButton(
            onPressed: _imageFile == null ? null : _analyzeImage,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey,
            ),
            child: const Text('분석하기', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}