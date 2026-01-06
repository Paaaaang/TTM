/// 배지 모델 클래스
///
/// DB 테이블 매핑:
/// - badge 테이블: 배지 마스터 정보
/// - member_badge 테이블: 회원별 배지 획득 정보
class Badge {
  // DB: badge 테이블
  final int badgeId;           // badge_id (PK)
  final String badgeName;      // badge_name
  final String description;    // description
  final String? iconPath;      // icon_path
  final DateTime? createdAt;   // created_at

  Badge({
    required this.badgeId,
    required this.badgeName,
    required this.description,
    this.iconPath,
    this.createdAt,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      badgeId: json['badge_id'] as int,
      badgeName: json['badge_name'] as String,
      description: json['description'] as String,
      iconPath: json['icon_path'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'badge_id': badgeId,
      'badge_name': badgeName,
      'description': description,
      'icon_path': iconPath,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}


class MemberBadge {
  // DB: member_badge 테이블 + badge 테이블 JOIN
  final int memberBadgeId;     // member_badge_id (PK)
  final int badgeId;           // badge_id (FK)
  final String badgeName;      // badge.badge_name (JOIN)
  final String description;    // badge.description (JOIN)
  final String? iconPath;      // badge.icon_path (JOIN)
  final DateTime acquiredAt;   // acquired_at

  MemberBadge({
    required this.memberBadgeId,
    required this.badgeId,
    required this.badgeName,
    required this.description,
    this.iconPath,
    required this.acquiredAt,
  });

  factory MemberBadge.fromJson(Map<String, dynamic> json) {
    return MemberBadge(
      memberBadgeId: json['member_badge_id'] as int,
      badgeId: json['badge_id'] as int,
      badgeName: json['badge_name'] as String,
      description: json['description'] as String,
      iconPath: json['icon_path'] as String?,
      acquiredAt: DateTime.parse(json['acquired_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'member_badge_id': memberBadgeId,
      'badge_id': badgeId,
      'badge_name': badgeName,
      'description': description,
      'icon_path': iconPath,
      'acquired_at': acquiredAt.toIso8601String(),
    };
  }

  // Helper: 획득 시간 표시 (예: "3일 전")
  String get acquiredTimeAgo {
    final now = DateTime.now();
    final difference = now.difference(acquiredAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years년 전';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months개월 전';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}


class BadgeStats {
  // 배지 통계
  final int totalBadges;         // 전체 배지 수
  final int acquiredBadges;      // 획득 배지 수
  final double acquisitionRate;  // 획득률 (%)

  BadgeStats({
    required this.totalBadges,
    required this.acquiredBadges,
    required this.acquisitionRate,
  });

  factory BadgeStats.fromJson(Map<String, dynamic> json) {
    return BadgeStats(
      totalBadges: json['total_badges'] as int,
      acquiredBadges: json['acquired_badges'] as int,
      acquisitionRate: (json['acquisition_rate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_badges': totalBadges,
      'acquired_badges': acquiredBadges,
      'acquisition_rate': acquisitionRate,
    };
  }

  // Helper: 진행률 표시 (0.0 ~ 1.0)
  double get progress => totalBadges > 0 ? acquiredBadges / totalBadges : 0.0;
}
