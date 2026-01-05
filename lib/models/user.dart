/// 사용자 모델
class User {
  final String id;
  final String loginId;
  final String nickname;
  final String email;
  final String? name;
  final String? phone;
  final String? birthdate;
  final String? gender;
  final String? profileImage;

  User({
    required this.id,
    required this.loginId,
    required this.nickname,
    required this.email,
    this.name,
    this.phone,
    this.birthdate,
    this.gender,
    this.profileImage,
  });

  /// JSON to User
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['member_id']?.toString() ?? json['id']?.toString() ?? '',
      loginId: json['login_id'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      email: json['email'] as String,
      name: json['member_name'] as String? ?? json['name'] as String?,
      phone: json['phone_number'] as String? ?? json['phone'] as String?,
      birthdate: json['birth_date'] as String? ?? json['birthdate'] as String?,
      gender: json['gender'] as String?,
      profileImage: json['profile_image'] as String? ?? json['profileImage'] as String?,
    );
  }

  /// User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'login_id': loginId,
      'nickname': nickname,
      'email': email,
      'name': name,
      'phone': phone,
      'birthdate': birthdate,
      'gender': gender,
      'profileImage': profileImage,
    };
  }
}
