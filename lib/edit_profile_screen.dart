import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'app_config.dart';
import 'models/member.dart';

class EditProfileScreen extends StatefulWidget {
  final Member member;
  const EditProfileScreen({super.key, required this.member});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  final TextEditingController _passwordController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member.name);
    _phoneController = TextEditingController(text: widget.member.phoneNumber ?? '');
    _addressController = TextEditingController(text: widget.member.address ?? '');
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 600);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<String?> _uploadImage(File image) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/upload');
    var request = http.MultipartRequest('POST', url);
    request.files.add(await http.MultipartFile.fromPath('file', image.path));
    var response = await http.Response.fromStream(await request.send());
    if (response.statusCode == 201) {
      return jsonDecode(response.body)['imageUrl'];
    }
    return null;
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      String? imageUrl = widget.member.profileImageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage(_imageFile!);
      }

      final url = Uri.parse('${AppConfig.baseUrl}/api/members/${widget.member.id}');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text,
          'phoneNumber': _phoneController.text,
          'address': _addressController.text,
          'profileImageUrl': imageUrl,
          'password': _passwordController.text.isNotEmpty ? _passwordController.text : null,
        }),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final updatedMember = Member.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
        Navigator.pop(context, updatedMember);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('수정되었습니다.')));
      }
    } catch (e) {
      print(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String? fullImageUrl;
    if (_imageFile == null && widget.member.profileImageUrl != null) {
      fullImageUrl = widget.member.profileImageUrl!.startsWith('http')
          ? widget.member.profileImageUrl
          : '${AppConfig.baseUrl}${widget.member.profileImageUrl}';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('회원 정보 수정'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (fullImageUrl != null ? NetworkImage(fullImageUrl) : null) as ImageProvider?,
                    child: (_imageFile == null && fullImageUrl == null)
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Color(0xFF6C63FF), shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildTextField('이름', _nameController),
            const SizedBox(height: 15),
            _buildTextField('전화번호', _phoneController, inputType: TextInputType.phone),
            const SizedBox(height: 15),
            _buildTextField('주소 / 한줄 소개', _addressController),
            const SizedBox(height: 15),
            _buildTextField('새 비밀번호 (변경 시 입력)', _passwordController, obscureText: true),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('저장하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool obscureText = false, TextInputType? inputType}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}