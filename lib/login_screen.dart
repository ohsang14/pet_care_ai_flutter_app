import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_config.dart'; // 👈 1. [추가] AppConfig import
import 'member.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoginTabSelected = true;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 회원가입 함수
  Future<void> signUp() async {
    // 2. [수정] AppConfig.baseUrl 사용
    final url = Uri.parse('${AppConfig.baseUrl}/api/members/join');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('회원가입 성공: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입에 성공했습니다! 로그인을 진행해주세요.')),
        );
        setState(() {
          isLoginTabSelected = true;
        });
      } else {
        print('회원가입 실패: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    } catch (e) {
      print('에러 발생: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버와 통신 중 에러가 발생했습니다.')),
      );
    }
  }

  // 로그인 함수
  // 로그인 함수
  Future<void> login() async {
    // 1. [디버깅] 현재 사용 중인 주소 확인하기
    print("DEBUG: 현재 감지된 플랫폼 주소 = ${AppConfig.baseUrl}");

    final url = Uri.parse('${AppConfig.baseUrl}/api/members/login');

    print("DEBUG: 실제 요청 보내는 URL = $url"); // URL 확인

    try {
      final response = await http.post(
        // ... (이하 코드 동일)
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        print('로그인 성공');

        final Map<String, dynamic> responseData =
        jsonDecode(utf8.decode(response.bodyBytes));

        final Member loggedInMember = Member.fromJson(responseData);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(member: loggedInMember),
          ),
        );
      } else {
        print('로그인 실패: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이메일 또는 비밀번호가 일치하지 않습니다.')),
        );
      }
    } catch (e) {
      print('로그인 에러: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 중 에러가 발생했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.black,
                    child: Icon(Icons.favorite, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text('PetCare AI',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('반려견의 건강한 삶을 위한 AI 파트너',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('환영합니다',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        buildTabSwitcher(),
                        const SizedBox(height: 24),
                        if (isLoginTabSelected)
                          buildLoginFields()
                        else
                          buildSignupFields(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTabSwitcher() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isLoginTabSelected = true;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isLoginTabSelected ? Colors.white : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('로그인')),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isLoginTabSelected = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isLoginTabSelected ? Colors.white : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('회원가입')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLoginFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('이메일', style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 8),
        buildTextField('이메일을 입력하세요', controller: _emailController),
        const SizedBox(height: 16),
        Text('비밀번호', style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 8),
        buildTextField('비밀번호를 입력하세요',
            obscureText: true, controller: _passwordController),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: login,
          style: buildButtonStyle(),
          child: const Text('로그인', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget buildSignupFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('이름', style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 8),
        buildTextField('이름을 입력하세요', controller: _nameController),
        const SizedBox(height: 16),
        Text('이메일', style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 8),
        buildTextField('이메일을 입력하세요', controller: _emailController),
        const SizedBox(height: 16),
        Text('비밀번호', style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 8),
        buildTextField('비밀번호를 입력하세요',
            obscureText: true, controller: _passwordController),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: signUp,
          style: buildButtonStyle(),
          child: const Text('회원가입', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget buildTextField(String hintText,
      {bool obscureText = false, TextEditingController? controller}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  ButtonStyle buildButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}