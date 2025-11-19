import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_config.dart';
import 'member.dart';

class EditProfileScreen extends StatefulWidget {
  final Member member;
  const EditProfileScreen({super.key, required this.member});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member.name);
    _passwordController = TextEditingController();
  }

  Future<void> _updateProfile() async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/members/${widget.member.id}');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text,
          'password': _passwordController.text.isNotEmpty ? _passwordController.text : null,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // 수정된 정보로 Member 객체 갱신하여 반환
        final updatedMember = Member.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
        Navigator.pop(context, updatedMember);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('정보가 수정되었습니다.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('수정 실패')));
      }
    } catch (e) {
      // 에러 처리
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원 정보 수정')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '이름', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '새 비밀번호 (변경 시에만 입력)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: const Text('저장하기'),
              ),
            )
          ],
        ),
      ),
    );
  }
}