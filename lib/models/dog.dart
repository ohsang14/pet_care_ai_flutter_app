class Dog {
  final int id;
  final String name;
  final String birthDate;
  final String? profileImageUrl;
  final String? breed;
  final String? gender;
  final bool? isNeutered;
  final double? weight;

  Dog({
    required this.id,
    required this.name,
    required this.birthDate,
    this.profileImageUrl,
    this.breed,
    this.gender,
    this.isNeutered,
    this.weight,
  });

  factory Dog.fromJson(Map<String, dynamic> json) {
    return Dog(
      id: json['id'],
      name: json['name'],
      birthDate: json['birthDate'],
      profileImageUrl: json['profileImageUrl'], // 👈 매핑 확인
      breed: json['breed'],
      gender: json['gender'],
      isNeutered: json['isNeutered'],
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
    );
  }
}