/// 홈 화면 - 식단/운동/커뮤니티 탭과 칼로리 트래커
/// MainScreen.tsx의 홈 탭 콘텐츠를 Flutter로 변환
import 'package:flutter/material.dart';
import 'package:ttm/constants/app_colors.dart';
import 'package:ttm/screens/calorie_detail_popup.dart';

/// 홈 화면 위젯
/// 상단: 칼로리 트래커
/// 중단: 식단/운동/커뮤니티 탭
/// 하단: 각 탭의 콘텐츠
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// 스크롤 컨트롤러
  final ScrollController _scrollController = ScrollController();
  
  /// 현재 활성화된 탭 (0: 식단, 1: 운동, 2: 커뮤니티)
  int _currentTab = 0;
  
  /// 각 섹션의 GlobalKey
  final GlobalKey _dietKey = GlobalKey();
  final GlobalKey _exerciseKey = GlobalKey();
  final GlobalKey _communityKey = GlobalKey();
  
  /// 더미 데이터: 식단 (아침/점심/저녁/간식)
  final Map<String, List<Map<String, dynamic>>> _mealData = {
    'breakfast': [],
    'lunch': [],
    'dinner': [],
    'snack': [],
  };
  
  /// 단식 상태 관리 (각 식사별)
  final Map<String, bool> _fastingState = {
    'breakfast': false,
    'lunch': false,
    'dinner': false,
    'snack': false,
  };

  /// 더미 데이터: 운동
  final List<Map<String, dynamic>> _exerciseData = [];

  /// 더미 데이터: 커뮤니티 게시글
  final List<Map<String, dynamic>> _communityPosts = [
    {
      'id': 1,
      'author': '건강러버',
      'time': '2시간 전',
      'content': '오늘 처음으로 5km 달리기 성공했어요! 너무 뿌듯해요 💪',
      'likes': 24,
      'comments': 8,
    },
    {
      'id': 2,
      'author': '다이어터',
      'time': '5시간 전',
      'content': '한 달간의 식단 관리 결과 -3kg 성공! 여러분도 할 수 있어요!',
      'likes': 42,
      'comments': 15,
    },
    {
      'id': 3,
      'author': '요가마스터',
      'time': '1일 전',
      'content': '아침 요가 30분 루틴 공유합니다. 하루를 상쾌하게 시작하세요 🧘‍♀️',
      'likes': 38,
      'comments': 12,
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 스크롤 리스너 - 현재 보이는 섹션 추적
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

  /// 위젯의 화면 내 위치 가져오기
  double? _getWidgetPosition(GlobalKey key) {
    final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    final position = renderBox.localToGlobal(Offset.zero);
    return position.dy;
  }

  /// 특정 섹션으로 스크롤
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

  /// 식단 칼로리 계산
  int _calculateMealCalories(String mealType) {
    return _mealData[mealType]?.fold<int>(0, (sum, meal) => sum + (meal['calories'] as int? ?? 0)) ?? 0;
  }

  /// 총 칼로리 계산
  int get _totalCalories {
    return _calculateMealCalories('breakfast') +
        _calculateMealCalories('lunch') +
        _calculateMealCalories('dinner') +
        _calculateMealCalories('snack');
  }

  /// 운동 소모 칼로리 계산
  int get _totalExerciseCalories {
    return _exerciseData.fold(0, (sum, ex) => sum + (ex['calories'] as int? ?? 0));
  }

  /// 순 칼로리 (섭취 - 소모)
  int get _netCalories => _totalCalories - _totalExerciseCalories;

  /// 목표 칼로리
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

  /// 상단 헤더 빌드 (칼로리 트래커)
  Widget _buildHeader() {
    // TODO: 실제로는 사용자 정보에서 닉네임을 가져와야 함
    const String userNickname = '사용자';
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

  /// 고정 탭 바 빌드
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

  /// 탭 버튼 빌드
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

  /// 섹션 빌드
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

  /// 식단 콘텐츠 빌드 (2x2 그리드)
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

  /// 식사 카드 빌드 (개선된 버전)
  Widget _buildMealCard(String type, String title, String emoji) {
    final meals = _mealData[type] ?? [];
    final totalCalories = _calculateMealCalories(type);
    final hasMeal = meals.isNotEmpty; // 식단이 추가되었는지 확인
    final hasImage = meals.isNotEmpty && meals.first['image'] != null;
    final isFasting = _fastingState[type] ?? false;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.pushNamed(context, '/meal/camera');
        if (result != null && result is Map<String, dynamic>) {
          setState(() {
            _mealData[type] = [result];
            _fastingState[type] = false; // 식단 추가 시 단식 해제
          });
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
                      final result = await Navigator.pushNamed(context, '/meal/camera');
                      if (result != null && result is Map<String, dynamic>) {
                        setState(() {
                          _mealData[type] = [result];
                          _fastingState[type] = false;
                        });
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
                    // 이미지 또는 플레이스홀더
                    Expanded(
                      child: hasImage
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                meals.first['image'] ?? '',
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.restaurant_menu,
                                      color: Colors.grey[300],
                                      size: 32,
                                    ),
                                  );
                                },
                              ),
                            )
                          : Container(
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
                    
                    // 하단: 칼로리 또는 단식 체크 버튼
                    if (hasMeal)
                      // 식단이 추가되면 총 열량 표시
                      Text(
                        '$totalCalories kcal',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1DB954),
                        ),
                      )
                    else
                      // 식단이 없으면 단식 체크 버튼
                      InkWell(
                        onTap: () {
                          setState(() {
                            _fastingState[type] = !(_fastingState[type] ?? false);
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '단식',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isFasting
                                      ? const Color(0xFF1DB954)
                                      : Colors.grey[600],
                                ),
                              ),
                              Icon(
                                Icons.check,
                                size: 18,
                                color: isFasting
                                    ? const Color(0xFF1DB954)
                                    : Colors.grey[400],
                              ),
                            ],
                          ),
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

  /// 운동 콘텐츠 빌드
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
          // 운동 기록이 없을 때
          if (_exerciseData.isEmpty)
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
            ),
          // 운동 기록이 있을 때
          if (_exerciseData.isNotEmpty) ...[
            ..._exerciseData.map((exercise) {
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
                              exercise['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              exercise['duration'] ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          exercise['time'] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '-${exercise['calories']} kcal',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 8),
            // 운동 추가 버튼
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('운동 기록 추가 화면은 준비중입니다')),
                  );
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text('운동 추가'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 커뮤니티 콘텐츠 빌드
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
          // 게시글 목록
          ..._communityPosts.map((post) {
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
                            post['author'] ?? '',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            post['time'] ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        '👤',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post['content'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.thumb_up_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${post['likes']}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${post['comments']}',
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
}
