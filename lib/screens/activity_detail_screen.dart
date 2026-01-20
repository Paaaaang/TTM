/// 내 활동 상세 화면
/// 운동, 식단, 커뮤니티 글, 좋아요 내역을 확인할 수 있는 화면
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/post.dart';
import '../models/meal_log.dart';
import '../models/exercise_log.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../services/meal_service.dart';
import '../services/exercise_service.dart';

class ActivityDetailScreen extends StatefulWidget {
  const ActivityDetailScreen({super.key});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  final PostService _postService = PostService();
  final MealService _mealService = MealService();
  final ExerciseService _exerciseService = ExerciseService();

  User? _currentUser;
  bool _isLoading = true;
  bool _hasLoadedMyPosts = false;
  bool _hasLoadedLikedPosts = false;

  // 데이터
  List<MealLog> _meals = [];
  List<ExerciseLog> _exercises = [];
  List<PostListItem> _myPosts = [];
  List<PostListItem> _likedPosts = [];

  int _selectedFilter = 0; // 0: 전체, 1: 최근 7일, 2: 최근 30일

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        return;
      }
      if (!mounted) {
        return;
      }

      setState(() {});

      if (_tabController.index == 2 && !_hasLoadedMyPosts) {
        _loadMyPosts();
      } else if (_tabController.index == 3 && !_hasLoadedLikedPosts) {
        _loadLikedPosts();
      }
    });

    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        debugPrint('로그인 정보를 찾을 수 없습니다.');
        return;
      }

      _currentUser = user;

      await Future.wait([_loadMeals(), _loadExercises()]);
    } catch (e) {
      debugPrint('내 활동 초기 데이터 로드 실패: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMeals() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    try {
      final range = _getSelectedDateRange();
      final meals = await _mealService.getMealsByDateRange(
        user.memberId,
        range.start,
        range.end,
      );

      meals.sort((a, b) => b.mealDate.compareTo(a.mealDate));

      if (!mounted) {
        return;
      }
      setState(() {
        _meals = meals;
      });
    } catch (e) {
      debugPrint('식단 데이터 로드 실패: $e');
      if (!mounted) {
        return;
      }
      setState(() {
        _meals = [];
      });
    }
  }

  Future<void> _loadExercises() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    try {
      final range = _getSelectedDateRange();
      final exercises = await _exerciseService.getExercisesByDateRange(
        user.memberId,
        range.start,
        range.end,
      );

      exercises.sort((a, b) => b.exerciseDate.compareTo(a.exerciseDate));

      if (!mounted) {
        return;
      }
      setState(() {
        _exercises = exercises;
      });
    } catch (e) {
      debugPrint('운동 데이터 로드 실패: $e');
      if (!mounted) {
        return;
      }
      setState(() {
        _exercises = [];
      });
    }
  }

  Future<void> _loadMyPosts() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    try {
      final posts = await _postService.getMyPosts(user.memberId);
      if (!mounted) {
        return;
      }
      setState(() {
        _myPosts = posts;
        _hasLoadedMyPosts = true;
      });
    } catch (e) {
      debugPrint('내 게시글 로드 실패: $e');
      if (!mounted) {
        return;
      }
      setState(() {
        _myPosts = [];
        _hasLoadedMyPosts = true;
      });
    }
  }

  Future<void> _loadLikedPosts() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    try {
      final likedPosts = await _postService.getLikedPosts(user.memberId);
      if (!mounted) {
        return;
      }
      setState(() {
        _likedPosts = likedPosts;
        _hasLoadedLikedPosts = true;
      });
    } catch (e) {
      debugPrint('좋아요한 게시글 로드 실패: $e');
      if (!mounted) {
        return;
      }
      setState(() {
        _likedPosts = [];
        _hasLoadedLikedPosts = true;
      });
    }
  }

  Future<void> _onFilterChanged(int index) async {
    if (_selectedFilter == index) {
      return;
    }

    setState(() {
      _selectedFilter = index;
      _isLoading = true;
    });

    try {
      await Future.wait([_loadMeals(), _loadExercises()]);
    } catch (e) {
      debugPrint('필터 변경 처리 실패: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  DateTimeRange _getSelectedDateRange() {
    final now = DateTime.now();

    switch (_selectedFilter) {
      case 1:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
      case 2:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
      default:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 90)),
          end: now,
        );
    }
  }

  Widget _buildFilterChips() {
    final filters = ['전체', '최근 7일', '최근 30일'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(filters.length, (index) {
          final isSelected = _selectedFilter == index;
          return Padding(
            padding: EdgeInsets.only(
              right: index == filters.length - 1 ? 0 : 8,
            ),
            child: ChoiceChip(
              label: Text(filters[index]),
              selected: isSelected,
              onSelected: (value) {
                if (value) {
                  _onFilterChanged(index);
                }
              },
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 활동'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '식단'),
            Tab(text: '운동'),
            Tab(text: '내 글'),
            Tab(text: '좋아요'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
          ? const Center(child: Text('로그인 후 이용해주세요.'))
          : Column(
              children: [
                if (_tabController.index <= 1) _buildFilterChips(),
                if (_tabController.index > 1) const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      RefreshIndicator(
                        onRefresh: _loadMeals,
                        child: _buildMealList(),
                      ),
                      RefreshIndicator(
                        onRefresh: _loadExercises,
                        child: _buildExerciseList(),
                      ),
                      RefreshIndicator(
                        onRefresh: _loadMyPosts,
                        child: _buildMyPostList(),
                      ),
                      RefreshIndicator(
                        onRefresh: _loadLikedPosts,
                        child: _buildLikedPostList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMealList() {
    if (_meals.isEmpty) {
      return const Center(child: Text('식단 기록이 없습니다'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _meals.length,
      itemBuilder: (context, index) {
        final meal = _meals[index];
        return _buildMealCard(meal);
      },
    );
  }

  Widget _buildMealCard(MealLog meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _getMealTypeColor(meal.mealType),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getMealTypeName(meal.mealType),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('yyyy-MM-dd').format(meal.mealDate),
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const Spacer(),
              Text(
                '${meal.totalCalories.toStringAsFixed(0)} kcal',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1DB954),
                ),
              ),
            ],
          ),
          if (meal.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...meal.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(item.foodName, style: const TextStyle(fontSize: 13)),
                    const Spacer(),
                    Text(
                      '${item.caloriesKcal?.toStringAsFixed(0) ?? '0'} kcal',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getMealTypeName(String type) {
    switch (type) {
      case 'BREAKFAST':
        return '아침';
      case 'LUNCH':
        return '점심';
      case 'DINNER':
        return '저녁';
      case 'SNACK':
        return '간식';
      default:
        return type;
    }
  }

  Color _getMealTypeColor(String type) {
    switch (type) {
      case 'BREAKFAST':
        return Colors.orange;
      case 'LUNCH':
        return Colors.green;
      case 'DINNER':
        return Colors.blue;
      case 'SNACK':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildExerciseList() {
    if (_exercises.isEmpty) {
      return const Center(child: Text('운동 기록이 없습니다'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _exercises.length,
      itemBuilder: (context, index) {
        final exercise = _exercises[index];
        return _buildExerciseCard(exercise);
      },
    );
  }

  Widget _buildExerciseCard(ExerciseLog exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1DB954).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Color(0xFF1DB954),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.exerciseName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('yyyy-MM-dd').format(exercise.exerciseDate),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildExerciseInfo(
                Icons.timer_outlined,
                '${exercise.durationMinutes}분',
              ),
              const SizedBox(width: 16),
              _buildExerciseInfo(
                Icons.local_fire_department_outlined,
                '${exercise.caloriesBurned?.toStringAsFixed(0) ?? '0'} kcal',
              ),
            ],
          ),
          if (exercise.memo != null && exercise.memo!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                exercise.memo!,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExerciseInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildMyPostList() {
    if (_myPosts.isEmpty) {
      return const Center(child: Text('작성한 게시글이 없습니다'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myPosts.length,
      itemBuilder: (context, index) {
        final post = _myPosts[index];
        return _buildPostCard(post);
      },
    );
  }

  Widget _buildLikedPostList() {
    if (_likedPosts.isEmpty) {
      return const Center(child: Text('좋아요한 게시글이 없습니다'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _likedPosts.length,
      itemBuilder: (context, index) {
        final post = _likedPosts[index];
        return _buildPostCard(post, highlightLike: true, showAuthor: true);
      },
    );
  }

  Widget _buildPostCard(
    PostListItem post, {
    bool highlightLike = false,
    bool showAuthor = false,
  }) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.pushNamed(
          context,
          '/community/post',
          arguments: post.postId,
        );
        if (result == true) {
          if (highlightLike) {
            _loadLikedPosts();
          } else {
            _loadMyPosts();
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
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
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTimeAgo(post.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        textAlign: TextAlign.right,
                      ),
                      if (showAuthor &&
                          (post.authorNickname?.isNotEmpty ?? false))
                        Text(
                          post.authorNickname!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              post.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildPostStat(
                  highlightLike ? Icons.favorite : Icons.favorite_border,
                  post.likeCount.toString(),
                  color: highlightLike ? Colors.red : null,
                ),
                const SizedBox(width: 12),
                _buildPostStat(
                  Icons.visibility_outlined,
                  post.viewCount.toString(),
                ),
                if (post.imageCount > 0) ...[
                  const SizedBox(width: 12),
                  _buildPostStat(
                    Icons.image_outlined,
                    post.imageCount.toString(),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostStat(IconData icon, String count, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(fontSize: 12, color: color ?? Colors.grey[700]),
        ),
      ],
    );
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'DIET':
        return '식단';
      case 'EXERCISE':
        return '운동';
      case 'LIFESTYLE':
        return '일상';
      case 'FREE':
        return '자유';
      default:
        return category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'DIET':
        return Colors.orange;
      case 'EXERCISE':
        return Colors.blue;
      case 'LIFESTYLE':
        return Colors.purple;
      case 'FREE':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatTimeAgo(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
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
