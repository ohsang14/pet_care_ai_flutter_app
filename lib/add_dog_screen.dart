import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'member.dart';

class AddDogScreen extends StatefulWidget {
  final Member member;
  const AddDogScreen({super.key, required this.member});

  @override
  State<AddDogScreen> createState() => _AddDogScreenState();
}

class _AddDogScreenState extends State<AddDogScreen> {
  final _nameController = TextEditingController();
  DateTime? _selectedBirthDate; // 선택된 생년월일을 저장할 변수

  // '저장' 버튼 눌렀을 때 실행될 API 호출 함수
  Future<void> _saveDog() async {
    // 1. 서버 API 주소 (우리가 Postman으로 테스트한 주소)
    // ${widget.member.id}를 통해 현재 로그인한 회원의 ID를 주소에 포함
    final url =
    Uri.parse('http://10.0.2.2:8080/api/members/${widget.member.id}/dogs');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text,
          // 2. 날짜를 'YYYY-MM-DD' 형식의 문자열로 변환
          'birthDate': _selectedBirthDate?.toIso8601String().split('T').first,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        // 3. 성공 시 (201 Created)
        print('반려견 등록 성공: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('반려견이 성공적으로 등록되었습니다!')),
        );
        // 등록 성공 후, 이전 화면(홈 화면)으로 돌아가기
        Navigator.pop(context);
      } else {
        // 4. 실패 시
        print('반려견 등록 실패: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('등록에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    } catch (e) {
      print('반려견 등록 에러: $e');
    }
  }

  // 날짜 선택 팝업을 띄우는 함수
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 반려견 등록'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 이름 입력창
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '이름',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 생년월일 선택
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedBirthDate == null
                        ? '생년월일을 선택해주세요'
                        : '생년월일: ${_selectedBirthDate!.toLocal().toString().split(' ')[0]}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: const Text('날짜 선택'),
                ),
              ],
            ),
            const SizedBox(height: 40),
            // 저장 버튼
            ElevatedButton(
              onPressed: _saveDog, // 5. 저장 버튼에 API 호출 함수 연결
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
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
}
