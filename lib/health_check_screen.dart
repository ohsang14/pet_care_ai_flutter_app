import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_config.dart'; // 👈 AppConfig import
import 'models/dog.dart';
import 'models/member.dart';
import 'health_history_screen.dart';

class HealthCheckScreen extends StatefulWidget {
  final Member member;
  const HealthCheckScreen({super.key, required this.member});

  @override
  State<HealthCheckScreen> createState() => _HealthCheckScreenState();
}

class _HealthCheckScreenState extends State<HealthCheckScreen> {
  List<Dog> _dogList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDogs();
  }

  Future<void> _fetchDogs() async {
    setState(() { _isLoading = true; });
    final url = Uri.parse('${AppConfig.baseUrl}/api/members/${widget.member.id}/dogs');
    try {
      final response = await http.get(url);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _dogList = responseData.map((data) => Dog.fromJson(data)).toList();
          _isLoading = false;
        });
      } else {
        setState(() { _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('건강 체크'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        automaticallyImplyLeading: false, // 탭 화면이므로 뒤로가기 숨김
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dogList.isEmpty
          ? const Center(child: Text('등록된 반려견이 없습니다.', style: TextStyle(color: Colors.grey)))
          : ListView.separated(
        padding: const EdgeInsets.all(20.0),
        itemCount: _dogList.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final dog = _dogList[index];

          // ⭐️ [핵심] 이미지 URL 처리 로직 추가
          String? imageUrl = dog.profileImageUrl;
          String? fullImageUrl;
          if (imageUrl != null && imageUrl.isNotEmpty) {
            if (imageUrl.startsWith('http')) {
              fullImageUrl = imageUrl;
            } else {
              fullImageUrl = '${AppConfig.baseUrl}$imageUrl';
            }
          }

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),

              // ⭐️ [수정] CircleAvatar에 이미지 적용
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFE8EAF6),
                radius: 28,
                backgroundImage: fullImageUrl != null ? NetworkImage(fullImageUrl) : null,
                child: fullImageUrl == null
                    ? const Icon(Icons.favorite, color: Color(0xFF6C63FF)) // 사진 없으면 하트
                    : null,
              ),

              title: Text(dog.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              subtitle: const Text('건강 기록 보러가기', style: TextStyle(color: Colors.grey)),
              trailing: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
              ),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HealthHistoryScreen(dog: dog))
              ),
            ),
          );
        },
      ),
    );
  }
}