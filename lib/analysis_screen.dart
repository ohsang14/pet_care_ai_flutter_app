import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'app_config.dart';
import 'models/analysis_reslult.dart'; // 👈 'analysis_result.dart'로 오타 수정 필요
import 'models/analysis_result_screen.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  File? _imageFile;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // 강아지/고양이 선택 상태. 기본값은 "dog"
  String _petType = "dog";

  // Spring Boot 서버 URL (Android 에뮬레이터에서 로컬 PC 접근 시 사용)
  

  // 이미지 선택 함수 (갤러리/카메라)
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('이미지 선택 에러: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지를 가져오는 데 실패했습니다: $e')),
        );
      }
    }
  }

  // 이미지 분석 요청 함수
  Future<void> _analyzeImage() async {
    if (_imageFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('분석할 이미지를 먼저 선택해주세요.')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 선택된 _petType에 따라 동적으로 API 엔드포인트 결정
    final String apiEndpoint = _petType == "dog" ? "/dog" : "/cat";
    final url = Uri.parse('${AppConfig.baseUrl}/api/analysis$apiEndpoint');

    print('INFO: 호출하는 API URL: $url (펫 타입: $_petType)'); // 디버깅용 로그

    try {
      var request = http.MultipartRequest('POST', url);
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _imageFile!.path,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200) {
        print('분석 성공');
        final List<dynamic> responseData =
        jsonDecode(utf8.decode(response.bodyBytes));

        final List<AnalysisResult> results =
        responseData.map((data) => AnalysisResult.fromJson(data)).toList();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnalysisResultScreen(results: results),
          ),
        );
      } else {
        print('분석 실패: ${response.statusCode}, ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('분석에 실패했습니다. (${response.statusCode})')),
        );
      }
    } catch (e) {
      print('분석 요청 에러: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('서버 통신 중 에러가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      body: _isLoading
          ? _buildLoadingIndicator() // 로딩 중 UI
          : _buildMainContent(),    // 메인 콘텐츠 UI
    );
  }

  // 로딩 중일 때 표시할 UI
  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 20),
          Text(
            'AI가 사진을 분석하고 있습니다...\n잠시만 기다려주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // 메인 콘텐츠 (이미지 선택 및 버튼) UI
  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0), // Padding 조정
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPetTypeSelector(), // 강아지/고양이 선택 UI
          const SizedBox(height: 24),

          _buildImagePreview(), // 이미지 미리보기/업로드 영역
          const SizedBox(height: 32),

          _buildActionButton(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: Icons.photo_library,
            label: '갤러리에서 선택',
            backgroundColor: Colors.blueAccent,
          ),
          const SizedBox(height: 16),

          _buildActionButton(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: Icons.camera_alt,
            label: '카메라로 촬영',
            backgroundColor: Colors.grey[700]!,
          ),
          const SizedBox(height: 40),

          _buildAnalyzeButton(), // 분석하기 버튼
        ],
      ),
    );
  }

  // ======== ✅ 여기가 수정된 부분 =========
  // 강아지/고양이 선택 토글 버튼 UI (MediaQuery로 수정)
  Widget _buildPetTypeSelector() {

    // 1. 화면의 전체 너비를 가져옵니다.
    final double screenWidth = MediaQuery.of(context).size.width;

    // 2. SingleChildScrollView의 좌우 패딩 값 (각 24.0)
    final double horizontalPadding = 24.0 * 2;

    // 3. ToggleButtons가 차지할 수 있는 실제 너비
    final double availableWidth = screenWidth - horizontalPadding;

    // 4. ToggleButtons는 버튼 사이에 1px 구분선을 가집니다.
    //    (실제 너비 / 2)를 한 뒤, 테두리 여유 공간(2px)을 뺍니다.
    final double buttonWidth = (availableWidth / 2) - 2.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      // 5. 'constraints' 속성을 제거합니다.
      child: ToggleButtons(
        isSelected: [_petType == "dog", _petType == "cat"],
        onPressed: (int index) {
          setState(() {
            _petType = (index == 0) ? "dog" : "cat";
          });
        },
        borderRadius: BorderRadius.circular(12),
        fillColor: Colors.blueAccent,
        selectedColor: Colors.white,
        color: Colors.white70,
        borderColor: Colors.grey[700],
        selectedBorderColor: Colors.blueAccent,
        splashColor: Colors.blueAccent.withOpacity(0.3),
        highlightColor: Colors.blueAccent.withOpacity(0.1),

        // 6. 'children'의 각 Row를 'SizedBox'로 감싸서 너비를 강제합니다.
        children: [
          SizedBox(
            width: buttonWidth, // 👈 너비 지정
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pets),
                SizedBox(width: 8),
                Text('강아지', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          SizedBox(
            width: buttonWidth, // 👈 너비 지정
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flare),
                SizedBox(width: 8),
                Text('고양이', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // ======== ✅ 여기까지 수정된 부분 =========


  // 이미지 미리보기/업로드 영역 UI
  Widget _buildImagePreview() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[700]!, width: 2),
      ),
      child: _imageFile == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _petType == "dog" ? Icons.pets : Icons.flare, // 선택된 동물에 따라 아이콘 변경
              color: Colors.white54,
              size: 100,
            ),
            const SizedBox(height: 10),
            Text(
              '${_petType == "dog" ? "강아지" : "고양이"} 사진을 업로드 해주세요',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      )
          : ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.file(
          _imageFile!,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // 공통 버튼 UI 빌더
  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // 분석하기 버튼 UI
  Widget _buildAnalyzeButton() {
    return ElevatedButton(
      onPressed: _imageFile == null ? null : _analyzeImage,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text('분석하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}