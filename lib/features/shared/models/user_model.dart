class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String role; // 'passenger' hoặc 'driver'
  final double rating;
  final int totalTrips;
  final String? avatarUrl;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.role,
    this.rating = 5.0,
    this.totalTrips = 0,
    this.avatarUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'passenger',
      rating: (map['rating'] ?? 5.0).toDouble(),
      totalTrips: map['totalTrips'] ?? 0,
      avatarUrl: map['avatarUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'role': role,
      'rating': rating,
      'totalTrips': totalTrips,
      'avatarUrl': avatarUrl,
    };
  }
}