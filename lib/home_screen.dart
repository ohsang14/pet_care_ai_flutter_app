import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_config.dart'; // AppConfig import
import 'add_dog_screen.dart';
import 'dog_detail_screen.dart';
import 'member.dart';
import 'models/dog.dart';

class HomeScreen extends StatefulWidget {
  final Member member;
  const HomeScreen({super.key, required this.member});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Dog> _dogList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDogs();
  }

  Future<void> _fetchDogs() async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('${AppConfig.baseUrl}/api/members/${widget.member.id}/dogs');
    try {
      final response = await http.get(url);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> responseData =
        jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _dogList = responseData.map((data) => Dog.fromJson(data)).toList();
          _isLoading = false;
        });
      } else {
        print('반려견 목록 로드 실패: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('반려견 목록 로드 에러: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToAddDog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDogScreen(member: widget.member),
      ),
    ).then((result) {
      if (result == true) {
        _fetchDogs();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      // AppBar는 MainScreen 등 상위 위젯의 테마를 따르거나 별도 지정 가능
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Text('PetCare AI', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            const SizedBox(width: 5),
            Icon(Icons.pets, color: Theme.of(context).primaryColor, size: 20),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchDogs,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '안녕하세요, ${widget.member.name}님! 👋',
                    style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '오늘도 우리 아이들이 건강하게!',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 30),
                  _buildQuickActionsCard(context),
                  const SizedBox(height: 30),
                  _buildMyDogsHeader(context),
                  const SizedBox(height: 16),
                  _buildDogList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(context, Icons.camera_alt_outlined, '품종 분석', Colors.blueAccent),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildActionButton(context, Icons.favorite_border, '건강 체크', Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {
        // TODO: 탭 이동 구현 (MainScreen의 탭 인덱스 변경 등)
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildMyDogsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '내 반려견',
          style: TextStyle(
              color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        TextButton.icon(
          onPressed: _navigateToAddDog,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('추가'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF6C63FF),
          ),
        ),
      ],
    );
  }

  Widget _buildDogList() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator());
    }

    if (_dogList.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(Icons.pets, size: 40, color: Colors.grey[300]),
            const SizedBox(height: 10),
            const Text(
              '등록된 반려견이 없습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _dogList.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final dog = _dogList[index];

        // 1. 원본 URL
        final String? rawUrl = dog.profileImageUrl;

        // 2. URL 종류에 따라 처리 (외부 링크 vs 내부 파일)
        String? fullImageUrl;
        if (rawUrl != null && rawUrl.isNotEmpty) {
          if (rawUrl.startsWith('http')) {
            fullImageUrl = rawUrl;
          } else {
            fullImageUrl = '${AppConfig.baseUrl}$rawUrl';
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFFF0F0F3),
              backgroundImage: (fullImageUrl != null)
                  ? NetworkImage(fullImageUrl)
                  : null,
              child: (fullImageUrl == null)
                  ? const Icon(Icons.pets, color: Colors.grey)
                  : null,
            ),
            title: Text(
              dog.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  dog.breed ?? '견종 정보 없음',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DogDetailScreen(dog: dog),
                ),
              );

              if (result == true) {
                _fetchDogs();
              }
            },
          ),
        );
      },
    );
  }
}