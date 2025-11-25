import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'app_config.dart';
import 'main_screen.dart';
import 'models/member.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoginTab = true; // 로그인/회원가입 탭 상태

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // 이메일 로그인
  Future<void> _emailLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    setState(() { _isLoading = true; });

    final url = Uri.parse('${AppConfig.baseUrl}/api/members/login');
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
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        final member = Member.fromJson(responseData);
        Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => MainScreen(member: member)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인 실패: 이메일/비번을 확인하세요.')));
      }
    } catch (e) {
      print(e);
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // 이메일 회원가입
  Future<void> _emailSignUp() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    setState(() { _isLoading = true; });

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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('가입 성공! 로그인해주세요.')));
        setState(() { isLoginTab = true; }); // 로그인 탭으로 이동
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('가입 실패. 이미 존재하는 이메일일 수 있습니다.')));
      }
    } catch (e) {
      print(e);
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // 🟡 카카오 로그인 (수정됨)
  Future<void> _kakaoLogin() async {
    try {
      // 1. 카카오톡 설치 여부 확인
      bool isInstalled = await isKakaoTalkInstalled();
      OAuthToken token;

      if (isInstalled) {
        try {
          token = await UserApi.instance.loginWithKakaoTalk();
        } catch (error) {
          if (error is PlatformException && error.code == 'CANCELED') return;
          token = await UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      print('카카오 인증 성공! 토큰: ${token.accessToken}');

      // [중요] 이메일 조회 로직(UserApi.instance.me)은 제거합니다.
      // 대신, 토큰을 그대로 백엔드 서버로 보냅니다.
      if (!mounted) return;
      await _sendKakaoTokenToServer(token.accessToken);

    } catch (error) {
      print('카카오 로그인 실패: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카카오 로그인에 실패했습니다.')),
      );
    }
  }
// [수정됨] 서버로 '토큰'을 전송하는 함수
  Future<void> _sendKakaoTokenToServer(String accessToken) async {
    setState(() { _isLoading = true; });

    // 백엔드 엔드포인트 확인
    final url = Uri.parse('${AppConfig.baseUrl}/api/members/kakao');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        // ⭐️ [핵심] 백엔드 DTO의 변수명(accessToken)과 정확히 일치시켜야 함!
        body: jsonEncode({
          'accessToken': accessToken,
        }),
      );

      print('서버 응답 코드: ${response.statusCode}');
      print('서버 응답 본문: ${utf8.decode(response.bodyBytes)}');

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 로그인 성공!
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        final member = Member.fromJson(responseData);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen(member: member)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('서버 로그인 실패: 잠시 후 다시 시도해주세요.'))
        );
      }
    } catch (e) {
      print('서버 통신 에러: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('서버와 연결할 수 없습니다.'))
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD), // 밝은 배경
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고 영역
              const Icon(Icons.pets, size: 60, color: Color(0xFF6C63FF)),
              const SizedBox(height: 16),
              const Text(
                'PetCare AI',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text('우리 아이 건강 지킴이', style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 40),

              // 입력 폼 카드
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    // 탭 전환 (로그인 / 회원가입)
                    Row(
                      children: [
                        _buildTabButton('로그인', true),
                        _buildTabButton('회원가입', false),
                      ],
                    ),
                    const SizedBox(height: 30),

                    if (!isLoginTab) ...[
                      _buildTextField('이름', _nameController, Icons.person_outline),
                      const SizedBox(height: 16),
                    ],
                    _buildTextField('이메일', _emailController, Icons.email_outlined),
                    const SizedBox(height: 16),
                    _buildTextField('비밀번호', _passwordController, Icons.lock_outline, obscureText: true),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : (isLoginTab ? _emailLogin : _emailSignUp),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(isLoginTab ? '로그인' : '회원가입', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 소셜 로그인 구분선
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('또는', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 30),

              // 🟡 카카오 로그인 버튼
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _kakaoLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE500), // 카카오 노란색
                    foregroundColor: const Color(0xFF191919), // 카카오 검은색
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble, size: 20), // 카카오 아이콘 대용
                      SizedBox(width: 10),
                      Text('카카오로 시작하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String text, bool isLogin) {
    final isSelected = isLoginTab == isLogin;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isLoginTab = isLogin),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent, width: 2)),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? const Color(0xFF6C63FF) : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey[400]),
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: const Color(0xFFF8F9FD),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}