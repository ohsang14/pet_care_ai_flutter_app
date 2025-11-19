import 'dart:convert';
import 'dart:io'; // File
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'app_config.dart';
import 'models/dog.dart'; // 👈 Dog 모델 import

class EditDogScreen extends StatefulWidget {
  final Dog dog; // 👈 1. [신규] 수정할 Dog 객체를 받음
  const EditDogScreen({super.key, required this.dog});

  @override
  State<EditDogScreen> createState() => _EditDogScreenState();
}

class _EditDogScreenState extends State<EditDogScreen> {
  // 폼 입력을 위한 컨트롤러 및 변수
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();

  String? _gender;
  bool _isNeutered = false;

  File? _imageFile; // 2. 새로 선택한 이미지 파일
  String? _existingImageUrl; // 3. 기존에 저장되어 있던 이미지 URL
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // 4. 안드로이드 에뮬레이터 기준
  
  // (데스크탑: "http://localhost:8080")

  @override
  void initState() {
    super.initState();
    // 5. [신규] 위젯이 로드될 때, 전달받은 Dog 객체로 폼을 채움
    _nameController.text = widget.dog.name;
    _birthDateController.text = widget.dog.birthDate;
    _breedController.text = widget.dog.breed ?? '';
    _weightController.text = widget.dog.weight?.toString() ?? '';
    _gender = widget.dog.gender ?? 'male';
    _isNeutered = widget.dog.isNeutered ?? false;
    _existingImageUrl = widget.dog.profileImageUrl;
  }

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
        source: source,
        maxWidth: 600,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path); // 👈 새 이미지 파일로 설정
          _existingImageUrl = null; // 👈 기존 이미지는 사용 안 함
        });
      }
    } catch (e) {
      print("이미지 선택 에러: $e");
    }
  }

  // 6. [수정] '수정 완료' 버튼 클릭 시
  Future<void> _updateDog() async {
    if (_nameController.text.isEmpty || _birthDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름과 생년월일을 모두 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? finalImageUrl = _existingImageUrl; // 👈 기본값은 기존 이미지 URL

    try {
      // 7. (1단계) 만약 새 이미지를 선택했다면, 업로드
      if (_imageFile != null) {
        finalImageUrl = await _uploadImage(_imageFile!);
      }

      // (2단계) 최종 이미지 URL과 모든 정보를 API로 전송
      await _updateDogDetails(finalImageUrl);

    } catch (e) {
      print('수정 프로세스 에러: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수정 중 오류가 발생했습니다: ${e.toString()}')),
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

  // (1단계) 이미지 업로드 API (POST /api/upload)
  Future<String?> _uploadImage(File imageFile) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/upload');
    try {
      var request = http.MultipartRequest('POST', url);
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['imageUrl'];
      } else {
        throw Exception('이미지 업로드 실패: ${response.body}');
      }
    } catch (e) {
      throw Exception('이미지 업로드 중 에러: $e');
    }
  }

  // 8. [수정] (2단계) 반려견 정보 수정 API (PUT /api/dogs/{id})
  Future<void> _updateDogDetails(String? profileImageUrl) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/dogs/${widget.dog.id}');
    try {
      final response = await http.put( // 👈 http.put
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

      if (response.statusCode == 200) { // 👈 200 OK
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('반려견 정보가 성공적으로 수정되었습니다.')),
        );

        // 9. ⭐️ [핵심] ⭐️
        // 서버가 반환한 수정된 Dog 객체(JSON)를 파싱
        final Map<String, dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
        final Dog savedDog = Dog.fromJson(responseData);

        // 10. ⭐️ [핵심] ⭐️
        // 'true' 대신, 수정된 'savedDog' 객체를 반환하며 닫기
        Navigator.pop(context, savedDog);

      } else {
        throw Exception('반려견 정보 수정 실패: ${response.body}');
      }
    } catch (e) {
      throw Exception('반려견 정보 수정 중 에러: $e');
    }
  }

  // 날짜 선택 달력
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
        title: const Text('반려견 정보 수정'), // 👈 제목 변경
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
            _buildImagePicker(), // 👈 기존 이미지를 표시하는 로직 포함
            const SizedBox(height: 30),

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
            _buildGenderSelector(),
            const SizedBox(height: 20),
            _buildNeuteredSwitch(),
            const SizedBox(height: 40),

            // --- 저장 버튼 ---
            ElevatedButton(
              onPressed: _updateDog, // 👈 _updateDog 함수 호출
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // 👈 수정 버튼 색상
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('수정 완료', style: TextStyle(fontSize: 16)), // 👈 텍스트 변경
            ),
          ],
        ),
      ),
    );
  }

  // --- 위젯 빌더들 ---

  Widget _buildImagePicker() {
    // [신규] 기존 이미지 URL 조합
    final String? fullImageUrl = (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
        ? '${AppConfig.baseUrl}$_existingImageUrl'
        : null;

    ImageProvider? backgroundImage;
    if (_imageFile != null) {
      backgroundImage = FileImage(_imageFile!); // 1. (우선) 새 파일
    } else if (fullImageUrl != null) {
      backgroundImage = NetworkImage(fullImageUrl); // 2. (차선) 기존 네트워크 이미지
    } else {
      backgroundImage = null; // 3. 둘 다 없음
    }

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white.withOpacity(0.1),
            backgroundImage: backgroundImage, // 👈 backgroundImage 적용
            child: (backgroundImage == null)
                ? const Icon(Icons.pets, size: 60, color: Colors.white70)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: InkWell(
              onTap: _showImageSourceDialog,
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
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}