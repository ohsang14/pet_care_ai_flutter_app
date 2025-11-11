import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'models/dog.dart'; // Dog 모델

class AddSymptomScreen extends StatefulWidget {
  final Dog dog; // 👈 SymptomListScreen에서 전달받은 반려견 객체
  const AddSymptomScreen({super.key, required this.dog});

  @override
  State<AddSymptomScreen> createState() => _AddSymptomScreenState();
}

class _AddSymptomScreenState extends State<AddSymptomScreen> {
  // 1. 텍스트 입력을 제어하기 위한 컨트롤러
  final _symptomController = TextEditingController();
  final _memoController = TextEditingController();

  bool _isLoading = false;

  // Spring Boot 서버 URL (Android 에뮬레이터 기준)
  final String _baseUrl = "http://10.0.2.2:8080";
  // (만약 iOS 또는 데스크탑을 사용 중이라면 "http://localhost:8080"로 변경)


  // '저장하기' 버튼을 눌렀을 때 실행되는 함수
  Future<void> _saveSymptom() async {
    // 2. '주요 증상'은 필수 항목으로 검증
    if (_symptomController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주요 증상을 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // 로딩 시작
    });

    // 3. API URL (POST /api/dogs/{dogId}/symptoms)
    final url = Uri.parse('$_baseUrl/api/dogs/${widget.dog.id}/symptoms');

    try {
      // 4. Spring Boot의 SymptomLogRequestDto와 일치하는 JSON 본문 생성
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'symptom': _symptomController.text, // 주요 증상
          'memo': _memoController.text,       // 상세 메모
          // 'logDate'는 보내지 않으면 서버(Spring)가 자동으로 현재 시간을 입력합니다.
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) { // 201 CREATED (저장 성공)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('증상이 성공적으로 기록되었습니다.')),
        );
        // 5. 저장 성공 시, true 값을 반환하며 이전 화면(SymptomListScreen)으로 복귀
        Navigator.pop(context, true);
      } else {
        print('증상 저장 실패: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    } catch (e) {
      print('증상 저장 에러: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('서버 통신 중 에러가 발생했습니다.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // 로딩 종료
        });
      }
    }
  }

  @override
  void dispose() {
    // 화면이 종료될 때 컨트롤러 리소스를 해제합니다.
    _symptomController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text("'${widget.dog.name}' 증상 추가"),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(
              controller: _symptomController,
              labelText: '주요 증상 *',
              hintText: '예: 구토, 설사, 기침, 잦은 긁음 등',
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _memoController,
              labelText: '상세 메모 (선택)',
              hintText: '예: 노란색 토를 2번 했음, 사료 먹은 직후',
              maxLines: 5, // 여러 줄 입력 가능
            ),
            const SizedBox(height: 40),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _saveSymptom, // 👈 저장 함수 연결
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // 저장 버튼
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('저장하기', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  // 텍스트 필드 스타일을 위한 헬퍼 위젯
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white), // 입력 글자색
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.white70),
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder( // 기본 테두리
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder( // 포커스 시 테두리
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
    );
  }
}