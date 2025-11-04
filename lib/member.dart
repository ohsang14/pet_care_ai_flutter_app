class Member {
  final int id;
  final String name;
  final String email;

  Member({required this.id, required this.name, required this.email});

  // JSON 데이터(Map)를 Member 객체로 변환해주는 함수
  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(id: json['id'], name: json['name'], email: json['email']);
  }
}
