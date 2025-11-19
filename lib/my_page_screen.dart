import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'app_config.dart';
import 'member.dart';
import 'models/health_check.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart'; // 👈 회원 수정 화면

class MyPageScreen extends StatefulWidget {
  final Member member;
  const MyPageScreen({super.key, required this.member});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  late Member _member; // 회원 정보 상태 관리
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

  // 회원 정보 수정 화면으로 이동
  void _navigateToEditProfile() async {
    final updatedMember = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfileScreen(member: _member)),
    );

    if (updatedMember != null && updatedMember is Member) {
      setState(() {
        _member = updatedMember; // 화면 갱신
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD), // 밝은 배경
      appBar: AppBar(
        title: const Text('마이페이지'),
        backgroundColor: const Color(0xFF0A0E21), // 헤더는 어둡게 (피그마 스타일)
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. 프로필 카드
            _buildProfileCard(),
            const SizedBox(height: 20),

            // 2. 통계 카드
            Row(
              children: [
                Expanded(child: _buildStatCard('총 분석 횟수', '$_totalCount', Icons.trending_up, Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('평균 건강 점수', _averageScore.toStringAsFixed(0), Icons.favorite, Colors.redAccent)),
              ],
            ),
            const SizedBox(height: 20),

            // 3. 분석 기록 (강아지 사진 포함!)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0,5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('분석 기록', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_historyList.isEmpty)
                    const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('기록이 없습니다.'))),

                  ..._historyList.take(5).map((check) => _buildHistoryItem(check)).toList(),
                ],
              ),
            ),

            // ... (로그아웃 버튼 등은 기존과 동일하게 배치) ...
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0,4))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[200],
            child: Text(_member.name[0], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_member.name}님', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(_member.email, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                  child: const Text('일반 회원', style: TextStyle(fontSize: 11, color: Colors.grey)),
                )
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black54),
            onPressed: _navigateToEditProfile, // 👈 설정 버튼에 수정 기능 연결
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        children: [
          CircleAvatar(radius: 20, backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 20)),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(HealthCheck check) {
    final dateStr = DateFormat('yyyy년 MM월 dd일').format(check.checkDate);
    final imageUrl = check.dogProfileImageUrl;
    final fullImageUrl = (imageUrl != null && imageUrl.isNotEmpty) ? '${AppConfig.baseUrl}$imageUrl' : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          // 🐶 강아지 사진 표시
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[200],
            backgroundImage: fullImageUrl != null ? NetworkImage(fullImageUrl) : null,
            child: fullImageUrl == null ? const Icon(Icons.pets, color: Colors.grey) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(check.dogName ?? '반려견', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Text('건강 체크', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('건강 점수: ${check.totalScore}점', style: const TextStyle(fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 2),
                Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}