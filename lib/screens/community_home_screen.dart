/// 커뮤니티 홈 화면 (DB 연동 버전)
/// - DB 데이터 사용
/// - 카테고리 필터링
/// - 좋아요 아이콘으로 표시
/// - 게시글 클릭 시 상세 화면 이동
library;

import 'package:flutter/material.dart';
import 'package:ttm/constants/app_colors.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import '../widgets/profile_avatar.dart';

/// 커뮤니티 홈 화면 위젯
class CommunityHomeScreen extends StatefulWidget {
  const CommunityHomeScreen({super.key});

  @override
  State<CommunityHomeScreen> createState() => CommunityHomeScreenState();
}

class CommunityHomeScreenState extends State<CommunityHomeScreen> {
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();

  List<PostListItem> _posts = [];
  bool _isLoading = true;
  String _selectedCategory = '전체';
  int? _currentUserId;

  // 카테고리 목록
  final List<String> _categories = ['전체', '자유', 'Q&A', '후기'];

  // 카테고리 한글 -> 영문 매핑
  final Map<String, String> _categoryMap = {
    '전체': 'ALL',
    '자유': 'FREE',
    'Q&A': 'QNA',
    '후기': 'REVIEW',
  };

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  /// 외부에서 호출 가능한 새로고침 메서드
  Future<void> refresh() async {
    await _loadUserInfo();
  }

