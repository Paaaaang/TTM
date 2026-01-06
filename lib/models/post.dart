/// 게시물 이미지 모델
///
/// DB 테이블: post_image
/// - image_id (INT PK) → imageId
/// - post_id (INT FK) → postId
/// - image_path (VARCHAR) → imagePath
/// - display_order (INT) → displayOrder
/// - created_at (TIMESTAMP) → createdAt
class PostImage {
  final int imageId;
  final int postId;
  final String imagePath;
  final int displayOrder;
  final DateTime createdAt;

  PostImage({
    required this.imageId,
    required this.postId,
    required this.imagePath,
    required this.displayOrder,
    required this.createdAt,
  });

  factory PostImage.fromJson(Map<String, dynamic> json) {
    return PostImage(
      imageId: json['imageId'] as int,
      postId: json['postId'] as int,
      imagePath: json['imagePath'] as String,
      displayOrder: json['displayOrder'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageId': imageId,
      'postId': postId,
      'imagePath': imagePath,
      'displayOrder': displayOrder,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  PostImage copyWith({
    int? imageId,
    int? postId,
    String? imagePath,
    int? displayOrder,
    DateTime? createdAt,
  }) {
    return PostImage(
      imageId: imageId ?? this.imageId,
      postId: postId ?? this.postId,
      imagePath: imagePath ?? this.imagePath,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// 게시물 모델
///
/// DB 테이블: post
/// - post_id (INT PK) → postId
/// - member_id (INT FK) → memberId
/// - category (VARCHAR) → category
/// - title (VARCHAR) → title
/// - content (TEXT) → content
/// - view_count (INT) → viewCount
/// - like_count (INT) → likeCount
/// - created_at (TIMESTAMP) → createdAt
class Post {
  final int postId;
  final int memberId;
  final String? authorNickname;
  final String category;
  final String title;
  final String content;
  final int viewCount;
  final int likeCount;
  final DateTime createdAt;
  final List<PostImage> images;

  Post({
    required this.postId,
    required this.memberId,
    this.authorNickname,
    required this.category,
    required this.title,
    required this.content,
    required this.viewCount,
    required this.likeCount,
    required this.createdAt,
    this.images = const [],
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    List<PostImage> imageList = [];
    if (json['images'] != null) {
      imageList = (json['images'] as List)
          .map((img) => PostImage.fromJson(img as Map<String, dynamic>))
          .toList();
    }

    return Post(
      postId: json['postId'] as int,
      memberId: json['memberId'] as int,
      authorNickname: json['authorNickname'] as String?,
      category: json['category'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      viewCount: json['viewCount'] as int,
      likeCount: json['likeCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      images: imageList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'memberId': memberId,
      'authorNickname': authorNickname,
      'category': category,
      'title': title,
      'content': content,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'createdAt': createdAt.toIso8601String(),
      'images': images.map((img) => img.toJson()).toList(),
    };
  }

  Post copyWith({
    int? postId,
    int? memberId,
    String? authorNickname,
    String? category,
    String? title,
    String? content,
    int? viewCount,
    int? likeCount,
    DateTime? createdAt,
    List<PostImage>? images,
  }) {
    return Post(
      postId: postId ?? this.postId,
      memberId: memberId ?? this.memberId,
      authorNickname: authorNickname ?? this.authorNickname,
      category: category ?? this.category,
      title: title ?? this.title,
      content: content ?? this.content,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      createdAt: createdAt ?? this.createdAt,
      images: images ?? this.images,
    );
  }

  // Helper getters
  String get categoryName {
    switch (category) {
      case '전체':
        return '전체';
      case '식단':
        return '식단';
      case '운동':
        return '운동';
      case '자유':
        return '자유';
      default:
        return category;
    }
  }

  bool get hasImages => images.isNotEmpty;

  int get imageCount => images.length;

  String get firstImagePath => images.isNotEmpty ? images.first.imagePath : '';

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}년 전';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}개월 전';
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

// 목록 조회용 간단한 모델
class PostListItem {
  final int postId;
  final int memberId;
  final String? authorNickname;
  final String category;
  final String title;
  final int viewCount;
  final int likeCount;
  final int imageCount;
  final DateTime createdAt;

  PostListItem({
    required this.postId,
    required this.memberId,
    this.authorNickname,
    required this.category,
    required this.title,
    required this.viewCount,
    required this.likeCount,
    required this.imageCount,
    required this.createdAt,
  });

  factory PostListItem.fromJson(Map<String, dynamic> json) {
    return PostListItem(
      postId: json['postId'] as int,
      memberId: json['memberId'] as int,
      authorNickname: json['authorNickname'] as String?,
      category: json['category'] as String,
      title: json['title'] as String,
      viewCount: json['viewCount'] as int,
      likeCount: json['likeCount'] as int,
      imageCount: json['imageCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'memberId': memberId,
      'authorNickname': authorNickname,
      'category': category,
      'title': title,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'imageCount': imageCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Helper getters
  String get categoryName {
    switch (category) {
      case '전체':
        return '전체';
      case '식단':
        return '식단';
      case '운동':
        return '운동';
      case '자유':
        return '자유';
      default:
        return category;
    }
  }

  bool get hasImages => imageCount > 0;

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}년 전';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}개월 전';
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
