import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'member.dart';

class MainScreen extends StatefulWidget {
  // 1. MainScreen이 Member 객체를 받도록 생성자 수정
  final Member member;
  const MainScreen({super.key, required this.member});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 2. 화면 목록을 정적(static)이 아닌, 상태가 관리하는 리스트로 변경
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    // 3. MainScreen이 받은 member 정보를 HomeScreen으로 넘겨주도록 설정
    _widgetOptions = <Widget>[
      HomeScreen(member: widget.member), // 👈 여기!
      const Center(child: Text('품종 분석 페이지')),
      const Center(child: Text('건강 체크 페이지')),
      const Center(child: Text('마이 페이지')),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            label: '품종 분석',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: '건강 체크',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '마이페이지',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }
}
