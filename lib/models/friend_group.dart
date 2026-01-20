// 친구 그룹 모델
class FriendGroup {
  final int groupId;
  final String groupName;
  final int creatorMemberId;
  final int memberCount;
  final DateTime createdAt;

  FriendGroup({
    required this.groupId,
    required this.groupName,
    required this.creatorMemberId,
    required this.memberCount,
    required this.createdAt,
  });

  factory FriendGroup.fromJson(Map<String, dynamic> json) {
    return FriendGroup(
      groupId: json['group_id'] ?? 0,
      groupName: json['group_name'] ?? '',
      creatorMemberId: json['creator_member_id'] ?? 0,
      memberCount: json['member_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'group_name': groupName,
      'creator_member_id': creatorMemberId,
      'member_count': memberCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// 그룹 멤버 정보
class GroupMemberInfo {
  final int memberId;
  final String nickname;
  final String? profileImage;
  final int calorieGoal;
  final int nutritionScore;
  final int badgeCount;
  final DateTime joinedAt;

  GroupMemberInfo({
    required this.memberId,
    required this.nickname,
    this.profileImage,
    required this.calorieGoal,
    required this.nutritionScore,
    required this.badgeCount,
    required this.joinedAt,
  });

  factory GroupMemberInfo.fromJson(Map<String, dynamic> json) {
    return GroupMemberInfo(
      memberId: json['member_id'] ?? 0,
      nickname: json['nickname'] ?? '',
      profileImage: json['profile_image'],
      calorieGoal: json['calorie_goal'] ?? 0,
      nutritionScore: json['nutrition_score'] ?? 0,
      badgeCount: json['badge_count'] ?? 0,
      joinedAt: DateTime.parse(json['joined_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
