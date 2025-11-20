import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_config.dart'; // AppConfig import
import 'models/dog.dart';
import 'edit_dog_screen.dart';

class DogDetailScreen extends StatefulWidget {
  final Dog dog;
  const DogDetailScreen({super.key, required this.dog});

  @override
  State<DogDetailScreen> createState() => _DogDetailScreenState();
}

class _DogDetailScreenState extends State<DogDetailScreen> {
  late Dog _dog;
  bool _hasBeenEdited = false;

  @override
  void initState() {
    super.initState();
    _dog = widget.dog;
  }

  Future<bool> _deleteDog(BuildContext context) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/dogs/${_dog.id}');
    try {
      final response = await http.delete(url);

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
          content: Text("'${_dog.name}'의 모든 정보(건강 기록 포함)가 삭제됩니다.\n정말 삭제하시겠습니까?"),
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
                  Navigator.of(context).pop(true);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToEditDog(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditDogScreen(dog: _dog),
      ),
    );

    if (result != null && result is Dog) {
      setState(() {
        _dog = result;
        _hasBeenEdited = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. 원본 URL 가져오기
    final String? rawUrl = _dog.profileImageUrl;

    // 2. URL 종류에 따라 처리 (외부 링크 vs 내부 파일)
    String? fullImageUrl;
    if (rawUrl != null && rawUrl.isNotEmpty) {
      if (rawUrl.startsWith('http')) {
        fullImageUrl = rawUrl; // 이미 http로 시작하면 그대로 사용
      } else {
        fullImageUrl = '${AppConfig.baseUrl}$rawUrl'; // 아니면 내 서버 주소 붙이기
      }
    }

    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) {
          if (_hasBeenEdited) {
            // 이미 pop된 후에는 값을 반환할 수 없으므로,
            // pop하기 전에 Navigator.pop(context, true)를 호출하는 방식이 더 좋습니다.
            // 하지만 여기서는 시스템 뒤로가기 버튼 대응을 위해 놔둡니다.
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FD), // 밝은 배경
        appBar: AppBar(
          title: Text('${_dog.name}의 상세 정보'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
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
              Center(
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: (fullImageUrl != null)
                      ? NetworkImage(fullImageUrl)
                      : null,
                  child: (fullImageUrl == null)
                      ? const Icon(Icons.pets, size: 60, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  _dog.name,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.cake_outlined, '생년월일', _dog.birthDate),
                      const Divider(),
                      _buildInfoRow(Icons.pets_outlined, '견종', _dog.breed),
                      const Divider(),
                      _buildInfoRow(Icons.transgender, '성별',
                          _dog.gender == 'male' ? '남아' : (_dog.gender == 'female' ? '여아' : '미등록')),
                      const Divider(),
                      _buildInfoRow(Icons.healing_outlined, '중성화',
                          _dog.isNeutered == true ? '완료' : '미완료'),
                      const Divider(),
                      _buildInfoRow(Icons.monitor_weight_outlined, '체중',
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

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    final displayValue = (value == null || value.isEmpty) ? '정보 없음' : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 22),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            displayValue,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}