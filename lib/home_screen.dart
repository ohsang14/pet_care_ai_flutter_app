// lib/home_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'member.dart';
import 'add_dog_screen.dart';
import 'models/dog.dart';

// 2. StatelessWidget에서 StatefulWidget으로 변경
class HomeScreen extends StatefulWidget {
  final Member member;

  const HomeScreen({super.key, required this.member});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 3. 서버에서 받아온 반려견 목록을 저장할 리스트
  List<Dog> _dogList = [];

  // 4. 데이터를 불러오는 중인지 상태를 관리할 변수
  bool _isLoading = true;

  // 5. 화면이 처음 로드될 때 실행되는 함수
  @override
  void initState() {
    super.initState();
    // 반려견 목록을 불러오는 함수를 호출
    _fetchDogs();
  }

  // 6. 서버에서 반려견 목록을 불러오는 API 호출 함수
  Future<void> _fetchDogs() async {
    // 7. 우리가 Postman에서 테스트한 GET API 주소
    final url = Uri.parse(
      'http://10.0.2.2:8080/api/members/${widget.member.id}/dogs',
    );
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // 8. 성공 시, JSON 데이터를 List<Dog>로 변환
        final List<dynamic> responseData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        setState(() {
          _dogList = responseData.map((data) => Dog.fromJson(data)).toList();
          _isLoading = false; // 로딩 완료
        });
      } else {
        // 9. 실패 시
        print('반려견 목록 로드 실패: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('반려견 목록 로드 에러: $e');
      setState(() {
        _isLoading = false;
      });
    }
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
                // 환영 헤더
                Text(
                  '안녕하세요, ${widget.member.name}님! 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '오늘도 우리 아이들이 건강하게!',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 30),

                // 빠른 기능 카드
                _buildQuickActionsCard(context),

                const SizedBox(height: 30),

                // 내 반려견 헤더
                _buildMyDogsHeader(context),

                const SizedBox(height: 20),

                // 10. 반려견 목록
                _buildDogList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
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

  Widget _buildActionButton(BuildContext context, IconData icon, String label) {
    return Column(
      children: [
        InkWell(
          onTap: () {},
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '내 반려견',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton.icon(
          onPressed: () {
            // '+ 추가' 버튼 클릭 시 AddDogScreen으로 이동 후,
            // 화면이 다시 돌아왔을 때 목록을 새로고침(_fetchDogs)함
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddDogScreen(member: widget.member),
              ),
            ).then((_) {
              // 11. 등록 화면에서 돌아왔을 때 목록 새로고침
              setState(() {
                _isLoading = true; // 로딩 상태로 변경
              });
              _fetchDogs();
            });
          },
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            '추가',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
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

  // 12. 반려견 목록 위젯
  Widget _buildDogList() {
    if (_isLoading) {
      // 로딩 중일 때
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_dogList.isEmpty) {
      // 목록이 비어있을 때
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

    // 목록이 있을 때
    return ListView.builder(
      itemCount: _dogList.length,
      shrinkWrap: true, // SingleChildScrollView 안에서 ListView가 올바르게 작동하도록 설정
      physics: const NeverScrollableScrollPhysics(), // 부모 스크롤을 사용
      itemBuilder: (context, index) {
        final dog = _dogList[index];
        // 13. Figma 디자인과 유사한 반려견 카드
        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              radius: 25,
              // TODO: 강아지 이미지 연동
              backgroundColor: Colors.grey,
              child: Icon(Icons.pets, color: Colors.white),
            ),
            title: Text(
              dog.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '생년월일: ${dog.birthDate}',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}
