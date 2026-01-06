// 홈 화면 - 식단/운동/커뮤니티 탭과 칼로리 트래커
// MainScreen.tsx의 홈 탭 콘텐츠를 Flutter로 변환
import 'package:flutter/material.dart';
import 'package:ttm/constants/app_colors.dart';
import 'package:ttm/screens/calorie_detail_popup.dart';
import 'package:ttm/services/auth_service.dart';
import 'package:ttm/services/meal_service.dart';
import 'package:ttm/services/exercise_service.dart';
import 'package:ttm/services/post_service.dart';
import 'package:ttm/models/user.dart';
import 'package:ttm/models/meal_log.dart';
import 'package:ttm/models/exercise_log.dart';
import 'package:ttm/models/post.dart';
// 홈 화면 위젯
// 상단: 칼로리 트래커
// 중단: 식단/운동/커뮤니티 탭
// 하단: 각 탭의 콘텐츠
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 스크롤 컨트롤러
  final ScrollController _scrollController = ScrollController();
  
  // 현재 활성화된 탭 (0: 식단, 1: 운동, 2: 커뮤니티)
  int _currentTab = 0;  
  /// 인증 서비스
  final AuthService _authService = AuthService();
  
  /// 식단 서비스
  final MealService _mealService = MealService();
  
  /// 운동 서비스
  final ExerciseService _exerciseService = ExerciseService();
  
  /// 커뮤니티 서비스
  final PostService _postService = PostService();
  
  /// 현재 사용자 정보
  User? _currentUser;
  
  /// 오늘의 식단 데이터 (DB에서 로드)
  List<MealLog> _todayMeals = [];
  
  /// 오늘의 운동 데이터 (DB에서 로드)
  List<ExerciseLog> _todayExercises = [];
  
  /// 커뮤니티 게시글 데이터 (DB에서 로드)
  List<PostListItem> _todayCommunityPosts = [];
  
  /// 로딩 상태
  bool _isLoadingMeals = false;
  bool _isLoadingExercises = false;
  bool _isLoadingCommunityPosts = false;
  
  final GlobalKey _dietKey = GlobalKey();
  final GlobalKey _exerciseKey = GlobalKey();
  final GlobalKey _communityKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadUserInfo();
    _loadTodayMeals();
    _loadTodayExercises();
    _loadTodayCommunityPosts();
  }
  
  /// 사용자 정보 로드
  Future<void> _loadUserInfo() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }
  
  /// 오늘의 식단 데이터 로드
  Future<void> _loadTodayMeals() async {
    if (_currentUser == null) {
      // 사용자 정보가 없으면 먼저 로드
      await _loadUserInfo();
    }
    
    if (_currentUser == null) {
      return; // 여전히 사용자 정보가 없으면 리턴
    }
    
    setState(() {
      _isLoadingMeals = true;
    });
    
    try {
      final meals = await _mealService.getTodayMeals(_currentUser!.memberId);
      if (mounted) {
        setState(() {
          _todayMeals = meals;
          _isLoadingMeals = false;
        });
      }
    } catch (e) {
      print('오늘 식단 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isLoadingMeals = false;
        });
      }
    }
  }

  /// 오늘의 운동 데이터 로드
  Future<void> _loadTodayExercises() async {
    if (_currentUser == null) {
      // 사용자 정보가 없으면 먼저 로드
      await _loadUserInfo();
    }
    
    if (_currentUser == null) {
      return; // 여전히 사용자 정보가 없으면 리턴
    }
    
    setState(() {
      _isLoadingExercises = true;
    });
    
    try {
      final exercises = await _exerciseService.getTodayExercises(_currentUser!.memberId);
      if (mounted) {
        setState(() {
          _todayExercises = exercises;
          _isLoadingExercises = false;
        });
      }
    } catch (e) {
      print('오늘 운동 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isLoadingExercises = false;
        });
      }
    }
  }

  /// 커뮤니티 게시글 데이터 로드 (최신 10개)
  Future<void> _loadTodayCommunityPosts() async {
    setState(() {
      _isLoadingCommunityPosts = true;
    });
    
    try {
      // 전체 카테고리, 최신 10개 게시물 조회
      final posts = await _postService.getPostsList(
        page: 1,
        limit: 10,
        category: null, // 전체 카테고리
      );
      if (mounted) {
        setState(() {
          _todayCommunityPosts = posts;
          _isLoadingCommunityPosts = false;
        });
      }
    } catch (e) {
      print('커뮤니티 게시글 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isLoadingCommunityPosts = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 스크롤 리스너 - 현재 보이는 섹션 추적
  void _onScroll() {
    final dietPosition = _getWidgetPosition(_dietKey);
    final exercisePosition = _getWidgetPosition(_exerciseKey);
    final communityPosition = _getWidgetPosition(_communityKey);
    
    // 각 섹션의 상단 위치가 화면 상단에서 250px 이내에 있는지 확인
    if (communityPosition != null && communityPosition <= 250 && communityPosition >= -100) {
      if (_currentTab != 2) setState(() => _currentTab = 2);
    } else if (exercisePosition != null && exercisePosition <= 250 && exercisePosition >= -100) {
      if (_currentTab != 1) setState(() => _currentTab = 1);
    } else if (dietPosition != null && dietPosition <= 250) {
      if (_currentTab != 0) setState(() => _currentTab = 0);
    }
  }

  // 위젯의 화면 내 위치 가져오기
  double? _getWidgetPosition(GlobalKey key) {
    final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    final position = renderBox.localToGlobal(Offset.zero);
    return position.dy;
  }

  // 특정 섹션으로 스크롤
  void _scrollToSection(int index) {
    GlobalKey? targetKey;
    switch (index) {
      case 0:
        targetKey = _dietKey;
        break;
      case 1:
        targetKey = _exerciseKey;
        break;
      case 2:
        targetKey = _communityKey;
        break;
    }
    
    if (targetKey?.currentContext != null) {
      setState(() => _currentTab = index);
      Scrollable.ensureVisible(
        targetKey!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    }
  }

  // 식단 칼로리 계산 (특정 식사 유형)
  int _calculateMealCalories(String mealType) {
    return _todayMeals
        .where((meal) => meal.mealType == mealType)
        .fold<int>(0, (sum, meal) => sum + meal.totalCalories.toInt());
  }

  // 총 칼로리 계산
  int get _totalCalories {
    return _todayMeals.fold<int>(0, (sum, meal) => sum + meal.totalCalories.toInt());
  }

  // 운동 소모 칼로리 계산
  int get _totalExerciseCalories {
    return _todayExercises.fold<int>(0, (sum, ex) => sum + (ex.caloriesBurned?.toInt() ?? 0));
  }

  // 순 칼로리 (섭취 - 소모)
  int get _netCalories => _totalCalories - _totalExerciseCalories;

  // 목표 칼로리
  final int _targetCalories = 2000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // 상단 헤더 (칼로리 트래커) - 고정
          _buildHeader(),
          // 탭 바 - 고정
          _buildFixedTabBar(),
          // 스크롤 가능한 콘텐츠
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  // 식단 섹션
                  _buildSection('식단', _buildDietContent(), _dietKey),
                  // 운동 섹션
                  _buildSection('운동', _buildExerciseContent(), _exerciseKey),
                  // 커뮤니티 섹션
                  _buildSection('커뮤니티', _buildCommunityContent(), _communityKey),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 상단 헤더 빌드 (칼로리 트래커)
  Widget _buildHeader() {
    final String userNickname = _currentUser?.nickname ?? '사용자';
    final double progressPercent = (_netCalories / _targetCalories).clamp(0.0, 1.0);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 타이틀과 사용자 이름
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TTM',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$userNickname님',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 칼로리 트래커 카드
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => CalorieDetailPopup(
                      intakeCalories: _totalCalories,
                      burnedCalories: _totalExerciseCalories,
                      targetCalories: _targetCalories,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // 칼로리 텍스트
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '오늘의 칼로리',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '$_netCalories / $_targetCalories kcal',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    // 진행 바
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progressPercent,
                        minHeight: 10,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ],
                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 고정 탭 바 빌드
  Widget _buildFixedTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabButton('식단', Icons.restaurant_menu, 0),
          _buildTabButton('운동', Icons.fitness_center, 1),
          _buildTabButton('커뮤니티', Icons.people, 2),
        ],
      ),
    );
  }

  // 탭 버튼 빌드
  Widget _buildTabButton(String title, IconData icon, int index) {
    final isActive = _currentTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => _scrollToSection(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? const Color(0xFF1DB954) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? const Color(0xFF1DB954) : Colors.grey[400],
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  color: isActive ? Colors.black87 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 섹션 빌드
  Widget _buildSection(String title, Widget content, GlobalKey key) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (title == '식단')
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/meal/add'),
                    child: const Text('추가'),
                  )
                else if (title == '운동')
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/exercise/add'),
                    child: const Text('추가'),
                  )
                else if (title == '커뮤니티')
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/community'),
                    child: const Text('더보기'),
                  ),
              ],
            ),
          ),
          content,
        ],
      ),
    );
  }

  // 식단 콘텐츠 빌드 (2x2 그리드)
  Widget _buildDietContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 0.85,
        children: [
          _buildMealCard('breakfast', '아침', '🌅'),
          _buildMealCard('lunch', '점심', '🌞'),
          _buildMealCard('dinner', '저녁', '🌙'),
          _buildMealCard('snack', '간식', '🍎'),
        ],
      ),
    );
  }

  // 식사 카드 빌드 (DB 연동 버전)
  Widget _buildMealCard(String type, String title, String emoji) {
    // 해당 식사 유형의 식단 필터링
    final mealLogs = _todayMeals.where((meal) => meal.mealType == type).toList();
    final totalCalories = _calculateMealCalories(type);
    final hasMeal = mealLogs.isNotEmpty;

    return GestureDetector(
      onTap: () async {
        // TODO: 식단 추가/수정 화면으로 이동
        final result = await Navigator.pushNamed(context, '/meal/camera');
        if (result != null && result is Map<String, dynamic>) {
          // 식단 추가 후 새로고침
          await _loadTodayMeals();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('식단이 추가되었습니다'),
                backgroundColor: Color(0xFF1DB954),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  // + 버튼
                  InkWell(
                    onTap: () async {
                      // TODO: 식단 추가 화면
                      final result = await Navigator.pushNamed(context, '/meal/camera');
                      if (result != null) {
                        await _loadTodayMeals();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('식단이 추가되었습니다'),
                              backgroundColor: Color(0xFF1DB954),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1DB954),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 콘텐츠 영역
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 로딩 또는 데이터 표시
                    if (_isLoadingMeals)
                      const Center(child: CircularProgressIndicator())
                    else if (hasMeal)
                      // 식단이 있으면 음식 목록 표시
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 음식 항목들
                            Expanded(
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: mealLogs.first.items.length > 3 ? 3 : mealLogs.first.items.length,
                                itemBuilder: (context, index) {
                                  final item = mealLogs.first.items[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      '• ${item.foodName}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (mealLogs.first.items.length > 3)
                              Text(
                                '외 ${mealLogs.first.items.length - 3}개',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                          ],
                        ),
                      )
                    else
                      // 식단이 없으면 플레이스홀더
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.restaurant_menu,
                            color: Colors.grey[300],
                            size: 36,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // 하단: 칼로리 표시
                    if (hasMeal)
                      Text(
                        '$totalCalories kcal',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1DB954),
                        ),
                      )
                    else
                      Text(
                        '식단 추가',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 운동 콘텐츠 빌드 (DB 연동 버전)
  Widget _buildExerciseContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '오늘의 운동',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Icon(Icons.fitness_center, color: Colors.grey[500], size: 20),
            ],
          ),
          const SizedBox(height: 16),
          
          // 로딩 중
          if (_isLoadingExercises)
            const Center(child: CircularProgressIndicator())
          
          // 운동 기록이 없을 때
          else if (_todayExercises.isEmpty)
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('운동 기록 추가 화면은 준비중입니다')),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 48),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        '아직 기록된 운동이 없습니다',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '운동 기록을 추가해보세요!',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          
          // 운동 기록이 있을 때 (DB 데이터)
          else ...[
            ..._todayExercises.map((exercise) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.exerciseName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              exercise.durationFormatted,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          exercise.caloriesFormatted,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF6B6B),
                          ),
                        ),
                      ],
                    ),
                    if (exercise.memo != null && exercise.memo!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        exercise.memo!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  // 커뮤니티 콘텐츠 빌드
  Widget _buildCommunityContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '커뮤니티',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Icon(Icons.chat_bubble_outline, color: Colors.grey[500], size: 20),
            ],
          ),
          const SizedBox(height: 16),
          // 로딩 중
          if (_isLoadingCommunityPosts)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          // 게시글이 없을 때
          else if (_todayCommunityPosts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '아직 게시글이 없습니다',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          // 게시글 목록
          else
            ..._todayCommunityPosts.map((post) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // 카테고리 뱃지
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
                                      post.categoryName,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // 작성자
                                  Flexible(
                                    child: Text(
                                      post.authorNickname ?? '익명',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                post.timeAgo,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 이미지 표시 아이콘
                        if (post.hasImages)
                          Icon(
                            Icons.image,
                            size: 20,
                            color: Colors.grey[400],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 제목
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    // 좋아요, 조회수
                    Row(
                      children: [
                        Icon(Icons.thumb_up_outlined,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${post.likeCount}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.visibility_outlined,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${post.viewCount}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          const SizedBox(height: 8),
          // 커뮤니티 더보기 버튼
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('커뮤니티 화면은 준비중입니다')),
                );
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text('커뮤니티 가기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 카테고리별 색상 반환
  Color _getCategoryColor(String category) {
    switch (category) {
      case '식단':
        return AppColors.primary;
      case '운동':
        return AppColors.secondary;
      case '자유':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
