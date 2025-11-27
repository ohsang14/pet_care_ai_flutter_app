import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:mypet/service/storage_service.dart';
import 'app_config.dart';
import 'models/health_check.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'models/member.dart';

class MyPageScreen extends StatefulWidget {
  final Member member;
  const MyPageScreen({super.key, required this.member});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  late Member _member;
  List<HealthCheck> _historyList = [];
  bool _isLoading = true;
  int _totalCount = 0;
  double _averageScore = 0.0;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
    _fetchMyHistory();
  }

  Future<void> _fetchMyHistory() async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/members/${_member.id}/health-checks');
    try {
      final response = await http.get(url);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
        final List<HealthCheck> loadedList = responseData.map((data) => HealthCheck.fromJson(data)).toList();

        int sumScore = 0;
        for (var check in loadedList) sumScore += check.totalScore;
        double avg = loadedList.isNotEmpty ? sumScore / loadedList.length : 0.0;

        setState(() {
          _historyList = loadedList;
          _totalCount = loadedList.length;
          _averageScore = avg;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _navigateToEditProfile() async {
    final updatedMember = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfileScreen(member: _member)),
    );
    if (updatedMember != null && updatedMember is Member) {
      setState(() { _member = updatedMember; });
      // 프로필 수정 후에도 최신 정보를 저장소에 업데이트하는 것이 좋습니다.
      await StorageService.saveMember(_member);
    }
  }

  // 👋 로그아웃 (수정됨)
  void _logout() async {
    await StorageService.deleteMember();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  // 🗑️ 회원 탈퇴 로직 (수정됨)
  Future<void> _deleteAccount() async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/members/${_member.id}');

    try {
      // 1. Spring Boot 서버에 삭제 요청 (DB 데이터 삭제)
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        print("서버 데이터 삭제 성공");

        // ⭐️ [추가] 기기에 저장된 로그인 정보 삭제 (자동 로그인 해제)
        await StorageService.deleteMember();

        // 2. 카카오 연동 끊기
        if (_member.kakaoId != null && _member.kakaoId != 0) {
          try {
            await UserApi.instance.unlink();
            print('카카오 연결 끊기 성공');
          } catch (e) {
            print('카카오 연결 끊기 실패 (이미 끊겼거나 오류): $e');
          }
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원 탈퇴가 완료되었습니다.')),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('탈퇴 실패: 서버 통신 오류')),
        );
      }
    } catch (e) {
      print('탈퇴 오류: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('오류가 발생했습니다. 잠시 후 다시 시도해주세요.')),
      );
    }
  }

  // 🔔 탈퇴 확인 팝업
  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원 탈퇴', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          '정말로 탈퇴하시겠습니까?\n\n탈퇴 시 등록된 반려견 정보와\n모든 건강 기록이 영구적으로 삭제됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 팝업 닫기
              _deleteAccount(); // 실제 탈퇴 진행
            },
            child: const Text('탈퇴하기', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 프로필 이미지 URL 처리
    String? profileUrl;
    if (_member.profileImageUrl != null && _member.profileImageUrl!.isNotEmpty) {
      profileUrl = _member.profileImageUrl!.startsWith('http')
          ? _member.profileImageUrl
          : '${AppConfig.baseUrl}${_member.profileImageUrl}';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('마이페이지'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _navigateToEditProfile,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. 프로필 섹션
            Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage: profileUrl != null ? NetworkImage(profileUrl) : null,
                  child: profileUrl == null
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
                const SizedBox(height: 15),
                Text(_member.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 5),
                Text(_member.email, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                if (_member.phoneNumber != null && _member.phoneNumber!.isNotEmpty)
                  Text(_member.phoneNumber!, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                if (_member.address != null && _member.address!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(_member.address!, style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.w500)),
                  ),
              ],
            ),
            const SizedBox(height: 30),

            // 2. 통계 카드
            Row(
              children: [
                Expanded(child: _buildStatCard('총 분석 횟수', '$_totalCount', Icons.trending_up, Colors.blueAccent)),
                const SizedBox(width: 15),
                Expanded(child: _buildStatCard('평균 건강 점수', _averageScore.toStringAsFixed(1), Icons.favorite, Colors.redAccent)),
              ],
            ),
            const SizedBox(height: 25),

            // 3. 분석 기록
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 5, bottom: 15),
                child: Text('최근 분석 기록', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              ),
            ),
            if (_historyList.isEmpty)
              Container(
                padding: const EdgeInsets.all(30),
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: const Center(child: Text('기록이 없습니다.', style: TextStyle(color: Colors.grey))),
              )
            else
              ..._historyList.take(5).map((check) => _buildHistoryItem(check)).toList(),

            const SizedBox(height: 40),

            // 4. 하단 버튼 영역
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  backgroundColor: Colors.white,
                ),
                child: const Text('로그아웃', style: TextStyle(fontSize: 16, color: Colors.black87)),
              ),
            ),
            const SizedBox(height: 10),

            TextButton(
              onPressed: _showDeleteConfirmDialog,
              child: Text(
                '회원 탈퇴',
                style: TextStyle(color: Colors.grey[500], fontSize: 13, decoration: TextDecoration.underline),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // _buildStatCard, _buildHistoryItem 등은 기존과 동일합니다.
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(HealthCheck check) {
    final dateStr = DateFormat('yyyy.MM.dd').format(check.checkDate);
    final imageUrl = check.dogProfileImageUrl;
    final fullImageUrl = (imageUrl != null && imageUrl.isNotEmpty)
        ? (imageUrl.startsWith('http') ? imageUrl : '${AppConfig.baseUrl}$imageUrl')
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
              image: fullImageUrl != null
                  ? DecorationImage(image: NetworkImage(fullImageUrl), fit: BoxFit.cover)
                  : null,
            ),
            child: fullImageUrl == null ? const Icon(Icons.pets, color: Colors.grey) : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(check.dogName ?? '반려견', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFE8EAF6), borderRadius: BorderRadius.circular(8)),
                      child: const Text('건강 체크', style: TextStyle(fontSize: 11, color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('건강 점수: ${check.totalScore}점', style: const TextStyle(color: Colors.black87, fontSize: 14)),
              ],
            ),
          ),
          Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}