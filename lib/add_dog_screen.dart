import 'dart:convert';
import 'dart:io'; // File
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'app_config.dart';
import 'models/member.dart';

class AddDogScreen extends StatefulWidget {
  final Member member;
  const AddDogScreen({super.key, required this.member});

  @override
  State<AddDogScreen> createState() => _AddDogScreenState();
}

class _AddDogScreenState extends State<AddDogScreen> {
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();

  String? _gender = 'male';
  bool _isNeutered = false;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // 갤러리/카메라에서 이미지 선택
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024, // 1. 너비 제한 (너무 큰 사진 방지)
        maxHeight: 1024, // 2. 높이 제한
        imageQuality: 70, // 3. 화질 70%로 압축
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("이미지 선택 에러: $e");
      // 권한 문제일 수 있음
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진을 가져오지 못했습니다. 권한을 확인해주세요.')),
      );
    }
  }

  // 저장하기
  Future<void> _saveDog() async {
    if (_nameController.text.isEmpty || _birthDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름과 생년월일을 모두 입력해주세요.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    String? profileImageUrl;

    try {
      // 1. 이미지가 있으면 먼저 업로드
      if (_imageFile != null) {
        profileImageUrl = await _uploadImage(_imageFile!);
      }

      // 2. 정보 저장 (이미지 URL 포함)
      await _saveDogDetails(profileImageUrl);

    } catch (e) {
      print('저장 에러: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 중 오류 발생: $e')),
        );
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // 이미지 업로드 API
  Future<String?> _uploadImage(File imageFile) async {
    // ⭐️ 2. [수정] AppConfig 사용
    final url = Uri.parse('${AppConfig.baseUrl}/api/upload');

    try {
      var request = http.MultipartRequest('POST', url);
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // 타임아웃 설정 (이미지 업로드는 시간이 걸릴 수 있음)
      var streamedResponse = await request.send().timeout(const Duration(seconds: 10));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['imageUrl'];
      } else {
        throw Exception('이미지 업로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('이미지 업로드 서버 연결 실패: $e');
    }
  }

  // 정보 저장 API
  Future<void> _saveDogDetails(String? profileImageUrl) async {
    // ⭐️ 3. [수정] AppConfig 사용
    final url = Uri.parse('${AppConfig.baseUrl}/api/members/${widget.member.id}/dogs');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text,
          'birthDate': _birthDateController.text,
          'profileImageUrl': profileImageUrl,
          'breed': _breedController.text,
          'gender': _gender,
          'isNeutered': _isNeutered,
          'weight': _weightController.text.isNotEmpty
              ? double.tryParse(_weightController.text)
              : null,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('반려견이 등록되었습니다!')),
        );
        Navigator.pop(context, true); // 홈 화면 새로고침 트리거
      } else {
        throw Exception('정보 저장 실패: ${response.body}');
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _birthDateController.text = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('새 반려견 등록'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImagePicker(),
            const SizedBox(height: 30),
            _buildCardForm(),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveDog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 5,
              ),
              child: const Text('등록하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: _showImageSourceDialog,
        child: Stack(
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 3),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                image: _imageFile != null ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover) : null,
              ),
              child: _imageFile == null ? Icon(Icons.pets, size: 50, color: Colors.grey.shade300) : null,
            ),
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFF6C63FF), shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          _buildTextField('이름 *', _nameController),
          const SizedBox(height: 16),
          _buildTextField('생년월일 *', _birthDateController, isReadOnly: true, onTap: _selectDate, icon: Icons.calendar_today),
          const SizedBox(height: 16),
          _buildTextField('견종 (선택)', _breedController),
          const SizedBox(height: 16),
          _buildTextField('체중 (kg)', _weightController, inputType: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 16),
          _buildGenderSelector(),
          const Divider(height: 30),
          _buildNeuteredSwitch(),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isReadOnly = false, VoidCallback? onTap, IconData? icon, TextInputType? inputType}) {
    return TextField(
      controller: controller,
      readOnly: isReadOnly,
      onTap: onTap,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: const Color(0xFFF8F9FD),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        suffixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: [
        const Text('성별', style: TextStyle(fontSize: 16, color: Colors.black87)),
        const Spacer(),
        _buildRadioBtn('male', '남아'),
        const SizedBox(width: 10),
        _buildRadioBtn('female', '여아'),
      ],
    );
  }

  Widget _buildRadioBtn(String val, String label) {
    return GestureDetector(
      onTap: () => setState(() => _gender = val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _gender == val ? const Color(0xFF6C63FF) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: _gender == val ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildNeuteredSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('중성화 여부', style: TextStyle(fontSize: 16, color: Colors.black87)),
        Switch(
          value: _isNeutered,
          onChanged: (v) => setState(() => _isNeutered = v),
          activeColor: const Color(0xFF6C63FF),
        ),
      ],
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('갤러리에서 선택'),
                  onTap: () {
                    _pickImage(ImageSource.gallery);
                    Navigator.of(context).pop();
                  }),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('카메라로 촬영'),
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
}