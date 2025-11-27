class Member {
  final int id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final String? phoneNumber;
  final String? address;
  final int? kakaoId;

  Member({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.phoneNumber,
    this.address,
    this.kakaoId,
  });

  // JSON 데이터(Map)를 Member 객체로 변환해주는 함수
  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profileImageUrl: json['profileImageUrl'],
      phoneNumber: json['phoneNumber'],
      address: json['address'],
      kakaoId: json['kakaoId'],
    );
  }
}