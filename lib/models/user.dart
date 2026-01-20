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
  final String? loginId;
  final String nickname;
  final String? memberName;
  
  // 연락처 및 개인정보
  final String? phoneNumber;
  final String? birthDate; // YYYY-MM-DD
  final String? gender; // M, F, O
  final String? region;
  
  // 신체 정보
  final double? heightCm;
  final double? weightKg;
  final int calorieGoal; // 일일 칼로리 목표 (kcal)
  final double? waterGoal; // 일일 물 섭취 목표 (L)
  
  // 건강 정보
  final String? activityLevel; // LOW, NORMAL, HIGH
  
  // 계정 상태
  final String memberStatus; // ACTIVE, INACTIVE, SUSPENDED, DELETED
  final bool termsAgreed;
  
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
    this.loginId,
    required this.nickname,
    this.memberName,
    this.phoneNumber,
    this.birthDate,
    this.gender,
    this.region,
    this.heightCm,
    this.weightKg,
    this.calorieGoal = 2000,
    this.waterGoal,
    this.activityLevel,
    this.memberStatus = 'ACTIVE',
    this.termsAgreed = false,
    this.pushNotificationEnabled = true,
    this.marketingNotificationEnabled = false,
    this.profileImage,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  /// JSON to User (DB 컬럼명 그대로 매칭)
  factory User.fromJson(Map<String, dynamic> json) {
    // camelCase와 snake_case 모두 지원
    return User(
      memberId: (json['memberId'] ?? json['member_id']) as int,
      email: (json['email']) as String? ?? '',
      loginId: (json['loginId'] ?? json['login_id']) as String?,
      nickname: (json['nickname']) as String? ?? '알 수 없음',
      memberName: (json['memberName'] ?? json['member_name']) as String?,
      phoneNumber: (json['phoneNumber'] ?? json['phone_number']) as String?,
      birthDate: (json['birthDate'] ?? json['birth_date']) as String?,
      gender: (json['gender']) as String?,
      region: (json['region']) as String?,
      heightCm: (json['heightCm'] ?? json['height_cm']) != null 
          ? ((json['heightCm'] ?? json['height_cm']) as num).toDouble() 
          : null,
      weightKg: (json['weightKg'] ?? json['weight_kg']) != null 
          ? ((json['weightKg'] ?? json['weight_kg']) as num).toDouble() 
          : null,
      calorieGoal: (json['calorieGoal'] ?? json['calorie_goal']) as int? ?? 2000,
      waterGoal: (json['waterGoal'] ?? json['water_goal']) != null 
          ? ((json['waterGoal'] ?? json['water_goal']) as num).toDouble() 
          : null,
      activityLevel: (json['activityLevel'] ?? json['activity_level']) as String?,
      memberStatus: (json['memberStatus'] ?? json['member_status']) as String? ?? 'ACTIVE',
      termsAgreed: (json['termsAgreed'] ?? json['terms_agreed']) == 1 || 
                   (json['termsAgreed'] ?? json['terms_agreed']) == true,
      pushNotificationEnabled: (json['pushNotificationEnabled'] ?? json['push_notification_enabled']) == 1 || 
                               (json['pushNotificationEnabled'] ?? json['push_notification_enabled']) == true,
      marketingNotificationEnabled: (json['marketingNotificationEnabled'] ?? json['marketing_notification_enabled']) == 1 || 
                                    (json['marketingNotificationEnabled'] ?? json['marketing_notification_enabled']) == true,
      profileImage: (json['profileImage'] ?? json['profile_image']) as String?,
      createdAt: (json['createdAt'] ?? json['created_at']) != null 
          ? DateTime.parse((json['createdAt'] ?? json['created_at']) as String) 
          : null,
      updatedAt: (json['updatedAt'] ?? json['updated_at']) != null 
          ? DateTime.parse((json['updatedAt'] ?? json['updated_at']) as String) 
          : null,
      deletedAt: (json['deletedAt'] ?? json['deleted_at']) != null 
          ? DateTime.parse((json['deletedAt'] ?? json['deleted_at']) as String) 
          : null,
    );
  }

  /// User to JSON (DB 컬럼명으로 변환)
  Map<String, dynamic> toJson() {
    return {
      'member_id': memberId,
      'email': email,
      if (loginId != null) 'login_id': loginId,
      'nickname': nickname,
      if (memberName != null) 'member_name': memberName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (birthDate != null) 'birth_date': birthDate,
      if (gender != null) 'gender': gender,
      if (region != null) 'region': region,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      'calorie_goal': calorieGoal,
      if (waterGoal != null) 'water_goal': waterGoal,
      if (activityLevel != null) 'activity_level': activityLevel,
      'member_status': memberStatus,
      'terms_agreed': termsAgreed ? 1 : 0,
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
    int? calorieGoal,
    double? waterGoal,
    String? activityLevel,
    String? memberStatus,
    bool? termsAgreed,
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
      calorieGoal: calorieGoal ?? this.calorieGoal,
      waterGoal: waterGoal ?? this.waterGoal,
      activityLevel: activityLevel ?? this.activityLevel,
      memberStatus: memberStatus ?? this.memberStatus,
      termsAgreed: termsAgreed ?? this.termsAgreed,
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
