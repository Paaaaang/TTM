/// 게시글 상세 화면
/// PostDetailScreen.tsx를 Flutter로 변환
import 'package:flutter/material.dart';

/// 댓글 모델
class Comment {
  final int id;
  final String author;
  final String authorAvatar;
  final DateTime createdAt;
  final String content;
  final int likes;
  final bool isLiked;

  Comment({
    required this.id,
    required this.author,
    required this.authorAvatar,
    required this.createdAt,
    required this.content,
    required this.likes,
    this.isLiked = false,
  });
}

/// 게시글 상세 화면 위젯
class PostDetailScreen extends StatefulWidget {
  final int postId;

  const PostDetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  // 더미 게시글 데이터
  final String _author = '건강러버';
  final String _authorAvatar = '💪';
  final String _content = '오늘 처음으로 5km 달리기 성공했어요! 너무 뿌듯해요 🏃‍♀️\n\n꾸준히 하니까 정말 체력이 늘어나는게 느껴져요. 다들 화이팅!';
  final DateTime _createdAt = DateTime.now().subtract(const Duration(hours: 2));
  int _likes = 24;
  bool _isLiked = false;

  // 더미 댓글 데이터
  final List<Comment> _comments = [
    Comment(
      id: 1,
      author: '다이어터',
      authorAvatar: '🥗',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      content: '대단해요! 저도 열심히 해야겠어요 💪',
      likes: 3,
      isLiked: false,
    ),
    Comment(
      id: 2,
      author: '요가마스터',
      authorAvatar: '🧘',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      content: '5km는 정말 대단한데요! 축하해요 🎉',
      likes: 2,
      isLiked: true,
    ),
    Comment(
      id: 3,
      author: '근육왕',
      authorAvatar: '🏋️',
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      content: '꾸준함이 답이죠! 저도 응원합니다 😊',
      likes: 1,
      isLiked: false,
    ),
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('게시글'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: _showPostOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // 스크롤 가능한 영역
          Expanded(
            child: ListView(
              children: [
                // 게시글 카드
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 작성자 정보
                      Row(
                        children: [
                          // 아바타
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _authorAvatar,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 이름 및 시간
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _author,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _getTimeAgo(_createdAt),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // 게시글 내용
                      Text(
                        _content,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 좋아요 버튼 및 수
                      Row(
                        children: [
                          InkWell(
                            onTap: _toggleLike,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _isLiked ? Colors.red[50] : Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isLiked ? Icons.favorite : Icons.favorite_border,
                                    size: 18,
                                    color: _isLiked ? Colors.red : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$_likes',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _isLiked ? Colors.red : Colors.grey[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 18,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_comments.length}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // 댓글 섹션
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '댓글 ${_comments.length}개',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 댓글 목록
                      ..._comments.map((comment) => _buildCommentCard(comment)).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 댓글 입력 바
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12 + MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: '댓글을 입력하세요...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 전송 버튼
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _submitComment,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 댓글 카드
  Widget _buildCommentCard(Comment comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 아바타
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                comment.authorAvatar,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 댓글 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 작성자 및 시간
                Row(
                  children: [
                    Text(
                      comment.author,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getTimeAgo(comment.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // 댓글 텍스트
                Text(
                  comment.content,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                // 좋아요
                InkWell(
                  onTap: () {
                    setState(() {
                      // TODO: 댓글 좋아요 토글
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        comment.isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 14,
                        color: comment.isLiked ? Colors.red : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${comment.likes}',
                        style: TextStyle(
                          fontSize: 12,
                          color: comment.isLiked ? Colors.red : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 좋아요 토글
  void _toggleLike() {
    setState(() {
      if (_isLiked) {
        _likes--;
      } else {
        _likes++;
      }
      _isLiked = !_isLiked;
    });
  }

  /// 댓글 작성
  void _submitComment() {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _comments.insert(
        0,
        Comment(
          id: _comments.length + 1,
          author: '나',
          authorAvatar: '😊',
          createdAt: DateTime.now(),
          content: _commentController.text.trim(),
          likes: 0,
          isLiked: false,
        ),
      );
    });

    _commentController.clear();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('댓글이 작성되었습니다')),
    );
  }

  /// 시간 표시 변환
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${dateTime.month}월 ${dateTime.day}일';
    }
  }

  /// 게시글 옵션 메뉴
  void _showPostOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('공유하기'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 공유 기능
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: const Text('신고하기', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                // TODO: 신고 기능
              },
            ),
          ],
        ),
      ),
    );
  }
}
