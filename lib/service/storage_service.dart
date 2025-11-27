import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/member.dart';

class StorageService {
  // 보안 저장소 인스턴스 생성
  static const _storage = FlutterSecureStorage();

  // 저장할 키 값
  static const _keyMember = 'member_data';

  // 1. 회원 정보 저장 (로그인 성공 시 호출)
  static Future<void> saveMember(Member member) async {
    final jsonString = jsonEncode({
      'id': member.id,
      'name': member.name,
      'email': member.email,
      'profileImageUrl': member.profileImageUrl,
      'phoneNumber': member.phoneNumber,
      'address': member.address,
      'kakaoId': member.kakaoId,
    });

    await _storage.write(key: _keyMember, value: jsonString);
  }

  // 2. 회원 정보 불러오기 (앱 실행 시 호출)
  static Future<Member?> getMember() async {
    final jsonString = await _storage.read(key: _keyMember);
    if (jsonString == null) return null;

    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return Member.fromJson(jsonMap);
    } catch (e) {
      // 데이터가 깨졌거나 형식이 바뀌었으면 삭제
      await _storage.delete(key: _keyMember);
      return null;
    }
  }

  // 3. 회원 정보 삭제 (로그아웃/탈퇴 시 호출)
  static Future<void> deleteMember() async {
    await _storage.delete(key: _keyMember);
  }
}