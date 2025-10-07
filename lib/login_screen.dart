import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoginTabSelected = true;

  // 추가: 각 입력창의 값을 가져오기 위한 컨트롤러
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 추가: 회원가입 API를 호출하는 함수
  Future<void> signUp() async {
    // 안드로이드 에뮬레이터에서는 localhost 대신 10.0.2.2를 사용
    final url = Uri.parse('http://10.0.2.2:8080/api/members/join');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          // 'name' 필드 추가
          'name': _nameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      // 위젯이 아직 화면에 있는지 확인 후 UI 업데이트
      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('회원가입 성공: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입에 성공했습니다! 로그인을 진행해주세요.')),
        );
        // 성공 시 로그인 탭으로 전환
        setState(() {
          isLoginTabSelected = true;
        });
      } else {
        print('회원가입 실패: ${response.statusCode}');
        print('응답 내용: ${response.body}');
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

  @override
  Widget build(BuildContext context) {
    // 전체 UI 구조는 이전과 동일
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
                  const Text('PetCare AI', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('반려견의 건강한 삶을 위한 AI 파트너', style: TextStyle(color: Colors.white70, fontSize: 14)),
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
                        const Text('환영합니다', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
    // ... 이전과 동일
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
                setState(() { isLoginTabSelected = true; });
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
                setState(() { isLoginTabSelected = false; });
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
    // 수정: 로그인 필드에 맞게 수정 (이메일, 비밀번호)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('이메일', style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 8),
        buildTextField('이메일을 입력하세요', controller: _emailController),
        const SizedBox(height: 16),
        Text('비밀번호', style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 8),
        buildTextField('비밀번호를 입력하세요', obscureText: true, controller: _passwordController),
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
    // 수정: 회원가입 필드에 맞게 수정 (이름, 이메일, 비밀번호)
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
        buildTextField('비밀번호를 입력하세요', obscureText: true, controller: _passwordController),
        const SizedBox(height: 32),
        ElevatedButton(
          // 수정: onPressed에 signUp 함수 연결
          onPressed: signUp,
          style: buildButtonStyle(),
          child: const Text('회원가입', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  // 수정: controller를 받을 수 있도록 파라미터 추가
  Widget buildTextField(String hintText, {bool obscureText = false, TextEditingController? controller}) {
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

// 추가: 로그인 API를 호출하는 함수
  Future<void> login() async {
    final url = Uri.parse('http://10.0.2.2:8080/api/members/login');
    try {
      final response = await http.post(
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
        // 로그인 성공 시 홈 화면으로 이동 (뒤로가기 X)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        print('로그인 실패: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이메일 또는 비밀번호가 일치하지 않습니다.')),
        );
      }
    } catch (e) {
      print('로그인 에러: $e');
    }
  }

  ButtonStyle buildButtonStyle() {
    // ... 이전과 동일
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