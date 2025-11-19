import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'app_config.dart';
import 'member.dart';


class AddDogScreen extends StatefulWidget {
  final Member member;
  const AddDogScreen({super.key, required this.member});

  @override
  State<AddDogScreen> createState() => _AddDogScreenState();
}

class _AddDogScreenState extends State<AddDogScreen> {
  // 2. 폼 입력을 위한 컨트롤러 및 변수
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _breedController = TextEditingController(); // 견종
  final _weightController = TextEditingController(); // 체중

  String? _gender = 'male'; // 성별 (기본값 'male')
  bool _isNeutered = false; // 중성화 여부 (기본값 false)

  File? _imageFile; // 3. 선택된 프로필 이미지 파일
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // 4. 데스크탑(Windows/Mac) 기준
  
  // (Android 에뮬레이터: "http://10.0.2.2:8080")

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // 5. 갤러리/카메라에서 이미지 선택 (analysis_screen.dart와 유사)
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 600, // 이미지 크기 제한 (서버 부담 감소)
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("이미지 선택 에러: $e");
    }
  }

  // 6. '저장하기' 버튼 클릭 시 실행되는 메인 함수
  Future<void> _saveDog() async {
    if (_nameController.text.isEmpty || _birthDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름과 생년월일을 모두 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? profileImageUrl; // 최종 저장될 이미지 URL

    try {
      // 7. (1단계) 이미지가 선택되었다면, 이미지를 먼저 업로드
      if (_imageFile != null) {
        profileImageUrl = await _uploadImage(_imageFile!);
      }

      // (2단계) 이미지 URL(있거나 null)을 포함하여 반려견 정보 최종 저장
      await _saveDogDetails(profileImageUrl);

    } catch (e) {
      print('저장 프로세스 에러: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 중 오류가 발생했습니다: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 7-1. (1단계) 이미지 업로드 API (POST /api/upload)
  Future<String?> _uploadImage(File imageFile) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/upload');
    try {
      var request = http.MultipartRequest('POST', url);
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) { // 201 CREATED
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['imageUrl']; // {"imageUrl": "/images/..."}
      } else {
        throw Exception('이미지 업로드 실패: ${response.body}');
      }
    } catch (e) {
      throw Exception('이미지 업로드 중 에러: $e');
    }
  }

  // 7-2. (2단계) 반려견 정보 저장 API (POST /api/members/{id}/dogs)
  Future<void> _saveDogDetails(String? profileImageUrl) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/members/${widget.member.id}/dogs');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text,
          'birthDate': _birthDateController.text,
          'profileImageUrl': profileImageUrl, // 👈 (1) 이미지 URL (null일 수도 있음)
          'breed': _breedController.text,     // 👈 (2) 견종
          'gender': _gender,                  // 👈 (3) 성별
          'isNeutered': _isNeutered,          // 👈 (4) 중성화 여부
          'weight': _weightController.text.isNotEmpty
              ? double.tryParse(_weightController.text) // 👈 (5) 체중 (숫자)
              : null,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) { // 201 CREATED
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('반려견이 성공적으로 등록되었습니다.')),
        );
        Navigator.pop(context, true); // 👈 8. true를 반환하여 홈 화면이 새로고침되도록 함
      } else {
        throw Exception('반려견 정보 저장 실패: ${response.body}');
      }
    } catch (e) {
      throw Exception('반려견 정보 저장 중 에러: $e');
    }
  }

  // 9. 날짜 선택 달력
  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _birthDateController.text =
        "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('새 반려견 등록'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 프로필 사진 ---
            _buildImagePicker(),
            const SizedBox(height: 30),

            // --- 필수 정보 ---
            _buildTextField(
              controller: _nameController,
              labelText: '이름 *',
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _birthDateController,
              labelText: '생년월일 (YYYY-MM-DD) *',
              readOnly: true,
              onTap: _selectDate,
              suffixIcon: const Icon(Icons.calendar_today, color: Colors.white70),
            ),
            const SizedBox(height: 30),

            // --- 선택 정보 ---
            _buildTextField(
              controller: _breedController,
              labelText: '견종 (선택)',
              hintText: '예: 말티즈, 푸들 등',
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _weightController,
              labelText: '체중 (선택)',
              hintText: '숫자만 입력 (예: 3.5)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 20),

            // --- 성별 선택 ---
            _buildGenderSelector(),
            const SizedBox(height: 20),

            // --- 중성화 여부 ---
            _buildNeuteredSwitch(),
            const SizedBox(height: 40),

            // --- 저장 버튼 ---
            ElevatedButton(
              onPressed: _saveDog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('저장하기', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  // --- 10. (신규) 위젯 빌더들 ---

  Widget _buildImagePicker() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white.withOpacity(0.1),
            backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
            child: _imageFile == null
                ? const Icon(Icons.pets, size: 60, color: Colors.white70)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: InkWell(
              onTap: () {
                // 갤러리/카메라 선택창 띄우기
                _showImageSourceDialog();
              },
              child: const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.camera_alt, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[800],
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text('갤러리에서 선택', style: TextStyle(color: Colors.white)),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text('카메라로 촬영', style: TextStyle(color: Colors.white)),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('성별', style: TextStyle(color: Colors.white70, fontSize: 16)),
          Row(
            children: [
              Radio<String>(
                value: 'male',
                groupValue: _gender,
                onChanged: (value) {
                  setState(() { _gender = value; });
                },
                activeColor: Colors.blueAccent,
              ),
              const Text('남아', style: TextStyle(color: Colors.white)),
              Radio<String>(
                value: 'female',
                groupValue: _gender,
                onChanged: (value) {
                  setState(() { _gender = value; });
                },
                activeColor: Colors.blueAccent,
              ),
              const Text('여아', style: TextStyle(color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNeuteredSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('중성화 여부', style: TextStyle(color: Colors.white70, fontSize: 16)),
          Switch(
            value: _isNeutered,
            onChanged: (value) {
              setState(() { _isNeutered = value; });
            },
            activeColor: Colors.blueAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    bool readOnly = false,
    VoidCallback? onTap,
    Icon? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.white70),
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder( // 기본 테두리
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder( // 포커스 시 테두리
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}