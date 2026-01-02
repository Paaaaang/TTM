/// 커뮤니티 홈 화면
/// CommunityHomeScreen.tsx를 Flutter로 변환
import 'package:flutter/material.dart';

/// 게시글 모델
class Post {
  final int id;
  final String author;
  final String authorAvatar;
  final DateTime createdAt;
  final String content;
  final List<String> images;
  final int likes;
  final int comments;
  final bool isLiked;

  Post({
    required this.id,
    required this.author,
    required this.authorAvatar,
    required this.createdAt,
    required this.content,
    required this.images,
    required this.likes,
    required this.comments,
    this.isLiked = false,
  });
}

/// 커뮤니티 홈 화면 위젯
class CommunityHomeScreen extends StatefulWidget {
  const CommunityHomeScreen({Key? key}) : super(key: key);

  @override
  State<CommunityHomeScreen> createState() => _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends State<CommunityHomeScreen> {
  // 더미 게시글 데이터
  final List<Post> _posts = [
    Post(
      id: 1,
      author: '건강러버',
      authorAvatar: '💪',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      content: '오늘 처음으로 5km 달리기 성공했어요! 너무 뿌듯해요 🏃‍♀️\n\n꾸준히 하니까 정말 체력이 늘어나는게 느껴져요. 다들 화이팅!',
      images: [],
      likes: 24,
      comments: 8,
      isLiked: false,
    ),
    Post(
      id: 2,
      author: '다이어터',
      authorAvatar: '🥗',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      content: '한 달간의 식단 관리 결과 -3kg 성공! 💯\n\n식단 조절이 제일 중요한 것 같아요. 여러분도 할 수 있어요!',
      images: [],
      likes: 42,
      comments: 15,
      isLiked: true,
    ),
    Post(
      id: 3,
      author: '요가마스터',
      authorAvatar: '🧘',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      content: '아침 요가 30분 루틴 공유합니다.\n\n1. 고양이 자세 10회\n2. 다운독 20초\n3. 전사 자세 좌우 각 30초\n\n하루를 상쾌하게 시작하세요! ☀️',
      images: [],
      likes: 38,
      comments: 12,
      isLiked: false,
    ),
    Post(
      id: 4,
      author: '근육왕',
      authorAvatar: '🏋️',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
      content: '오늘의 운동 완료! 💪\n\n스쿼트 100개\n푸시업 50개\n플랭크 3분\n\n땀 흘리고 나니 기분이 너무 좋아요!',
      images: [],
      likes: 31,
      comments: 6,
      isLiked: false,
    ),
    Post(
      id: 5,
      author: '채식주의자',
      authorAvatar: '🥬',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      content: '오늘의 비건 도시락 🍱\n\n퀴노아 샐러드\n구운 채소\n두부 스테이크\n\n맛있고 건강한 한 끼였어요!',
      images: [],
      likes: 28,
      comments: 9,
      isLiked: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('커뮤니티'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: 게시글 새로고침
          await Future.delayed(const Duration(seconds: 1));
        },
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            return _buildPostCard(_posts[index]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 게시글 작성 화면으로 이동
          Navigator.pushNamed(context, '/community/create');
        },
        backgroundColor: const Color(0xFF66BB6A),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  /// 게시글 카드
  Widget _buildPostCard(Post post) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 작성자 정보
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
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
                      post.authorAvatar,
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
                        post.author,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _getTimeAgo(post.createdAt),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // 더보기 버튼
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {
                    _showPostOptions(post);
                  },
                ),
              ],
            ),
          ),

          // 게시글 내용
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              post.content,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 좋아요 및 댓글 수
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.favorite,
                  size: 16,
                  color: Colors.red[300],
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.likes}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.comments}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // 액션 버튼들
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        // TODO: 좋아요 토글
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            post.isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color: post.isLiked ? Colors.red : Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '좋아요',
                            style: TextStyle(
                              fontSize: 14,
                              color: post.isLiked ? Colors.red : Colors.grey[700],
                              fontWeight: post.isLiked ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.grey[300],
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      // TODO: 댓글 화면으로 이동
                      Navigator.pushNamed(
                        context,
                        '/community/post',
                        arguments: post.id,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '댓글',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
  void _showPostOptions(Post post) {
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
