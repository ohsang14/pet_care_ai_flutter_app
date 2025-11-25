import 'package:flutter/material.dart';
import 'models/member.dart';
import 'home_screen.dart';
import 'analysis_screen.dart';
import 'health_check_screen.dart';
import 'my_page_screen.dart';

class MainScreen extends StatefulWidget {
  final Member member;
  const MainScreen({super.key, required this.member});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 탭 변경 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 탭별 화면 리스트
    // (HomeScreen에 탭 변경 함수(_onItemTapped)를 전달합니다)
    final List<Widget> widgetOptions = <Widget>[
      HomeScreen(
        member: widget.member,
        onTabChange: _onItemTapped, // 👈 홈 화면 버튼 클릭 시 탭 전환을 위해 전달
      ),
      const AnalysisScreen(),
      HealthCheckScreen(member: widget.member), // 👈 import가 되어 있어야 인식됨
      MyPageScreen(member: widget.member),
    ];

    return Scaffold(
      body: widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined),
              activeIcon: Icon(Icons.camera_alt),
              label: '품종 분석',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              activeIcon: Icon(Icons.favorite),
              label: '건강 체크',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: '마이페이지',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped, // 탭 클릭 시 실행
          selectedItemColor: const Color(0xFF6C63FF),
          unselectedItemColor: Colors.grey[400],
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }
}