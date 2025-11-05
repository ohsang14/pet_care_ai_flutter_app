class Dog {
  final int id;
  final String name;
  final String birthDate; // 날짜를 문자열로 받습니다.

  Dog({required this.id, required this.name, required this.birthDate});

  // 서버에서 받은 JSON(Map)을 Dog 객체로 변환하는 팩토리 생성자
  factory Dog.fromJson(Map<String, dynamic> json) {
    return Dog(
      id: json['id'],
      name: json['name'],
      birthDate: json['birthDate'],
    );
  }
}
