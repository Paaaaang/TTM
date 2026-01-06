/// 사용자 모델
/// 
/// DB 테이블: members
/// 매핑 규칙: snake_case(DB) → camelCase(Dart)
/// - member_id (INT PK) → memberId
/// - email, login_id, nickname, member_name → email, loginId, nickname, memberName
/// - phone_number, birth_date, gender, region → phoneNumber, birthDate, gender, region
/// - height_cm, weight_kg → heightCm, weightKg
/// - disease_flag, allergy_flag → diseaseFlag, allergyFlag
/// - activity_level, sleep_hours, sleep_pattern → activityLevel, sleepHours, sleepPattern
/// - health_goal, member_status → healthGoal, memberStatus
/// - terms_agreed, social_login_agreed → termsAgreed, socialLoginAgreed
/// - push_notification_enabled, marketing_notification_enabled → pushNotificationEnabled, marketingNotificationEnabled
/// - profile_image, created_at, updated_at → profileImage, createdAt, updatedAt
class User {
  // 기본 정보
  final int memberId;
  final String email;
  final String loginId;
  final String nickname;
  final String memberName;
  
  // 연락처 및 개인정보
  final String? phoneNumber;
  final String? birthDate; // YYYY-MM-DD
  final String? gender; // M, F, O
  final String? region;
  
  // 신체 정보
  final double? heightCm;
  final double? weightKg;
  
  // 건강 정보
  final bool diseaseFlag;
  final bool allergyFlag;
  final String? activityLevel; // LOW, NORMAL, HIGH
  final double? sleepHours;
  final String? sleepPattern; // REGULAR, IRREGULAR, SHORT, LONG
  final String? healthGoal;
  
  // 계정 상태
  final String memberStatus; // ACTIVE, INACTIVE, SUSPENDED, DELETED
  final bool termsAgreed;
  final bool socialLoginAgreed;
  
  // 알림 설정
  final bool pushNotificationEnabled;
  final bool marketingNotificationEnabled;
  
  // 기타
  final String? profileImage;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  User({
    required this.memberId,
    required this.email,
    required this.loginId,
    required this.nickname,
    required this.memberName,
    this.phoneNumber,
    this.birthDate,
    this.gender,
    this.region,
    this.heightCm,
    this.weightKg,
    this.diseaseFlag = false,
    this.allergyFlag = false,
    this.activityLevel,
    this.sleepHours,
    this.sleepPattern,
    this.healthGoal,
    this.memberStatus = 'ACTIVE',
    this.termsAgreed = false,
    this.socialLoginAgreed = false,
    this.pushNotificationEnabled = true,
    this.marketingNotificationEnabled = false,
    this.profileImage,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  /// JSON to User (DB 컬럼명 그대로 매칭)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      memberId: json['member_id'] as int,
      email: json['email'] as String,
      loginId: json['login_id'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      memberName: json['member_name'] as String? ?? '',
      phoneNumber: json['phone_number'] as String?,
      birthDate: json['birth_date'] as String?,
      gender: json['gender'] as String?,
      region: json['region'] as String?,
      heightCm: json['height_cm'] != null 
          ? (json['height_cm'] as num).toDouble() 
          : null,
      weightKg: json['weight_kg'] != null 
          ? (json['weight_kg'] as num).toDouble() 
          : null,
      diseaseFlag: json['disease_flag'] == 1 || json['disease_flag'] == true,
      allergyFlag: json['allergy_flag'] == 1 || json['allergy_flag'] == true,
      activityLevel: json['activity_level'] as String?,
      sleepHours: json['sleep_hours'] != null 
          ? (json['sleep_hours'] as num).toDouble() 
          : null,
      sleepPattern: json['sleep_pattern'] as String?,
      healthGoal: json['health_goal'] as String?,
      memberStatus: json['member_status'] as String? ?? 'ACTIVE',
      termsAgreed: json['terms_agreed'] == 1 || json['terms_agreed'] == true,
      socialLoginAgreed: json['social_login_agreed'] == 1 || json['social_login_agreed'] == true,
      pushNotificationEnabled: json['push_notification_enabled'] == 1 || json['push_notification_enabled'] == true,
      marketingNotificationEnabled: json['marketing_notification_enabled'] == 1 || json['marketing_notification_enabled'] == true,
      profileImage: json['profile_image'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      deletedAt: json['deleted_at'] != null 
          ? DateTime.parse(json['deleted_at'] as String) 
          : null,
    );
  }

  /// User to JSON (DB 컬럼명으로 변환)
  Map<String, dynamic> toJson() {
    return {
      'member_id': memberId,
      'email': email,
      'login_id': loginId,
      'nickname': nickname,
      'member_name': memberName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (birthDate != null) 'birth_date': birthDate,
      if (gender != null) 'gender': gender,
      if (region != null) 'region': region,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      'disease_flag': diseaseFlag ? 1 : 0,
      'allergy_flag': allergyFlag ? 1 : 0,
      if (activityLevel != null) 'activity_level': activityLevel,
      if (sleepHours != null) 'sleep_hours': sleepHours,
      if (sleepPattern != null) 'sleep_pattern': sleepPattern,
      if (healthGoal != null) 'health_goal': healthGoal,
      'member_status': memberStatus,
      'terms_agreed': termsAgreed ? 1 : 0,
      'social_login_agreed': socialLoginAgreed ? 1 : 0,
      'push_notification_enabled': pushNotificationEnabled ? 1 : 0,
      'marketing_notification_enabled': marketingNotificationEnabled ? 1 : 0,
      if (profileImage != null) 'profile_image': profileImage,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  /// 복사본 생성
  User copyWith({
    int? memberId,
    String? email,
    String? loginId,
    String? nickname,
    String? memberName,
    String? phoneNumber,
    String? birthDate,
    String? gender,
    String? region,
    double? heightCm,
    double? weightKg,
    bool? diseaseFlag,
    bool? allergyFlag,
    String? activityLevel,
    double? sleepHours,
    String? sleepPattern,
    String? healthGoal,
    String? memberStatus,
    bool? termsAgreed,
    bool? socialLoginAgreed,
    bool? pushNotificationEnabled,
    bool? marketingNotificationEnabled,
    String? profileImage,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return User(
      memberId: memberId ?? this.memberId,
      email: email ?? this.email,
      loginId: loginId ?? this.loginId,
      nickname: nickname ?? this.nickname,
      memberName: memberName ?? this.memberName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      region: region ?? this.region,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      diseaseFlag: diseaseFlag ?? this.diseaseFlag,
      allergyFlag: allergyFlag ?? this.allergyFlag,
      activityLevel: activityLevel ?? this.activityLevel,
      sleepHours: sleepHours ?? this.sleepHours,
      sleepPattern: sleepPattern ?? this.sleepPattern,
      healthGoal: healthGoal ?? this.healthGoal,
      memberStatus: memberStatus ?? this.memberStatus,
      termsAgreed: termsAgreed ?? this.termsAgreed,
      socialLoginAgreed: socialLoginAgreed ?? this.socialLoginAgreed,
      pushNotificationEnabled: pushNotificationEnabled ?? this.pushNotificationEnabled,
      marketingNotificationEnabled: marketingNotificationEnabled ?? this.marketingNotificationEnabled,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  /// 하위 호환을 위한 getter (기존 코드에서 사용 중인 필드명)
  String get id => memberId.toString();
  String? get name => memberName;
  String? get phone => phoneNumber;
  String? get birthdate => birthDate;
}
