import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'app_config.dart';
import 'analysis_result_screen.dart';
import 'models/analysis_reslult.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  XFile? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String _petType = "dog"; // 기본값 강아지

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      setState(() { _image = pickedFile; });
    } catch (e) { print("이미지 선택 에러: $e"); }
  }

  Future<void> _analyzeImage() async {
    if (_image == null) return;
    setState(() { _isLoading = true; });

    final apiEndpoint = _petType == "dog" ? "/dog" : "/cat";
    final url = Uri.parse('${AppConfig.baseUrl}/api/analysis$apiEndpoint');

    try {
      var request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath('file', _image!.path));
      var response = await http.Response.fromStream(await request.send());

      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));

        // ⭐️ [중요] 분석 결과 생성
        final results = responseData.map((data) => AnalysisResult.fromJson(data)).toList();

        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AnalysisResultScreen(results: results))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('분석 실패')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('에러: $e')));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD), // 밝은 배경
      appBar: AppBar(
        title: const Text('AI 품종 분석'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '어떤 친구인지 궁금한가요?\n사진을 올려주세요!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            _buildPetTypeSelector(),
            const SizedBox(height: 30),

            // 📸 이미지 업로드 영역 (미리보기 포함)
            Container(
              height: 320,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[200]!, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: _image == null
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('터치하여 사진 선택', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                ],
              )
                  : ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.file(File(_image!.path), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(child: _buildActionButton(onPressed: () => _pickImage(ImageSource.gallery), icon: Icons.photo_library, label: '갤러리', backgroundColor: Colors.white, textColor: Colors.black87)),
                const SizedBox(width: 16),
                Expanded(child: _buildActionButton(onPressed: () => _pickImage(ImageSource.camera), icon: Icons.camera_alt, label: '카메라', backgroundColor: Colors.white, textColor: Colors.black87)),
              ],
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _image == null || _isLoading ? null : _analyzeImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF), // 포인트 컬러
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
                shadowColor: const Color(0xFF6C63FF).withOpacity(0.4),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('분석 시작하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _buildTypeOption("강아지", Icons.pets, "dog"),
          _buildTypeOption("고양이", Icons.catching_pokemon, "cat"), // 아이콘 변경
        ],
      ),
    );
  }

  Widget _buildTypeOption(String label, IconData icon, String type) {
    bool isSelected = _petType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _petType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({required VoidCallback onPressed, required IconData icon, required String label, required Color backgroundColor, required Color textColor}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: textColor),
      label: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[300]!)),
        elevation: 0,
      ),
    );
  }
}