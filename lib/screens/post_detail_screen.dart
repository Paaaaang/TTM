/// 게시글 상세 화면
/// DB 연동 버전 - PostService를 사용하여 실제 게시글 데이터를 불러옴
library;

import 'package:flutter/material.dart';
import 'package:ttm/constants/app_colors.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import '../constants/api_constants.dart';
import '../widgets/profile_avatar.dart';

/// 게시글 상세 화면 위젯
class PostDetailScreen extends StatefulWidget {
  final int postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode(); // 댓글 입력 포커스
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();

  Post? _post;
  bool _isLoading = true;
  int? _currentUserId;
  int _currentImageIndex = 0;
  bool _hasChanges = false;
  
  // 댓글 관련 상태
  List<Comment> _comments = [];
  Comment? _replyingTo; // 답글 작성 중인 대상 댓글

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  /// 사용자 정보 로드
  Future<void> _loadUserInfo() async {
    final user = await _authService.getCurrentUser();
    setState(() {
      _currentUserId = user?.memberId;
    });
    _loadPost();
    _loadComments();
  }

  /// 게시글 불러오기
  Future<void> _loadPost() async {
    try {
      final post = await _postService.getPost(
        widget.postId,
        currentMemberId: _currentUserId,
      );
      setState(() {
        _post = post;
        _isLoading = false;
      });
      _hasChanges = true;
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('게시글을 불러오는데 실패했습니다: $e')));
      }
    }
  }

  /// 댓글 불러오기
  Future<void> _loadComments() async {
    try {
      final comments = await _postService.getComments(
        widget.postId,
        currentMemberId: _currentUserId,
      );
      setState(() {
        _comments = comments;
      });
    } catch (e) {
      if (mounted) {
        print('댓글 로드 실패: $e');
      }
    }
  }

  /// 좋아요 토글 (인스타그램 스타일)
  Future<void> _toggleLike() async {
    if (_post == null || _currentUserId == null) return;

    try {
      _hasChanges = true;
      // UI 즉시 업데이트
      setState(() {
        _post = _post!.copyWith(
          isLiked: !_post!.isLiked,
          likeCount: _post!.isLiked
              ? _post!.likeCount - 1
              : _post!.likeCount + 1,
        );
      });

      // 서버 요청
      if (_post!.isLiked) {
        await _postService.likePost(widget.postId, _currentUserId!);
      } else {
        await _postService.unlikePost(widget.postId, _currentUserId!);
      }
    } catch (e) {
      // 에러 발생 시 롤백
      setState(() {
        _post = _post!.copyWith(
          isLiked: !_post!.isLiked,
          likeCount: _post!.isLiked
              ? _post!.likeCount - 1
              : _post!.likeCount + 1,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('좋아요 처리 실패: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, _hasChanges);
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context, _hasChanges),
            ),
            title: const Text('게시글'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_post == null) {
      return WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, _hasChanges);
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context, _hasChanges),
            ),
            title: const Text('게시글'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          body: const Center(child: Text('게시글을 찾을 수 없습니다')),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanges);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
          title: const Text('게시글'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: () async {
                final currentUser = await _authService.getCurrentUser();
                final isMyPost =
                    currentUser != null &&
                    currentUser.memberId == _post!.memberId;
                _showPostOptions(isMyPost);
              },
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
                            ProfileAvatar(
                              size: 48,
                              profileImageUrl: _post!.authorProfileImage,
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
                                        _post!.authorNickname ?? '익명',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // 카테고리 배지
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getCategoryColor(
                                            _post!.category,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          _getCategoryName(_post!.category),
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
                                    _getTimeAgo(_post!.createdAt),
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

                        // 게시글 제목
                        if (_post!.title.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              _post!.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                        // 게시글 내용
                        Text(
                          _post!.content,
                          style: const TextStyle(fontSize: 15, height: 1.6),
                        ),

                        // 이미지가 있는 경우 캐러셀로 표시
                        if (_post!.images.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          CarouselSlider(
                            options: CarouselOptions(
                              aspectRatio: 1,
                              viewportFraction: 1,
                              enableInfiniteScroll: _post!.images.length > 1,
                              onPageChanged: (index, reason) {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              },
                            ),
                            items: _post!.images.map((image) {
                              return Builder(
                                builder: (BuildContext context) {
                                  return Container(
                                    width: MediaQuery.of(context).size.width,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Builder(
                                        builder: (context) {
                                          String imageUrl;
                                          if (image.imagePath.startsWith('http')) {
                                            // 이미 완전한 URL
                                            imageUrl = image.imagePath;
                                          } else if (image.imagePath.startsWith('/')) {
                                            // 슬래시로 시작하는 상대 경로
                                            imageUrl = '${ApiConstants.baseUrl}${image.imagePath}';
                                          } else {
                                            // 슬래시 없는 상대 경로
                                            imageUrl = '${ApiConstants.baseUrl}/${image.imagePath}';
                                          }
                                          return Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Container(
                                                color: Colors.grey[200],
                                                child: Center(
                                                  child: CircularProgressIndicator(
                                                    value: loadingProgress.expectedTotalBytes != null
                                                        ? loadingProgress.cumulativeBytesLoaded /
                                                            loadingProgress.expectedTotalBytes!
                                                        : null,
                                                  ),
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[200],
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                      Icons.broken_image,
                                                      size: 50,
                                                      color: Colors.grey,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      '이미지를 불러올 수 없습니다',
                                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                          if (_post!.images.length > 1) ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: _post!.images.asMap().entries.map((
                                entry,
                              ) {
                                return Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentImageIndex == entry.key
                                        ? AppColors.primary
                                        : Colors.grey[300],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],

                        const SizedBox(height: 20),

                        // 좋아요, 조회수, 댓글수
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
                                  color: _post!.isLiked
                                      ? Colors.red[50]
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _post!.isLiked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      size: 18,
                                      color: _post!.isLiked
                                          ? Colors.red
                                          : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${_post!.likeCount}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _post!.isLiked
                                            ? Colors.red
                                            : Colors.grey[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.remove_red_eye_outlined,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_post!.viewCount}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
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
                        if (_comments.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child: Center(
                              child: Text(
                                '첫 번째 댓글을 남겨보세요!',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _comments.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              return _buildCommentItem(_comments[index]);
                            },
                          ),
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
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: 8 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_replyingTo != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'To: ${_replyingTo!.authorNickname}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              setState(() {
                                _replyingTo = null;
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 16,
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      // 프로필 이미지 제거됨
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          focusNode: _commentFocusNode,
                          decoration: InputDecoration(
                            hintText: _replyingTo != null ? '답글 추가...' : '댓글 추가...',
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          maxLines: null,
                          minLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _submitComment,
                        icon: const Icon(Icons.send),
                        color: AppColors.primary,
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

  /// 재귀적으로 댓글과 대댓글을 렌더링
  Widget _buildCommentItem(Comment comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 현재 댓글 렌더링
        _buildSingleComment(comment),

        // 2. 대댓글이 있다면 들여쓰기 후 렌더링
        if (comment.replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 48), // 대댓글 들여쓰기
            child: Column(
              children: comment.replies.map((reply) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _buildCommentItem(reply), // 대대댓글도 가능하도록 재귀
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  /// 단일 댓글 UI (프로필, 내용, 좋아요/답글 버튼)
  Widget _buildSingleComment(Comment comment) {
    final bool isMyComment = _currentUserId != null && comment.memberId == _currentUserId;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 프로필 이미지
        ProfileAvatar(
          profileImageUrl: comment.authorProfileImage,
          nickname: comment.authorNickname,
          size: 40,
        ),
        const SizedBox(width: 12),

        // 내용
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 닉네임 + 시간
              Row(
                children: [
                  Text(
                    comment.authorNickname,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getTimeAgo(comment.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // 텍스트
              Text(
                comment.content,
                style: const TextStyle(
                  fontSize: 14, 
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),

              // 액션 버튼들 (좋아요, 답글, 삭제)
              Row(
                children: [
                  // 좋아요
                  InkWell(
                    onTap: () => _toggleCommentLike(comment),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          comment.isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 16,
                          color: comment.isLiked ? Colors.red : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${comment.likeCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: comment.isLiked
                                ? Colors.red
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 답글 달기
                  InkWell(
                    onTap: () {
                      setState(() {
                        _replyingTo = comment;
                      });
                      FocusScope.of(context).requestFocus(_commentFocusNode);
                    },
                    child: Text(
                      '답글 달기',
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600]
                      ),
                    ),
                  ),

                  // 삭제 (내 댓글인 경우)
                  if (isMyComment) ...[
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () => _deleteComment(comment),
                      child: Text(
                        '삭제',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[300],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 댓글 작성
  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다')),
        );
      }
      return;
    }

    try {
      final newComment = await _postService.createComment(
        postId: widget.postId,
        memberId: currentUser.memberId,
        content: content,
        parentCommentId: _replyingTo?.commentId,
      );

      setState(() {
        if (newComment.parentCommentId != null) {
          _addReplyToParent(_comments, newComment.parentCommentId!, newComment);
        } else {
          _comments.insert(0, newComment);
        }
        _replyingTo = null;
      });

      _commentController.clear();
      FocusScope.of(context).unfocus();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('댓글 작성 실패: $e')),
        );
      }
    }
  }

  void _addReplyToParent(List<Comment> list, int parentId, Comment newReply) {
    for (var comment in list) {
      if (comment.commentId == parentId) {
        comment.replies.add(newReply);
        return;
      }
      if (comment.replies.isNotEmpty) {
        _addReplyToParent(comment.replies, parentId, newReply);
      }
    }
  }

  Future<void> _toggleCommentLike(Comment comment) async {
    if (_currentUserId == null) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다')),
       );
       return;
    }

    final oldState = comment;
    // 낙관적 업데이트
    final newState = comment.copyWith(
      isLiked: !comment.isLiked,
      likeCount: comment.isLiked ? comment.likeCount - 1 : comment.likeCount + 1,
    );

    setState(() {
      _updateCommentInList(_comments, newState);
    });

    try {
      await _postService.toggleCommentLike(comment.commentId, _currentUserId!);
    } catch (e) {
      // 롤백
      if (mounted) {
        setState(() {
          _updateCommentInList(_comments, oldState);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('좋아요 처리에 실패했습니다')),
        );
      }
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    if (_currentUserId == null) return;

    // 간단한 확인 대화상자
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('이 댓글을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('삭제', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _postService.deleteComment(comment.commentId, _currentUserId!);
      setState(() {
        _removeCommentFromList(_comments, comment.commentId);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('댓글 삭제 실패: $e')),
        );
      }
    }
  }

  void _removeCommentFromList(List<Comment> list, int commentId) {
    list.removeWhere((c) => c.commentId == commentId);
    for (var c in list) {
      if (c.replies.isNotEmpty) {
        _removeCommentFromList(c.replies, commentId);
      }
    }
  }

  void _updateCommentInList(List<Comment> list, Comment updated) {
    for (int i = 0; i < list.length; i++) {
      if (list[i].commentId == updated.commentId) {
        list[i] = updated;
        return;
      }
      if (list[i].replies.isNotEmpty) {
        _updateCommentInList(list[i].replies, updated);
      }
    }
  }

  /// 카테고리 이름 변환
  String _getCategoryName(String category) {
    switch (category.toUpperCase()) {
      case 'NOTICE':
        return '공지';
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
    switch (category.toUpperCase()) {
      case 'NOTICE':
        return Colors.red;
      case 'FREE':
        return Colors.blue;
      case 'QNA':
        return Colors.orange;
      case 'REVIEW':
        return Colors.purple;
      default:
        return Colors.grey;
    }
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
  void _showPostOptions(bool isMyPost) {
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
            if (isMyPost) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('수정하기'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 게시글 수정 화면으로 이동
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('게시글 수정 기능은 준비 중입니다')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('삭제하기', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete();
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('공유하기'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 공유 기능
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('공유 기능은 준비 중입니다')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.report, color: Colors.red),
                title: const Text('신고하기', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 신고 기능
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('신고 기능은 준비 중입니다')),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 게시글 삭제 확인
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('정말로 이 게시글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePost();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  /// 게시글 삭제
  Future<void> _deletePost() async {
    try {
      // 삭제 API 호출
      await _postService.deletePost(widget.postId);
      
      if (mounted) {
        _hasChanges = true;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(
          content: Text('게시글이 삭제되었습니다'),
          backgroundColor: Color(0xFF1DB954),
        ));
        Navigator.pop(context, true); // 상세 화면 닫기 (삭제 완료)
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
          content: Text('삭제에 실패했습니다: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }
}

/// 네트워크 이미지 위젯 (간단한 구현)
class ClipRRectImage extends StatelessWidget {
  final BorderRadius borderRadius;
  final BoxFit fit;
  final String imageUrl;

  const ClipRRectImage({
    super.key,
    required this.borderRadius,
    required this.fit,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: 실제 이미지 URL 처리
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image, size: 60, color: Colors.grey),
        ),
      ),
    );
  }
}
