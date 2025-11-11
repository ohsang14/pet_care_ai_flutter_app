import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'member.dart';
import 'analysis_screen.dart';
import 'health_check_screen.dart'; // 👈 1. 새 화면 import (아직 파일은 없음)

class MainScreen extends StatefulWidget {
  final Member member;
  const MainScreen({super.key, required this.member});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      HomeScreen(member: widget.member),
      const AnalysisScreen(),
      HealthCheckScreen(member: widget.member), // 👈 2. 2번 인덱스(세 번째 탭) 수정
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
            activeIcon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            activeIcon: Icon(Icons.camera_alt),
            label: '품종 분석',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border), // 👈 '건강 체크' 탭 아이콘
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
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }
}