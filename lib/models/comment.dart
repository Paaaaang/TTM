/// 댓글 모델
///
/// DB 테이블: post_comment
/// - comment_id (INT PK) → commentId
/// - post_id (INT FK) → postId
/// - member_id (INT FK) → memberId
/// - parent_comment_id (INT FK) → parentCommentId
/// - content (TEXT) → content
/// - like_count (INT) → likeCount
/// - created_at (TIMESTAMP) → createdAt
class Comment {
  final int commentId;
  final int postId;
  final int memberId;
  final int? parentCommentId;
  final String authorNickname;
  final String? authorProfileImage;
  final String content;
  final DateTime createdAt;
  final int likeCount;
  final bool isLiked;
  final List<Comment> replies;

  Comment({
    required this.commentId,
    required this.postId,
    required this.memberId,
    this.parentCommentId,
    required this.authorNickname,
    this.authorProfileImage,
    required this.content,
    required this.createdAt,
    required this.likeCount,
    this.isLiked = false,
    this.replies = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    // replies 처리
    List<Comment> repliesList = [];
    if (json['replies'] != null) {
      repliesList = (json['replies'] as List)
          .map((item) => Comment.fromJson(item))
          .toList();
    }

    return Comment(
      commentId: json['commentId'] as int,
      postId: json['postId'] as int,
      memberId: json['memberId'] as int,
      parentCommentId: json['parentCommentId'] as int?,
      authorNickname: json['authorNickname'] as String,
      authorProfileImage: json['authorProfileImage'] as String?,
      content: json['content'] as String,
      createdAt: (json['createdAt'] != null && json['createdAt'] != "")
        ? DateTime.parse(json['createdAt'] as String) 
        : DateTime.now(),
      likeCount: json['likeCount'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      replies: repliesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commentId': commentId,
      'postId': postId,
      'memberId': memberId,
      'parentCommentId': parentCommentId,
      'authorNickname': authorNickname,
      'authorProfileImage': authorProfileImage,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'likeCount': likeCount,
      'isLiked': isLiked,
      'replies': replies.map((e) => e.toJson()).toList(),
    };
  }

  Comment copyWith({
    int? commentId,
    int? postId,
    int? memberId,
    int? parentCommentId,
    String? authorNickname,
    String? authorProfileImage,
    String? content,
    DateTime? createdAt,
    int? likeCount,
    bool? isLiked,
    List<Comment>? replies,
  }) {
    return Comment(
      commentId: commentId ?? this.commentId,
      postId: postId ?? this.postId,
      memberId: memberId ?? this.memberId,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      authorNickname: authorNickname ?? this.authorNickname,
      authorProfileImage: authorProfileImage ?? this.authorProfileImage,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      replies: replies ?? this.replies,
    );
  }
}
