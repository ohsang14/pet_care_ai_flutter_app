import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // 👈 차트 라이브러리 임포트
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

  @override
  void initState() {
    super.initState();
    _fetchHealthChecks();
  }

  Future<void> _fetchHealthChecks() async {
    setState(() { _isLoading = true; });
    final url = Uri.parse('${AppConfig.baseUrl}/api/dogs/${widget.dog.id}/health-checks');
    try {
      final response = await http.get(url);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _healthChecks = responseData.map((data) => HealthCheck.fromJson(data)).toList();
          _isLoading = false;
        });
      } else {
        setState(() { _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _navigateToHealthSurvey() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QuestionnaireScreen(dog: widget.dog)),
    ).then((result) {
      if (result == true) {
        _fetchHealthChecks();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text('${widget.dog.name}의 건강 기록'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _healthChecks.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildChartCard(),
            const SizedBox(height: 25),
            _buildStartNewCheckButton(),
            const SizedBox(height: 25),
            const Text('과거 건강 기록', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 15),
            ..._healthChecks.map((check) => _buildHealthCheckItem(check)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text(
            '아직 건강 기록이 없습니다.\n첫 검사를 시작해 보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          _buildStartNewCheckButton(),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    // 차트 데이터 구성 (최근 5개 기록)
    List<HealthCheck> recentChecks = _healthChecks.reversed.take(5).toList(); // 최신순으로 정렬 후 5개
    List<FlSpot> spots = [];
    List<String> bottomTitles = [];

    for (int i = 0; i < recentChecks.length; i++) {
      spots.add(FlSpot(i.toDouble(), recentChecks[i].totalScore.toDouble()));
      bottomTitles.add(DateFormat('MM/dd').format(recentChecks[i].checkDate));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('건강 점수 변화', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < bottomTitles.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(bottomTitles[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 10)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Theme.of(context).primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
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

  Widget _buildStartNewCheckButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: _navigateToHealthSurvey,
        icon: const Icon(Icons.add_task),
        label: const Text('새로운 건강 상태 체크하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
          shadowColor: const Color(0xFF6C63FF).withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildHealthCheckItem(HealthCheck check) {
    String dateStr = DateFormat('yyyy년 MM월 dd일').format(check.checkDate);
    Color iconColor;
    IconData iconData;
    String statusText;

    final imageUrl = check.dogProfileImageUrl;
    final fullImageUrl = (imageUrl != null && imageUrl.isNotEmpty)
        ? '${AppConfig.baseUrl}$imageUrl'
        : null;

    if (check.totalScore <= 5) {
      iconColor = Colors.green;
      iconData = Icons.check_circle_outline;
      statusText = '매우 건강';
    } else if (check.totalScore <= 15) {
      iconColor = Colors.orange;
      iconData = Icons.warning_amber_outlined;
      statusText = '주의 필요';
    } else {
      iconColor = Colors.red;
      iconData = Icons.error_outline;
      statusText = '병원 방문 권유';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey[200], // 배경색 변경
          // 👇 [수정] 이미지가 있으면 NetworkImage, 없으면 아이콘
          backgroundImage: fullImageUrl != null ? NetworkImage(fullImageUrl) : null,
          child: fullImageUrl == null
              ? Icon(iconData, color: iconColor, size: 28) // 이미지 없으면 기존 아이콘 사용
              : null,
        ),
        title: Text('건강 점수: ${check.totalScore}점', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text(dateStr, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey[400]),

        // ⭐️ [핵심 수정] onTap 이벤트 추가 ⭐️
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
  }
}