  /// 사용자 정보 로드
  Future<void> _loadUserInfo() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUserId = user?.memberId;
      });
      _loadPosts(forceRefresh: true);
    }
  }

  /// 게시글 로드
  Future<void> _loadPosts({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final category = _selectedCategory == '전체'
          ? null
          : _categoryMap[_selectedCategory];
      final posts = await _postService.getPostsList(
        page: 1,
        limit: 50,
        category: category,
        currentMemberId: _currentUserId, // 좋아요 여부 확인용
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('게시글 로드 오류: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 좋아요 토글 (인스타그램 스타일)
  Future<void> _toggleLike(PostListItem post) async {
    if (_currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다')));
      }
      return;
    }

    try {
      // UI 즉시 업데이트 (낙관적 업데이트)
      setState(() {
        final index = _posts.indexWhere((p) => p.postId == post.postId);
        if (index != -1) {
          final currentPost = _posts[index];
          _posts[index] = PostListItem(
            postId: currentPost.postId,
            memberId: currentPost.memberId,
            authorNickname: currentPost.authorNickname,
            category: currentPost.category,
            title: currentPost.title,
            viewCount: currentPost.viewCount,
            likeCount: post.isLiked
                ? currentPost.likeCount - 1
                : currentPost.likeCount + 1,
            imageCount: currentPost.imageCount,
            isLiked: !post.isLiked,
            createdAt: currentPost.createdAt,
          );
        }
      });

      // 서버 요청
      if (post.isLiked) {
        await _postService.unlikePost(post.postId, _currentUserId!);
      } else {
        await _postService.likePost(post.postId, _currentUserId!);
      }
    } catch (e) {
      // 에러 발생 시 롤백
      setState(() {
        final index = _posts.indexWhere((p) => p.postId == post.postId);
        if (index != -1) {
          final currentPost = _posts[index];
          _posts[index] = PostListItem(
            postId: currentPost.postId,
            memberId: currentPost.memberId,
            authorNickname: currentPost.authorNickname,
            category: currentPost.category,
            title: currentPost.title,
            viewCount: currentPost.viewCount,
            likeCount: post.isLiked
                ? currentPost.likeCount + 1
                : currentPost.likeCount - 1,
            imageCount: currentPost.imageCount,
            isLiked: post.isLiked,
            createdAt: currentPost.createdAt,
          );
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('좋아요 처리 실패: ${e.toString()}')));
      }
    }
  }

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
      body: Column(
        children: [
          // 카테고리 필터
          Container(
            height: 50,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                      _loadPosts(forceRefresh: true);
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // 게시글 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _loadPosts(forceRefresh: true),
                    child: _posts.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height - 200,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.article_outlined,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        '게시글이 없습니다',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '아래로 당겨서 새로고침',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _posts.length,
                            itemBuilder: (context, index) {
                              return _buildPostCard(_posts[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 게시글 작성 화면으로 이동
          final result = await Navigator.pushNamed(
            context,
            '/community/create',
          );
          if (result == true) {
            // 작성 완료 시 목록 새로고침
            _loadPosts(forceRefresh: true);
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  /// 게시글 카드
  Widget _buildPostCard(PostListItem post) {
    return GestureDetector(
      onTap: () async {
        // 게시글 상세 화면으로 이동
        final result = await Navigator.pushNamed(
          context,
          '/community/post',
          arguments: post.postId,
        );
        if (result == true) {
          // 변경 사항 있으면 목록 새로고침
          _loadPosts(forceRefresh: true);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                  ProfileAvatar(
                    size: 40,
                    profileImageUrl: post.authorProfileImage,
                  ),
                  const SizedBox(width: 12),
                  // 이름 및 시간
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.authorNickname ?? '익명',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(post.category),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getCategoryName(post.category),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _getTimeAgo(post.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 더보기 버튼
                  IconButton(
                    icon: const Icon(Icons.more_horiz, size: 20),
                    onPressed: () {
                      _showPostOptions(post);
                    },
                  ),
                ],
              ),
            ),

            // 게시글 제목
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 12),

            // 좋아요 및 통계
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // 좋아요 (인스타그램 스타일)
                  GestureDetector(
                    onTap: () => _toggleLike(post),
                    child: Row(
                      children: [
                        Icon(
                          post.isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 22,
                          color: post.isLiked ? Colors.red : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.likeCount}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 조회수
                  Row(
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.viewCount}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // 이미지 수
                  if (post.imageCount > 0)
                    Row(
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.imageCount}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 카테고리 이름 한글 변환
  String _getCategoryName(String category) {
    switch (category) {
      case 'FREE':
        return '자유';
      case 'QNA':
        return 'Q&A';
      case 'REVIEW':
        return '후기';
      default:
        return category;
    }
  }

  /// 카테고리 색상
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'FREE':
        return Colors.blue[400]!;
      case 'QNA':
        return Colors.orange[400]!;
      case 'REVIEW':
        return Colors.purple[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  /// 아바타 텍스트 (닉네임 첫 글자)
  String _getAvatarText(String nickname) {
    if (nickname.isEmpty) return '?';
    return nickname[0].toUpperCase();
  }

  /// 아바타 색상 (닉네임 기반)
  Color _getAvatarColor(String nickname) {
    final colors = [
      Colors.red[400]!,
      Colors.pink[400]!,
      Colors.purple[400]!,
      Colors.deepPurple[400]!,
      Colors.indigo[400]!,
      Colors.blue[400]!,
      Colors.cyan[400]!,
      Colors.teal[400]!,
      Colors.green[400]!,
      Colors.orange[400]!,
    ];
    final hash = nickname.hashCode.abs();
    return colors[hash % colors.length];
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
  void _showPostOptions(PostListItem post) {
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
            if (post.memberId == _currentUserId) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('수정하기'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 수정 화면으로 이동
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('삭제하기', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  // 삭제 확인 다이얼로그
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('게시글 삭제'),
                      content: const Text('정말로 이 게시글을 삭제하시겠습니까?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('삭제'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      // 게시글 삭제 API 호출
                      await _postService.deletePost(post.postId);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('게시글이 삭제되었습니다'),
                            backgroundColor: Color(0xFF1DB954),
                          ),
                        );
                        // 목록 새로고침
                        _loadPosts();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('삭제에 실패했습니다: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ] else ...[
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
          ],
        ),
      ),
    );
  }
}
