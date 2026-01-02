/// 사용자 모델
class User {
  final String id;
  final String username;
  final String email;
  final String? name;
  final String? profileImage;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.name,
    this.profileImage,
  });

  /// JSON to User
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      profileImage: json['profileImage'] as String?,
    );
  }

  /// User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'name': name,
      'profileImage': profileImage,
    };
  }
}
