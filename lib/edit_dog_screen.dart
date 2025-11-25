import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'app_config.dart'; // AppConfig import
import 'models/dog.dart';

class EditDogScreen extends StatefulWidget {
  final Dog dog;
  const EditDogScreen({super.key, required this.dog});

  @override
  State<EditDogScreen> createState() => _EditDogScreenState();
}

class _EditDogScreenState extends State<EditDogScreen> {
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();

  String? _gender;
  bool _isNeutered = false;

  File? _imageFile;
  String? _existingImageUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 기존 정보 채우기
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, maxWidth: 600, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _existingImageUrl = null; // 새 이미지를 선택했으므로 기존 URL 무시
        });
      }
    } catch (e) { print("이미지 선택 에러: $e"); }
  }

  Future<void> _updateDog() async {
    if (_nameController.text.isEmpty || _birthDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이름과 생년월일을 입력해주세요.')));
      return;
    }

    setState(() { _isLoading = true; });

    String? finalImageUrl = widget.dog.profileImageUrl; // 기본값은 원래 이미지

    try {
      // 1. 새 이미지가 있다면 업로드
      if (_imageFile != null) {
        finalImageUrl = await _uploadImage(_imageFile!);
      }

      // 2. 정보 업데이트 (PUT)
      await _updateDogDetails(finalImageUrl);

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('에러: $e')));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/upload');
    var request = http.MultipartRequest('POST', url);
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    var response = await http.Response.fromStream(await request.send());

    if (response.statusCode == 201) {
      return jsonDecode(response.body)['imageUrl'];
    } else {
      throw Exception('이미지 업로드 실패');
    }
  }

  Future<void> _updateDogDetails(String? profileImageUrl) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/dogs/${widget.dog.id}');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': _nameController.text,
        'birthDate': _birthDateController.text,
        'profileImageUrl': profileImageUrl,
        'breed': _breedController.text,
        'gender': _gender,
        'isNeutered': _isNeutered,
        'weight': _weightController.text.isNotEmpty ? double.tryParse(_weightController.text) : null,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
      final Dog savedDog = Dog.fromJson(responseData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('수정되었습니다.')));
        Navigator.pop(context, savedDog); // 수정된 객체 반환
      }
    } else {
      throw Exception('수정 실패');
    }
  }

  Future<void> _selectDate() async {
    DateTime initialDate = DateTime.now();
    try { initialDate = DateTime.parse(_birthDateController.text); } catch(_) {}

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() { _birthDateController.text = picked.toString().split(' ')[0]; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD), // 밝은 배경
      appBar: AppBar(
        title: const Text('반려견 정보 수정'),
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
              onPressed: _updateDog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
              ),
              child: const Text('수정 완료', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    // 이미지 URL 처리 로직
    String? fullImageUrl;
    if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      if (_existingImageUrl!.startsWith('http')) {
        fullImageUrl = _existingImageUrl;
      } else {
        fullImageUrl = '${AppConfig.baseUrl}$_existingImageUrl';
      }
    }

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
                image: _imageFile != null
                    ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                    : (fullImageUrl != null
                    ? DecorationImage(image: NetworkImage(fullImageUrl), fit: BoxFit.cover)
                    : null),
              ),
              child: (_imageFile == null && fullImageUrl == null)
                  ? Icon(Icons.pets, size: 50, color: Colors.grey.shade300)
                  : null,
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
      backgroundColor: Colors.white, // 배경 흰색으로 변경
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.black87),
                title: const Text('갤러리에서 선택', style: TextStyle(color: Colors.black87)),
                onTap: () { _pickImage(ImageSource.gallery); Navigator.of(context).pop(); },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.black87),
                title: const Text('카메라로 촬영', style: TextStyle(color: Colors.black87)),
                onTap: () { _pickImage(ImageSource.camera); Navigator.of(context).pop(); },
              ),
            ],
          ),
        );
      },
    );
  }
}