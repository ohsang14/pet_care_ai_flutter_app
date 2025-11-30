import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:url_launcher/url_launcher.dart'; // 👈 [추가] 약관 링크용 패키지
import 'package:mypet/service/storage_service.dart'; // 👈 [추가] 자동 로그인용
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

  // 🔗 [추가] URL 열기 함수 (이용약관/개인정보)
  Future<void> _launchUrl(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      print('URL 열기 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('페이지를 열 수 없습니다.')),
        );
      }
    }
  }

  // 📧 이메일 로그인
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

        // ⭐️ [중요] 로그인 성공 시 기기에 정보 저장 (자동 로그인)
        await StorageService.saveMember(member);

        Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => MainScreen(member: member)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인 실패: 이메일/비번을 확인하세요.')));
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('서버 연결 오류가 발생했습니다.')));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // 📧 이메일 회원가입
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('서버 연결 오류가 발생했습니다.')));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // 🟡 카카오 로그인
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

  // 🟡 카카오 토큰 서버 전송
  Future<void> _sendKakaoTokenToServer(String accessToken) async {
    setState(() { _isLoading = true; });

    final url = Uri.parse('${AppConfig.baseUrl}/api/members/kakao');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'accessToken': accessToken,
        }),
      );

      print('서버 응답 코드: ${response.statusCode}');

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 로그인 성공!
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        final member = Member.fromJson(responseData);

        // ⭐️ [중요] 카카오 로그인도 기기에 정보 저장
        await StorageService.saveMember(member);

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
      backgroundColor: const Color(0xFFF8F9FD),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pets, size: 60, color: Color(0xFF6C63FF)),
              const SizedBox(height: 16),
              const Text(
                'PetCare AI',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text('우리 아이 건강 지킴이', style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
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

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _kakaoLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE500),
                    foregroundColor: const Color(0xFF191919),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble, size: 20),
                      SizedBox(width: 10),
                      Text('카카오로 시작하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40), // 하단 여백 확보

              // ⚖️ [추가됨] 이용약관 및 개인정보 처리방침 (앱스토어 필수)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => _launchUrl('https://policies.google.com/terms'), // TODO: 실제 약관 URL로 변경
                    child: Text('이용약관', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ),
                  Text('|', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  TextButton(
                    onPressed: () => _launchUrl('https://policies.google.com/privacy'), // TODO: 실제 개인정보 처리방침 URL로 변경
                    child: Text('개인정보 처리방침', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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