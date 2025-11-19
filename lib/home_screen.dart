import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  // 안드로이드 에뮬레이터 기준
  final String _baseUrl = "http://10.0.2.2:8080";
  // (데스크탑: "http://localhost:8080")

  @override
  void initState() {
    super.initState();
    _fetchDogs();
  }

  Future<void> _fetchDogs() async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('$_baseUrl/api/members/${widget.member.id}/dogs');
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
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '안녕하세요, ${widget.member.name}님! 👋',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '오늘도 우리 아이들이 건강하게!',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 30),
                _buildQuickActionsCard(context),
                const SizedBox(height: 30),
                _buildMyDogsHeader(context),
                const SizedBox(height: 20),
                _buildDogList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    // ... (수정 사항 없음) ...
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '빠른 기능',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(context, Icons.camera_alt, '품종 분석'),
              _buildActionButton(context, Icons.favorite, '건강 체크'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, IconData icon, String label) {
    // ... (수정 사항 없음) ...
    return Column(
      children: [
        InkWell(
          onTap: () {
            // TODO: '품종 분석' 또는 '건강 체크' 탭으로 이동
          },
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 30, color: Colors.grey[700]),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildMyDogsHeader(BuildContext context) {
    // ... (수정 사항 없음) ...
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '내 반려견',
          style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        TextButton.icon(
          onPressed: _navigateToAddDog,
          icon: const Icon(Icons.add, color: Colors.white),
          label:
          const Text('추가', style: TextStyle(color: Colors.white, fontSize: 16)),
          style: TextButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDogList() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }

    if (_dogList.isEmpty) {
      // ... (수정 사항 없음) ...
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            '등록된 반려견이 없습니다.\n[+ 추가] 버튼을 눌러 등록해주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _dogList.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final dog = _dogList[index];

        final imageUrl = dog.profileImageUrl;
        final fullImageUrl = (imageUrl != null && imageUrl.isNotEmpty)
            ? '$_baseUrl$imageUrl'
            : null;

        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[300],
              backgroundImage: (fullImageUrl != null)
                  ? NetworkImage(fullImageUrl)
                  : null,
              child: (fullImageUrl == null)
                  ? const Icon(Icons.pets, color: Colors.grey)
                  : null,
            ),
            title: Text(
              dog.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '생년월일: ${dog.birthDate}',
              style: const TextStyle(color: Colors.grey),
            ),

            // 2. ⭐️ [수정] onTap 이벤트를 async/await로 변경 ⭐️
            onTap: () async { // 👈 1. async 추가
              // 2. 상세 화면이 닫힐 때까지 기다리고, 반환값(result)을 받음
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DogDetailScreen(dog: dog),
                ),
              );

              // 3. 만약 상세 화면에서 'true' (삭제 성공)를 반환했다면
              if (result == true) {
                _fetchDogs(); // 👈 목록을 새로고침
              }
            },
          ),
        );
      },
    );
  }
}