import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'models/dog.dart';
import 'edit_dog_screen.dart'; // 👈 1. [추가] 수정 화면 import

// 2. ⭐️ [수정] StatelessWidget -> StatefulWidget
class DogDetailScreen extends StatefulWidget {
  final Dog dog;
  const DogDetailScreen({super.key, required this.dog});

  @override
  State<DogDetailScreen> createState() => _DogDetailScreenState();
}

// 3. ⭐️ [신규] State 클래스 생성
class _DogDetailScreenState extends State<DogDetailScreen> {

  late Dog _dog; // 4. ⭐️ [신규] 화면에 표시할 '상태'로서의 dog 객체
  bool _hasBeenEdited = false; // 5. ⭐️ [신규] 수정 여부 플래그 (홈 화면 새로고침용)

  // 6. [수정] IP 주소 State로 이동
  final String _baseUrl = "http://10.0.2.2:8080";
  // (데스크탑: "http://localhost:8080")

  @override
  void initState() {
    super.initState();
    _dog = widget.dog; // 7. ⭐️ [신규] State 변수를 위젯의 dog 객체로 초기화
  }

  // (이하 _deleteDog, _showDeleteConfirmDialog 함수는 State 클래스 안으로 이동)

  Future<bool> _deleteDog(BuildContext context) async {
    final url = Uri.parse('$_baseUrl/api/dogs/${_dog.id}'); // 👈 widget.dog -> _dog
    try {
      final response = await http.delete(url);
      // ... (이하 삭제 로직 동일) ...
      if (!context.mounted) return false;
      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('반려견 정보가 삭제되었습니다.')),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제에 실패했습니다. 다시 시도해주세요.')),
        );
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 중 에러 발생: $e')),
        );
      }
      return false;
    }
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('삭제 확인'),
          content: Text("'${_dog.name}'의 모든 정보(건강 기록 포함)가 삭제됩니다.\n정말 삭제하시겠습니까?"), // 👈 widget.dog -> _dog
          actions: [
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('삭제'),
              onPressed: () async {
                bool deleteSuccess = await _deleteDog(context);

                if (deleteSuccess) {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop(true); // 👈 [중요] 'true' 반환
                }
              },
            ),
          ],
        );
      },
    );
  }

  // 8. ⭐️ [수정] 수정 화면으로 이동하는 함수 (핵심)
  void _navigateToEditDog(BuildContext context) async { // 👈 async 추가
    // 9. EditDogScreen이 닫힐 때까지 기다리고, 반환값(수정된 Dog 객체)을 받음
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditDogScreen(dog: _dog), // 👈 state의 _dog 객체 전달
      ),
    );

    // 10. 만약 '저장'에 성공해서 Dog 객체가 반환되었다면
    if (result != null && result is Dog) {
      setState(() {
        _dog = result; // 👈 11. 화면의 '상태'를 새 Dog 객체로 업데이트 (새로고침)
        _hasBeenEdited = true; // 👈 12. 홈 화면도 새로고침하라고 플래그 설정
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    // 13. ⭐️ [수정] widget.dog -> _dog (State 변수 사용)
    final imageUrl = _dog.profileImageUrl;
    final fullImageUrl = (imageUrl != null && imageUrl.isNotEmpty)
        ? '$_baseUrl$imageUrl'
        : null;

    // 14. ⭐️ [신규] 뒤로가기 버튼을 눌렀을 때 홈 화면에 신호(true)를 주기 위한 PopScope
    return PopScope(
      // 15. 이 화면이 닫힐 때
      onPopInvoked: (didPop) {
        if (didPop) {
          // 16. 만약 수정이 일어났었다면(true), 홈 화면에 'true'를 반환
          if (_hasBeenEdited) {
            Navigator.pop(context, true);
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          title: Text('${_dog.name}의 상세 정보'), // 👈 widget.dog -> _dog
          backgroundColor: Colors.grey[900],
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                _navigateToEditDog(context);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () {
                _showDeleteConfirmDialog(context);
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. 프로필 사진 ---
              Center(
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: (fullImageUrl != null)
                      ? NetworkImage(fullImageUrl)
                      : null,
                  child: (fullImageUrl == null)
                      ? const Icon(Icons.pets, size: 80, color: Colors.white70)
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  _dog.name, // 👈 widget.dog -> _dog
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // --- 2. 상세 정보 카드 ---
              Card(
                color: Colors.grey[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // 17. ⭐️ [수정] widget.dog -> _dog
                      _buildInfoRow(Icons.cake, '생년월일', _dog.birthDate),
                      _buildInfoRow(Icons.pets, '견종', _dog.breed),
                      _buildInfoRow(Icons.wc, '성별', _dog.gender == 'male' ? '남아' : '여아'),
                      _buildInfoRow(Icons.health_and_safety, '중성화',
                          _dog.isNeutered == true ? '완료' : '미완료'),
                      _buildInfoRow(Icons.monitor_weight, '체중',
                          _dog.weight != null ? '${_dog.weight} kg' : null),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 18. [수정] _buildInfoRow 헬퍼 위젯을 State 클래스 안으로 이동
  Widget _buildInfoRow(IconData icon, String label, String? value) {
    final displayValue = (value == null || value.isEmpty) ? '정보 없음' : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            displayValue,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}