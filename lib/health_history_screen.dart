import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart'; // 👈 1. 차트 라이브러리
import 'package:intl/intl.dart';         // 👈 2. 날짜 포맷팅
import 'app_config.dart';
import 'models/dog.dart';
import 'models/health_check.dart';
import 'health_result_screen.dart';
import 'questionnaire_screen.dart';

class HealthHistoryScreen extends StatefulWidget {
  final Dog dog;
  const HealthHistoryScreen({super.key, required this.dog});

  @override
  State<HealthHistoryScreen> createState() => _HealthHistoryScreenState();
}

class _HealthHistoryScreenState extends State<HealthHistoryScreen> {
  List<HealthCheck> _healthChecks = [];
  bool _isLoading = true;

  // 안드로이드 에뮬레이터 기준 IP
  
  // (데스크탑: "http://localhost:8080")

  @override
  void initState() {
    super.initState();
    _fetchHealthChecks();
  }

  Future<void> _fetchHealthChecks() async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('${AppConfig.baseUrl}/api/dogs/${widget.dog.id}/health-checks');
    try {
      final response = await http.get(url);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> responseData =
        jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _healthChecks =
              responseData.map((data) => HealthCheck.fromJson(data)).toList();
          _isLoading = false;
        });
      } else {
        print('건강 기록 로드 실패: ${response.statusCode}');
        setState(() { _isLoading = false; });
      }
    } catch (e) {
      print('건강 기록 로드 에러: $e');
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _navigateToQuestionnaire() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionnaireScreen(dog: widget.dog),
      ),
    ).then((result) {
      if (result == true) {
        _fetchHealthChecks();
      }
    });
  }

  String _formatDateTime(DateTime dt) {
    return "${dt.year}년 ${dt.month}월 ${dt.day}일";
  }

  // 점수에 따른 색상 (차트 및 리스트 공용)
  Color _getScoreColor(int score) {
    if (score <= 5) return Colors.greenAccent;
    if (score <= 15) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Widget _buildScoreIcon(int score) {
    IconData icon;
    Color color = _getScoreColor(score);
    if (score <= 5) {
      icon = Icons.check_circle;
    } else if (score <= 15) {
      icon = Icons.warning_amber_rounded;
    } else {
      icon = Icons.dangerous_rounded;
    }
    return Icon(icon, color: color, size: 40);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text("'${widget.dog.name}'의 건강 기록"),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 3. [신규] 차트 위젯 추가
          if (!_isLoading && _healthChecks.isNotEmpty)
            _buildHealthChartCard(),

          // 4. '새로운 건강 체크하기' 버튼
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _navigateToQuestionnaire,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('새로운 건강 상태 체크하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // 5. 과거 기록 리스트
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  // 6. [신규] 차트 UI 빌더
  Widget _buildHealthChartCard() {
    // (1) 차트용 데이터 준비: 최신순 -> 오래된순으로 뒤집어서 시간 흐름대로 정렬
    final chartData = _healthChecks.reversed.toList();

    return Container(
      height: 250, // 차트 높이
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "건강 점수 변화",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 25, // 점수 최대값 (질문 5개 * 5점 = 25점)
                gridData: const FlGridData(show: false), // 격자 숨김
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5, // 5점 단위 표시
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        // 데이터 포인트가 너무 많으면 간격 조정 필요 (여기선 단순화)
                        if (index >= 0 && index < chartData.length) {
                          DateTime date = chartData[index].checkDate;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('MM/dd').format(date), // 날짜 포맷 (월/일)
                              style: const TextStyle(color: Colors.grey, fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    bottom: BorderSide(color: Colors.white10),
                    left: BorderSide(color: Colors.white10),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.totalScore.toDouble());
                    }).toList(),
                    isCurved: true, // 곡선 그래프
                    color: Colors.blueAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.blueAccent,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blueAccent.withOpacity(0.2), // 그래프 아래 채우기
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_healthChecks.isEmpty) {
      return const Center(
        child: Text(
          '저장된 건강 기록이 없습니다.\n위의 버튼을 눌러 첫 기록을 시작하세요.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _healthChecks.length,
      itemBuilder: (context, index) {
        final check = _healthChecks[index];
        return Card(
          color: Colors.grey[800],
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            leading: _buildScoreIcon(check.totalScore),
            title: Text(
              '${check.totalScore}점',
              style: TextStyle(
                color: _getScoreColor(check.totalScore),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              _formatDateTime(check.checkDate),
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HealthResultScreen(
                    dog: widget.dog,
                    pastCheck: check,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}