// 홈 화면 - 식단/운동/커뮤니티 탭과 칼로리 트래커
// MainScreen.tsx의 홈 탭 콘텐츠를 Flutter로 변환
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ttm/constants/app_colors.dart';
import 'package:ttm/screens/calendar_screen.dart';
import 'package:ttm/services/auth_service.dart';
import 'package:ttm/services/meal_service.dart';
import 'package:ttm/services/exercise_service.dart';
import 'package:ttm/models/user.dart';
import 'package:ttm/models/meal_log.dart';
import 'package:ttm/models/meal_item.dart';
import 'package:ttm/models/exercise_log.dart';
import 'dart:async';
import 'package:ttm/screens/calorie_detail_popup.dart';
import 'package:ttm/constants/api_constants.dart';
import 'package:ttm/screens/ai_coach_screen.dart';
import 'package:ttm/widgets/meal_edit_popup.dart';
import 'package:ttm/services/iot_service.dart';
import 'package:ttm/services/friend_group_service.dart';
import 'package:ttm/services/badge_service.dart';
import 'package:ttm/models/friend_group.dart';
import 'package:ttm/models/badge.dart';
import 'package:ttm/widgets/create_group_dialog.dart';

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

  // 라즈베리파이 연결 상태 (TODO: 실제 상태 연동)
  bool _isRaspberryConnected = false;
  Timer? _iotTimer;
  final IotService _iotService = IotService();
  bool _isIotProcessing = false;
  bool _isFastPolling = false; // 빠른 폴링 모드 플래그
  bool _useDefaultMemberId = false; // 404 발생 시 기본 memberId 사용

  // 현재 활성화된 탭 (0: 식단, 1: 운동)
  int _currentTab = 0;

  // 선택된 날짜 (기본값: 오늘)
  DateTime _selectedDate = DateTime.now();

  /// 인증 서비스
  final AuthService _authService = AuthService();

  /// 식단 서비스
  final MealService _mealService = MealService();

  /// 운동 서비스
  final ExerciseService _exerciseService = ExerciseService();

  /// 친구 그룹 서비스
  final FriendGroupService _friendGroupService = FriendGroupService();
  final BadgeService _badgeService = BadgeService();

  /// 현재 사용자 정보
  User? _currentUser;

  /// 오늘의 식단 데이터 (DB에서 로드)
  List<MealLog> _todayMeals = [];

  /// 오늘의 운동 데이터 (DB에서 로드)
  List<ExerciseLog> _todayExercises = [];

  /// 내 친구 그룹 목록
  List<FriendGroup> _myGroups = [];
  FriendGroup? _selectedGroup;
  List<GroupMemberInfo> _selectedGroupMembers = [];
  bool _isLoadingGroupMembers = false;
  String? _groupMembersError;
  final Map<int, List<GroupMemberInfo>> _groupMembersCache = {};

  /// 친구 목록
  List<User> _friends = [];

  /// 로딩 상태
  bool _isLoadingMeals = false;
  bool _isLoadingExercises = false;
  bool _isLoadingGroups = false;

  final GlobalKey _dietKey = GlobalKey();
  final GlobalKey _exerciseKey = GlobalKey();
  final GlobalKey _friendGroupKey = GlobalKey();

  /// 각 식사 타입별 단식 상태 (breakfast, lunch, dinner, snack)
  Map<String, bool> _fastingStatus = {
    'breakfast': false,
    'lunch': false,
    'dinner': false,
    'snack': false,
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadUserInfo();
    _loadTodayMeals();
    _loadTodayExercises();
    _loadMyGroups();
    _loadFriends();
    // start polling will be kicked after user info is loaded
  }

  /// 사용자 정보 로드
  Future<void> _loadUserInfo() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeShowReportPopup();
      });
      // start IoT status polling when we have a user
      if (_currentUser != null) {
        _startIotPolling();
      }
    }
  }

  void _startIotPolling() {
    // avoid multiple timers
    _iotTimer?.cancel();
    _isFastPolling = false;
    // poll every 3 seconds for faster processing detection
    _iotTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _checkRaspberryStatus();
    });
    // initial check
    _checkRaspberryStatus();
  }

  void _startFastPolling() {
    if (_isFastPolling) return; // already in fast mode
    _iotTimer?.cancel();
    _isFastPolling = true;
    _iotTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      await _checkRaspberryStatus();
    });
  }

  Future<void> _checkRaspberryStatus() async {
    if (_currentUser == null) return;

    // 이미 404 경험이 있으면 바로 기본 memberId 사용
    final memberIdToTry = _useDefaultMemberId ? 1 : _currentUser!.memberId;

    try {
      var status = await _iotService.getStatus(memberIdToTry);
      if (mounted) setState(() => _isRaspberryConnected = status.connected);
      try {
        final proc = await _iotService.getProcessingStatus(memberIdToTry);
        final processing = proc['processing'] == true;
        final wasProcessing = _isIotProcessing; // 이전 상태 저장

        if (mounted) {
          setState(() => _isIotProcessing = processing);

          // Processing이 끝났을 때 (true → false)
          if (wasProcessing && !processing) {
            // 식단 데이터 새로고침
            _loadTodayMeals();
          }

          // If processing started, switch to fast polling
          if (processing && !_isFastPolling) {
            _startFastPolling();
          } else if (!processing && _isFastPolling) {
            // Back to normal polling when processing ends
            _startIotPolling();
          }
        }
      } catch (e) {
        // ignore processing errors here
        if (mounted) setState(() => _isIotProcessing = false);
      }
    } catch (e) {
      // If user-specific status not found (404), try default device memberId=1
      if (e.toString().contains('404') && !_useDefaultMemberId) {
        // 한 번 404 발생 시 다음부터는 기본 memberId 사용
        _useDefaultMemberId = true;
        await _checkRaspberryStatus(); // 재귀 호출로 즉시 재시도
        return;
      }
      if (mounted) setState(() => _isRaspberryConnected = false);
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
      // 선택된 날짜에 해당하는 식단만 가져오기
      final startOfDay = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final endOfDay = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        23,
        59,
        59,
      );

      final meals = await _mealService.getMealsByDateRange(
        _currentUser!.memberId,
        startOfDay,
        endOfDay,
      );

      if (mounted) {
        setState(() {
          _todayMeals = meals;
          _isLoadingMeals = false;
        });
      }
    } catch (e) {
      print('식단 로드 오류: $e');
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
      // 선택된 날짜에 해당하는 운동만 가져오기
      final startOfDay = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final endOfDay = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        23,
        59,
        59,
      );

      final exercises = await _exerciseService.getExercisesByDateRange(
        _currentUser!.memberId,
        startOfDay,
        endOfDay,
      );

      if (mounted) {
        setState(() {
          _todayExercises = exercises;
          _isLoadingExercises = false;
        });
      }
    } catch (e) {
      print('운동 데이터 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isLoadingExercises = false;
        });
      }
    }
  }

  /// 내 친구 그룹 목록 로드
  Future<void> _loadMyGroups() async {
    if (_currentUser == null) {
      await _loadUserInfo();
    }

    if (_currentUser == null) {
      return;
    }

    setState(() {
      _isLoadingGroups = true;
    });

    try {
      final groups = await _friendGroupService.getMyGroups(
        _currentUser!.memberId,
      );

      if (mounted) {
        setState(() {
          _myGroups = groups;
          _isLoadingGroups = false;
          if (_myGroups.isEmpty) {
            _selectedGroup = null;
            _selectedGroupMembers = [];
          } else if (_selectedGroup == null ||
              !_myGroups.any((g) => g.groupId == _selectedGroup!.groupId)) {
            _selectedGroup = _myGroups.first;
          }
        });
        if (_selectedGroup != null) {
          await _loadGroupMembers(_selectedGroup!.groupId);
        }
      }
    } catch (e) {
      print('그룹 목록 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isLoadingGroups = false;
        });
      }
    }
  }

  Future<void> _selectGroup(FriendGroup group) async {
    if (_selectedGroup?.groupId == group.groupId) {
      setState(() {
        _selectedGroup = null;
        _selectedGroupMembers = [];
        _groupMembersError = null;
      });
      return;
    }

    setState(() {
      _selectedGroup = group;
      _groupMembersError = null;
    });

    await _loadGroupMembers(group.groupId);
  }

  Future<void> _loadGroupMembers(int groupId) async {
    if (_groupMembersCache.containsKey(groupId)) {
      final currentUserId = _currentUser?.memberId;
      final cached = _groupMembersCache[groupId] ?? [];
      final filtered = currentUserId == null
          ? cached
          : cached.where((m) => m.memberId != currentUserId).toList();
      setState(() {
        _selectedGroupMembers = filtered;
        _isLoadingGroupMembers = false;
        _groupMembersError = null;
      });
      return;
    }

    setState(() {
      _isLoadingGroupMembers = true;
      _groupMembersError = null;
    });

    try {
      final members = await _friendGroupService.getGroupMembers(groupId);
      final currentUserId = _currentUser?.memberId;
      final filtered = currentUserId == null
          ? members
          : members.where((m) => m.memberId != currentUserId).toList();
      if (mounted) {
        setState(() {
          _selectedGroupMembers = filtered;
          _groupMembersCache[groupId] = filtered;
          _isLoadingGroupMembers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingGroupMembers = false;
          _groupMembersError = '멤버 목록을 불러오지 못했습니다';
        });
      }
    }
  }

  String? _resolveProfileImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return '${ApiConstants.baseUrl}$path';
  }

  Widget _buildMemberAvatar({
    required String nickname,
    required String? profileImage,
    double radius = 22,
  }) {
    final url = _resolveProfileImageUrl(profileImage);
    if (url == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF1DB954).withOpacity(0.1),
        child: Text(
          nickname.isNotEmpty ? nickname[0] : '?',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1DB954),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF1DB954).withOpacity(0.1),
      child: ClipOval(
        child: Image.network(
          url,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Text(
                nickname.isNotEmpty ? nickname[0] : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1DB954),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _removeGroupMember(int groupId, int memberId) async {
    final success = await _friendGroupService.removeGroupMember(
      groupId,
      memberId,
    );
    if (!mounted) return;
    if (!success) {
      await _loadGroupMembers(groupId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('멤버 삭제에 실패했습니다'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _selectedGroupMembers = _selectedGroupMembers
          .where((m) => m.memberId != memberId)
          .toList();
      _groupMembersCache[groupId] = _selectedGroupMembers;
      _myGroups = _myGroups.map((group) {
        if (group.groupId == groupId) {
          return FriendGroup(
            groupId: group.groupId,
            groupName: group.groupName,
            creatorMemberId: group.creatorMemberId,
            memberCount: (group.memberCount - 1).clamp(0, 99999),
            createdAt: group.createdAt,
          );
        }
        return group;
      }).toList();
    });
  }

  void _showMemberDetailDialog(GroupMemberInfo member) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildMemberAvatar(
                      nickname: member.nickname,
                      profileImage: member.profileImage,
                      radius: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.nickname,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '영양 점수 ${member.nutritionScore}점',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: Colors.grey[600],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '목표 칼로리',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${member.calorieGoal} kcal',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '획득 배지',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${member.badgeCount}개',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '획득한 배지',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<MemberBadge>>(
                  future: _badgeService.getMemberBadges(member.memberId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final badges = snapshot.data ?? [];
                    if (badges.isEmpty) {
                      return Text(
                        '획득한 배지가 없습니다',
                        style: TextStyle(color: Colors.grey[600]),
                      );
                    }

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: badges.map((badge) {
                        return Chip(
                          label: Text(
                            badge.badgeName,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: const Color(
                            0xFF1DB954,
                          ).withOpacity(0.08),
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: const Color(0xFF1DB954).withOpacity(0.3),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 친구 목록 로드
  Future<void> _loadFriends() async {
    if (_currentUser == null) {
      await _loadUserInfo();
    }

    if (_currentUser == null) {
      return;
    }

    try {
      final friends = await _authService.getFriends(_currentUser!.memberId);

      if (mounted) {
        setState(() {
          _friends = friends;
        });
      }
    } catch (e) {
      print('친구 목록 로드 오류: $e');
    }
  }

  /// 그룹 생성 다이얼로그 표시
  Future<void> _showCreateGroupDialog() async {
    // 친구 목록이 비어있으면 먼저 로드
    if (_friends.isEmpty) {
      await _loadFriends();
    }

    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CreateGroupDialog(
        friends: _friends,
        existingGroups: _myGroups,
        currentUserId: _currentUser?.memberId,
        onGroupsChanged: _loadMyGroups,
      ),
    );

    if (result != null && _currentUser != null) {
      final groupName = result['groupName'] as String;
      final selectedFriendIds = result['selectedFriendIds'] as List<int>;

      // 그룹 생성
      final newGroup = await _friendGroupService.createGroup(
        groupName,
        _currentUser!.memberId,
      );

      if (newGroup != null) {
        // 선택한 친구들을 그룹에 추가
        for (final friendId in selectedFriendIds) {
          await _friendGroupService.addGroupMember(newGroup.groupId, friendId);
        }

        // 그룹 목록 새로고침
        await _loadMyGroups();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$groupName 그룹이 생성되었습니다'),
              backgroundColor: const Color(0xFF1DB954),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('그룹 생성에 실패했습니다'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  /// 운동 삭제 다이얼로그 표시
  Future<void> _showDeleteExerciseDialog(ExerciseLog exercise) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('운동 기록 삭제'),
        content: Text('\'${exercise.exerciseName}\' 운동 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (result == true && exercise.exerciseLogId != null) {
      await _deleteExercise(exercise.exerciseLogId!);
    }
  }

  /// 운동 삭제 실행
  Future<void> _deleteExercise(int exerciseLogId) async {
    if (_currentUser == null) return;

    try {
      final success = await _exerciseService.deleteExercise(
        exerciseLogId,
        _currentUser!.memberId,
      );

      if (success) {
        await _loadTodayExercises();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('운동 기록이 삭제되었습니다'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('운동 기록 삭제에 실패했습니다'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('운동 삭제 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('운동 기록 삭제 중 오류가 발생했습니다'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _iotTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // 스크롤 리스너 - 현재 보이는 섹션 추적
  void _onScroll() {
    final dietPosition = _getWidgetPosition(_dietKey);
    final exercisePosition = _getWidgetPosition(_exerciseKey);
    final friendGroupPosition = _getWidgetPosition(_friendGroupKey);

    // 각 섹션의 상단 위치가 화면 상단에서 250px 이내에 있는지 확인
    if (friendGroupPosition != null &&
        friendGroupPosition <= 250 &&
        friendGroupPosition >= -100) {
      if (_currentTab != 2) setState(() => _currentTab = 2);
    } else if (exercisePosition != null &&
        exercisePosition <= 250 &&
        exercisePosition >= -100) {
      if (_currentTab != 1) setState(() => _currentTab = 1);
    } else if (dietPosition != null && dietPosition <= 250) {
      if (_currentTab != 0) setState(() => _currentTab = 0);
    }
  }

  // 위젯의 화면 내 위치 가져오기
  double? _getWidgetPosition(GlobalKey key) {
    final RenderBox? renderBox =
        key.currentContext?.findRenderObject() as RenderBox?;
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
        targetKey = _friendGroupKey;
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

  // 식단 칼로리 계산 (특정 식사 유형) - 최신 식단만 사용
  int _calculateMealCalories(String mealType) {
    final mealLogs = _todayMeals
        .where((meal) => meal.mealType == mealType)
        .toList();
    if (mealLogs.isEmpty) return 0;

    // 가장 최근 식단만 선택
    final latestMeal = mealLogs.reduce(
      (a, b) => a.createdAt!.isAfter(b.createdAt!) ? a : b,
    );
    return latestMeal.totalCalories.toInt();
  }

  // 총 칼로리 계산 - 각 meal_type별 최신 식단만 합산
  int get _totalCalories {
    final mealTypes = ['BREAKFAST', 'LUNCH', 'DINNER', 'SNACK'];
    return mealTypes.fold<int>(
      0,
      (sum, type) => sum + _calculateMealCalories(type),
    );
  }

  // 운동 소모 칼로리 계산
  int get _totalExerciseCalories {
    return _todayExercises.fold<int>(
      0,
      (sum, ex) => sum + (ex.caloriesBurned?.toInt() ?? 0),
    );
  }

  // 순 칼로리 (섭취 - 소모)
  int get _netCalories => _totalCalories - _totalExerciseCalories;

  // 목표 칼로리 (사용자 설정 값 또는 기본값 2000)
  int get _targetCalories => _currentUser?.calorieGoal ?? 2000;

  // 날짜 변경 함수
  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    // TODO: 선택된 날짜의 데이터 로드
    _loadTodayMeals();
    _loadTodayExercises();
  }

  // 탄수화물 총량 계산 (g)
  double get _totalCarbs {
    return _todayMeals.fold<double>(
      0,
      (sum, meal) => sum + meal.totalCarbohydrates,
    );
  }

  // 단백질 총량 계산 (g)
  double get _totalProtein {
    return _todayMeals.fold<double>(0, (sum, meal) => sum + meal.totalProtein);
  }

  // 지방 총량 계산 (g)
  double get _totalFat {
    return _todayMeals.fold<double>(0, (sum, meal) => sum + meal.totalFat);
  }

  // 당류 총량 계산 (g)
  double get _totalSugar {
    return _todayMeals.fold<double>(0, (sum, meal) => sum + meal.totalSugar);
  }

  // 나트륨 총량 계산 (mg)
  double get _totalSodium {
    return _todayMeals.fold<double>(0, (sum, meal) => sum + meal.totalSodium);
  }

  double _calculateNutritionScore() {
    final carbsG = _totalCarbs;
    final proteinG = _totalProtein;
    final fatG = _totalFat;
    final sugarG = _totalSugar;
    final sodiumMg = _totalSodium;

    final macroCalories = carbsG * 4 + proteinG * 4 + fatG * 9;
    if (macroCalories <= 0) {
      return 0;
    }

    final carbRatio = (carbsG * 4) / macroCalories;
    final proteinRatio = (proteinG * 4) / macroCalories;
    final fatRatio = (fatG * 9) / macroCalories;

    double score = 100;
    score -=
        ((carbRatio - 0.5).abs() +
            (proteinRatio - 0.3).abs() +
            (fatRatio - 0.2).abs()) *
        100;

    if (sugarG > 50) {
      score -= ((sugarG - 50) / 5).clamp(0, 20);
    }
    if (sodiumMg > 2000) {
      score -= ((sodiumMg - 2000) / 100).clamp(0, 20);
    }

    return score.clamp(0, 100);
  }

  String _nutritionCheerText(double score) {
    if (score >= 80) {
      return '좋은 흐름이에요! 이대로만 유지해봐요.';
    }
    if (score >= 60) {
      return '잘하고 있어요. 균형을 조금만 더 맞춰볼까요?';
    }
    if (score >= 40) {
      return '조금만 더 개선하면 점수가 올라갈 거예요.';
    }
    return '오늘은 가볍게 시작해도 충분해요.';
  }

  void _showNutritionScoreHelp() {
    HapticFeedback.lightImpact();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('영양 점수 안내'),
        content: const Text('일일 기준으로 영양 점수는 탄/단/지 비율과 당류·나트륨 섭취량을 기준으로 계산돼요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _maybeShowReportPopup() async {
    if (_currentUser == null) return;

    final now = DateTime.now();
    if (now.weekday != DateTime.friday) return;

    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final lastFriday = lastDayOfMonth.subtract(
      Duration(days: (lastDayOfMonth.weekday - DateTime.friday + 7) % 7),
    );
    final isMonthly =
        now.year == lastFriday.year &&
        now.month == lastFriday.month &&
        now.day == lastFriday.day;

    final prefs = await SharedPreferences.getInstance();
    final key = isMonthly
        ? 'monthly_report_${now.year}-${now.month}-${now.day}'
        : 'weekly_report_${now.year}-${now.month}-${now.day}';

    if (prefs.getBool(key) == true) return;
    await prefs.setBool(key, true);

    if (!mounted) return;
    final title = isMonthly ? '월간 리포트를 확인해봐요!' : '주간 리포트를 확인해봐요!';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(
          isMonthly
              ? '최근 한 달간 식단/운동 요약을 확인할 수 있어요.'
              : '최근 7일간 식단/운동 요약을 확인할 수 있어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openReportInAICoach(isMonthly: isMonthly);
            },
            child: const Text('확인하기'),
          ),
        ],
      ),
    );
  }

  Future<void> _openReportInAICoach({required bool isMonthly}) async {
    if (_currentUser == null) return;

    final days = isMonthly ? 30 : 7;
    final stats = await _mealService.getMealStats(
      _currentUser!.memberId,
      days: days,
    );

    int breakfastDays = 0;
    int lowProteinDinnerDays = 0;
    double totalCalories = 0;

    if (stats != null) {
      final breakfastDates = <String>{};
      for (final item in stats) {
        final mealType = item['meal_type']?.toString() ?? '';
        final mealDate = item['meal_date']?.toString() ?? '';
        final totalProtein = (item['total_protein'] ?? 0).toDouble();
        final calories = (item['total_calories'] ?? 0).toDouble();

        totalCalories += calories;

        if (mealType == 'BREAKFAST' && mealDate.isNotEmpty) {
          breakfastDates.add(mealDate);
        }
        if (mealType == 'DINNER' && totalProtein < 20) {
          lowProteinDinnerDays += 1;
        }
      }
      breakfastDays = breakfastDates.length;
    }

    final periodLabel = isMonthly ? '최근 한 달간' : '최근 7일간';
    final prompt = StringBuffer()
      ..writeln('$periodLabel의 상태 분석 보고서를 작성해줘.')
      ..writeln('요약:')
      ..writeln('- 아침 기록 일수: ${breakfastDays}일')
      ..writeln('- 저녁 단백질이 낮은 날: ${lowProteinDinnerDays}일')
      ..writeln('- 총 섭취 칼로리 합계: ${totalCalories.toStringAsFixed(0)} kcal');

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AICoachScreen(initialPrompt: prompt.toString()),
      ),
    );
  }

  // 식사 타입별 탄수화물 계산 (g)
  double _getMealCarbs(String mealType) {
    return _todayMeals
        .where((meal) => meal.mealType == mealType)
        .fold<double>(0, (sum, meal) => sum + meal.totalCarbohydrates);
  }

  // 식사 타입별 단백질 계산 (g)
  double _getMealProtein(String mealType) {
    return _todayMeals
        .where((meal) => meal.mealType == mealType)
        .fold<double>(0, (sum, meal) => sum + meal.totalProtein);
  }

  // 식사 타입별 지방 계산 (g)
  double _getMealFat(String mealType) {
    return _todayMeals
        .where((meal) => meal.mealType == mealType)
        .fold<double>(0, (sum, meal) => sum + meal.totalFat);
  }

  // 식사 타입별 당류 계산 (g)
  double _getMealSugar(String mealType) {
    return _todayMeals
        .where((meal) => meal.mealType == mealType)
        .fold<double>(
          0,
          (sum, meal) =>
              sum +
              meal.items.fold<double>(0, (s, item) => s + (item.sugarG ?? 0)),
        );
  }

  // 식사 타입별 나트륨 계삸 (mg)
  double _getMealSodium(String mealType) {
    return _todayMeals
        .where((meal) => meal.mealType == mealType)
        .fold<double>(
          0,
          (sum, meal) =>
              sum +
              meal.items.fold<double>(0, (s, item) => s + (item.sodiumMg ?? 0)),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBackground,
      body: Stack(
        children: [
          Column(
            children: [
              // 상단 헤더 (칼로리 트래커) - 고정
              _buildHeader(),
              // 탭 바 - 고정
              _buildFixedTabBar(),
              // 스크롤 가능한 콘텐츠
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _loadTodayMeals();
                    await _loadTodayExercises();
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // 식단 섹션
                        _buildSection('식단', _buildDietContent(), _dietKey),
                        // 운동 섹션
                        _buildSection(
                          '운동',
                          _buildExerciseContent(),
                          _exerciseKey,
                        ),
                        // 친구 그룹 섹션
                        _buildSection(
                          '친구 그룹',
                          _buildFriendGroupContent(),
                          _friendGroupKey,
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isIotProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        '스마트 글래스에서 정보를 받아오고 있습니다.',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 상단 헤더 빌드 (날짜 선택기)
  Widget _buildHeader() {
    final today = DateTime.now();

    String formatDate(DateTime date) {
      return '${date.month}/${date.day}';
    }

    String getWeekday(DateTime date) {
      const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
      return weekdays[date.weekday - 1];
    }

    String getDayLabel(DateTime date) {
      final now = DateTime.now();
      final nowDate = DateTime(now.year, now.month, now.day);
      final compareDate = DateTime(date.year, date.month, date.day);
      final difference = compareDate.difference(nowDate).inDays;

      if (difference == 0) {
        return '오늘';
      } else if (difference == -1) {
        return '어제';
      } else if (difference == 1) {
        return '내일';
      }
      return ''; // 빈 문자열 반환
    }

    // 선택된 날짜가 어제/오늘/내일 중 무엇인지 판단
    final now = DateTime.now();
    final nowDate = DateTime(now.year, now.month, now.day);
    final selectedDateOnly = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final difference = selectedDateOnly.difference(nowDate).inDays;

    return Container(
      decoration: const BoxDecoration(color: AppColors.primary),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 상단: TAB TO ME + 달력 아이콘
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TAB TO ME',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        _isRaspberryConnected
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_off_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      // debug text to show connection status
                      Text(
                        _isRaspberryConnected ? '연결' : '끊김',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () async {
                          // 캘린더 화면으로 이동
                          final selectedDate = await Navigator.push<DateTime>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CalendarScreen(),
                            ),
                          );

                          // 선택된 날짜가 있으면 해당 날짜로 변경
                          if (selectedDate != null) {
                            setState(() {
                              _selectedDate = selectedDate;
                            });
                            // 선택된 날짜의 데이터 로드
                            _loadTodayMeals();
                            _loadTodayExercises();
                          }
                        },
                        icon: const Icon(Icons.calendar_today_outlined),
                        iconSize: 22,
                        color: Colors.white,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 중단: 날짜 선택 버튼 + 하단 날짜 표시
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // 상단: 날짜 선택 버튼들
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        // 이전 날짜 버튼
                        IconButton(
                          onPressed: () => _changeDate(-1),
                          icon: const Icon(Icons.chevron_left),
                          color: Colors.white,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),

                        // 날짜 선택 버튼들 (균등 배치)
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 왼쪽 버튼 (전날) - 고정 너비
                              SizedBox(
                                width: 70,
                                child: GestureDetector(
                                  onTap: () => _changeDate(-1),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: null, // 강조 표시 없음
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      getDayLabel(
                                            _selectedDate.subtract(
                                              const Duration(days: 1),
                                            ),
                                          ).isNotEmpty
                                          ? getDayLabel(
                                              _selectedDate.subtract(
                                                const Duration(days: 1),
                                              ),
                                            )
                                          : getWeekday(
                                              _selectedDate.subtract(
                                                const Duration(days: 1),
                                              ),
                                            ),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              // 가운데 버튼 (현재 선택된 날짜) - 항상 강조, 고정 너비
                              SizedBox(
                                width: 70,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedDate = DateTime.now();
                                    });
                                    _loadTodayMeals();
                                    _loadTodayExercises();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white, // 항상 강조
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      getDayLabel(_selectedDate).isNotEmpty
                                          ? getDayLabel(_selectedDate)
                                          : getWeekday(_selectedDate),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1DB954),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              // 오른쪽 버튼 (다음날) - 고정 너비
                              SizedBox(
                                width: 70,
                                child: GestureDetector(
                                  onTap: () => _changeDate(1),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: null, // 강조 표시 없음
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      getDayLabel(
                                            _selectedDate.add(
                                              const Duration(days: 1),
                                            ),
                                          ).isNotEmpty
                                          ? getDayLabel(
                                              _selectedDate.add(
                                                const Duration(days: 1),
                                              ),
                                            )
                                          : getWeekday(
                                              _selectedDate.add(
                                                const Duration(days: 1),
                                              ),
                                            ),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 다음 날짜 버튼
                        IconButton(
                          onPressed: () => _changeDate(1),
                          icon: const Icon(Icons.chevron_right),
                          color: Colors.white,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  // 하단: 날짜 표시
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        // 좌측 화살표 공간 (투명)
                        const SizedBox(width: 40),

                        // 날짜 영역
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // 어제 날짜
                              Text(
                                '${formatDate(_selectedDate.subtract(const Duration(days: 1)))} (${getWeekday(_selectedDate.subtract(const Duration(days: 1)))})',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.7),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),

                              // 오늘 날짜
                              Text(
                                '${formatDate(_selectedDate)} (${getWeekday(_selectedDate)})',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              // 내일 날짜
                              Text(
                                '${formatDate(_selectedDate.add(const Duration(days: 1)))} (${getWeekday(_selectedDate.add(const Duration(days: 1)))})',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.7),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 우측 화살표 공간 (투명)
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 하단 여백
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // 고정 탭 바 빌드
  Widget _buildFixedTabBar() {
    return Container(
      // decoration: BoxDecoration(
      //   color: Colors.white,
      //   border: Border(
      //     bottom: BorderSide(
      //       color: Colors.grey[200]!,
      //       width: 1,
      //     ),
      //   ),
      // ),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabButton('식단', Icons.restaurant_menu, 0),
          _buildTabButton('운동', Icons.fitness_center, 1),
          _buildTabButton('그룹', Icons.group, 2),
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
                color: isActive ? AppColors.primary : Colors.transparent,
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
                color: isActive ? AppColors.primary : Colors.grey[400],
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
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
      // margin: const EdgeInsets.only(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title == '식단')
            // 식단 헤더 (칼로리바 포함)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 영양 점수
                  Builder(
                    builder: (context) {
                      final score = _calculateNutritionScore();
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '영양 점수',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: _showNutritionScoreHelp,
                                  borderRadius: BorderRadius.circular(10),
                                  child: const Icon(
                                    Icons.help_outline_rounded,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${score.toStringAsFixed(0)}점',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1DB954),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _nutritionCheerText(score),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 칼로리바 + 탄단지
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 목표 칼로리
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '목표 칼로리',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$_netCalories / $_targetCalories kcal',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // 칼로리 진행 바
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 270,
                                child: LinearProgressIndicator(
                                  value: (_netCalories / _targetCalories).clamp(
                                    0.0,
                                    1.0,
                                  ),
                                  minHeight: 6,
                                  backgroundColor: Colors.grey[200],
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF1DB954),
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // 탄단지 표시
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildNutrientInfoCompact(
                                  '탄',
                                  _totalCarbs,
                                  Colors.orange,
                                ),
                                const SizedBox(width: 12),
                                _buildNutrientInfoCompact(
                                  '단',
                                  _totalProtein,
                                  Colors.red,
                                ),
                                const SizedBox(width: 12),
                                _buildNutrientInfoCompact(
                                  '지',
                                  _totalFat,
                                  Colors.blue,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // 우측: 상세 버튼
                      InkWell(
                        onTap: () async {
                          if (_currentUser == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('로그인이 필요합니다')),
                            );
                            return;
                          }

                          await showDialog(
                            context: context,
                            builder: (context) => CalorieDetailPopup(
                              intakeCalories: _totalCalories,
                              burnedCalories: _totalExerciseCalories,
                              targetCalories: _targetCalories,
                              currentUser: _currentUser!,
                              onCalorieGoalUpdated: () {
                                _loadUserInfo();
                              },
                              breakfastCalories: _calculateMealCalories(
                                'BREAKFAST',
                              ),
                              lunchCalories: _calculateMealCalories('LUNCH'),
                              dinnerCalories: _calculateMealCalories('DINNER'),
                              snackCalories: _calculateMealCalories('SNACK'),
                              breakfastCarbs: _getMealCarbs('BREAKFAST'),
                              breakfastProtein: _getMealProtein('BREAKFAST'),
                              breakfastFat: _getMealFat('BREAKFAST'),
                              lunchCarbs: _getMealCarbs('LUNCH'),
                              lunchProtein: _getMealProtein('LUNCH'),
                              lunchFat: _getMealFat('LUNCH'),
                              dinnerCarbs: _getMealCarbs('DINNER'),
                              dinnerProtein: _getMealProtein('DINNER'),
                              dinnerFat: _getMealFat('DINNER'),
                              snackCarbs: _getMealCarbs('SNACK'),
                              snackProtein: _getMealProtein('SNACK'),
                              snackFat: _getMealFat('SNACK'),
                              totalCarbs: _totalCarbs,
                              totalProtein: _totalProtein,
                              totalFat: _totalFat,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '상세',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: Colors.grey[700],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            // 운동/친구 그룹 헤더
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                      // 운동과 친구 그룹 모두 + 추가 버튼
                      title == '운동'
                          ? ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.pushNamed(
                                  context,
                                  '/exercise/add',
                                );
                                if (result != null) {
                                  await _loadTodayExercises();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('운동이 추가되었습니다'),
                                        backgroundColor: Color(0xFF1DB954),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('추가'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1DB954),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            )
                          : TextButton.icon(
                              onPressed: () => _showCreateGroupDialog(),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('추가'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF1DB954),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                    ],
                  ),

                  const SizedBox(height: 2),
                ],
              ),
            ),
          content,
        ],
      ),
    );
  }

  // 영양소 정보 위젯
  Widget _buildNutrientInfo(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(1)}g',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // 영양소 정보 위젯 (컴팩트 버전)
  Widget _buildNutrientInfoCompact(String label, double value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          '${value.toStringAsFixed(1)}g',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
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
          _buildMealCard('breakfast', '아침', 'icons_ui/breakfast.svg'),
          _buildMealCard('lunch', '점심', 'icons_ui/lunch.svg'),
          _buildMealCard('dinner', '저녁', 'icons_ui/dinner.svg'),
          _buildMealCard('snack', '간식', 'icons_ui/snack.svg'),
        ],
      ),
    );
  }

  // 식사 카드 빌드 (DB 연동 버전)
  Widget _buildMealCard(String type, String title, String iconPath) {
    // 해당 식사 유형의 식단 필터링 (소문자를 대문자로 변환)
    final mealType = type.toUpperCase();
    final mealLogs = _todayMeals
        .where((meal) => meal.mealType == mealType)
        .toList();

    // 가장 최근 식단만 선택 (여러 개 있을 경우)
    final latestMeal = mealLogs.isNotEmpty
        ? mealLogs.reduce((a, b) => a.createdAt!.isAfter(b.createdAt!) ? a : b)
        : null;

    final totalCalories = latestMeal?.totalCalories.toInt() ?? 0;
    final hasMeal = latestMeal != null;

    return GestureDetector(
      // 길게 누르기로 삭제 메뉴 표시
      onLongPress: hasMeal
          ? () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('$title 식단 삭제'),
                  content: const Text('이 식단을 삭제하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('삭제'),
                    ),
                  ],
                ),
              );

              if (result == true && latestMeal.mealLogId != null) {
                try {
                  // 식단 삭제 API 호출
                  final user = await _authService.getCurrentUser();
                  if (user != null && user.memberId != null) {
                    await _mealService.deleteMeal(
                      latestMeal.mealLogId!,
                      user.memberId!,
                    );
                    await _loadTodayMeals();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$title 식단이 삭제되었습니다')),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('식단 삭제 실패: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            }
          : null,
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SvgPicture.asset(
                    iconPath,
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF1DB954),
                      BlendMode.srcIn,
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
                  children: [
                    // 로딩 중일 때
                    if (_isLoadingMeals)
                      const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      // 상단: 식단 추가 버튼 또는 추가 완료 표시
                      Expanded(
                        child: InkWell(
                          onTap: !hasMeal && _fastingStatus[type] != true
                              ? () async {
                                  final result = await Navigator.pushNamed(
                                    context,
                                    '/meal/camera',
                                    arguments: {
                                      'mealType':
                                          title, // 한글 식사 유형 전달 (아침/점심/저녁/간식)
                                      'selectedDate': _selectedDate,
                                    }, // 선택한 식사 유형과 날짜 전달
                                  );

                                  // 직접 입력 완료 시 새로고침
                                  if (result == true) {
                                    await _loadTodayMeals();
                                    return;
                                  }

                                  // AI 분석 결과 데이터를 받아서 DB에 저장
                                  if (result != null &&
                                      result is Map<String, dynamic>) {
                                    print(
                                      '홈 화면에서 받은 AI 분석 결과: $result',
                                    ); // 디버깅용

                                    try {
                                      // MealType enum 변환
                                      String mealTypeEnum;
                                      switch (title) {
                                        case '아침':
                                          mealTypeEnum = 'BREAKFAST';
                                          break;
                                        case '점심':
                                          mealTypeEnum = 'LUNCH';
                                          break;
                                        case '저녁':
                                          mealTypeEnum = 'DINNER';
                                          break;
                                        case '간식':
                                          mealTypeEnum = 'SNACK';
                                          break;
                                        default:
                                          mealTypeEnum = 'BREAKFAST';
                                      }

                                      // MealItem 생성
                                      final mealItem = MealItem(
                                        mealLogId: 0,
                                        foodName: result['name'] as String,
                                        caloriesKcal:
                                            (result['calories'] as int)
                                                .toDouble(),
                                        carbohydratesG:
                                            result['carbs'] as double,
                                        proteinG: result['protein'] as double,
                                        fatG: result['fat'] as double,
                                        sugarG: result['sugar'] as double,
                                        sodiumMg: result['sodium'] as double,
                                      );

                                      // MealLog 생성
                                      final mealLog = MealLog(
                                        memberId: _currentUser!.memberId,
                                        mealDate: _selectedDate,
                                        mealType: mealTypeEnum,
                                        items: [mealItem],
                                      );

                                      // DB에 저장
                                      print(
                                        'DB 저장 시도: ${mealLog.toJson()}',
                                      ); // 디버깅용
                                      final savedMeal = await _mealService
                                          .createMeal(mealLog);
                                      if (savedMeal == null) {
                                        throw Exception('식단 저장에 실패했습니다');
                                      }
                                      print('DB 저장 완료: $savedMeal'); // 디버깅용

                                      // 단식 상태를 OFF로 변경하고 데이터 새로고침
                                      setState(() {
                                        _fastingStatus[type] = false;
                                      });
                                      print('DB에서 데이터 새로고침 시작'); // 디버깅용
                                      await _loadTodayMeals();
                                      print(
                                        'DB에서 데이터 새로고침 완료: ${_todayMeals.length}개 식단',
                                      ); // 디버깅용

                                      // 사용자에게 피드백
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('$title 식단이 추가되었습니다'),
                                            backgroundColor: const Color(
                                              0xFF1DB954,
                                            ),
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      print('식단 저장 중 오류 발생: $e'); // 디버깅용
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('식단 저장 실패: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                }
                              : hasMeal
                              ? () async {
                                  // 식단 수정 팝업 표시
                                  await showDialog(
                                    context: context,
                                    builder: (context) => MealEditPopup(
                                      mealLog: latestMeal,
                                      onUpdated: () async {
                                        await _loadTodayMeals();
                                      },
                                    ),
                                  );
                                  // 팝업 닫힌 후 새로고침
                                  await _loadTodayMeals();
                                }
                              : null,
                          child: Container(
                            child: !hasMeal
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '식단 추가',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: _fastingStatus[type] == true
                                              ? Colors.grey[400]
                                              : Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.add_circle_outline,
                                        color: _fastingStatus[type] == true
                                            ? Colors.grey[400]
                                            : const Color(0xFF1DB954),
                                        size: 20,
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        '추가 완료',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF1DB954),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF1DB954),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 경계선
                      Divider(color: Colors.grey[300], thickness: 1, height: 1),

                      const SizedBox(height: 8),

                      // 하단: 단식 체크 버튼 또는 칼로리 표시
                      if (!hasMeal)
                        // 단식했어요 체크 버튼
                        InkWell(
                          onTap: () {
                            setState(() {
                              _fastingStatus[type] =
                                  !(_fastingStatus[type] ?? false);
                            });
                            if (_fastingStatus[type] == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$title 단식이 기록되었습니다'),
                                  backgroundColor: const Color(0xFF1DB954),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _fastingStatus[type] == true
                                  ? const Color(0xFF1DB954)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  '단식했어요',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _fastingStatus[type] == true
                                        ? Colors.white
                                        : Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                                Icon(
                                  _fastingStatus[type] == true
                                      ? Icons.check_circle
                                      : Icons.check_outlined,
                                  size: 18,
                                  color: _fastingStatus[type] == true
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        // 칼로리 표시 (식단이 있을 때)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            '$totalCalories kcal',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1DB954),
                            ),
                          ),
                        ),
                    ],
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 로딩 중
          if (_isLoadingExercises)
            const Center(child: CircularProgressIndicator())
          // 운동 기록이 없을 때
          else if (_todayExercises.isEmpty)
            GestureDetector(
              onTap: () async {
                // 운동 추가 화면으로 이동
                final result = await Navigator.pushNamed(
                  context,
                  '/exercise/add',
                );
                if (result != null) {
                  await _loadTodayExercises();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('운동이 추가되었습니다'),
                        backgroundColor: Color(0xFF1DB954),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 80),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.fitness_center, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        '아직 기록된 운동이 없습니다',
                        style: TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '운동 기록을 추가해보세요!',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            )
          // 운동 기록이 있을 때 (DB 데이터)
          else ...[
            // 운동 추가 버튼
            GestureDetector(
              onTap: () async {
                final result = await Navigator.pushNamed(
                  context,
                  '/exercise/add',
                );
                if (result != null) {
                  await _loadTodayExercises();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('운동이 추가되었습니다'),
                        backgroundColor: Color(0xFF1DB954),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF1DB954),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF1DB954),
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '운동 추가하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1DB954),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            ..._todayExercises.asMap().entries.map((entry) {
              final index = entry.key;
              final exercise = entry.value;
              return Dismissible(
                key: Key(
                  'exercise_${exercise.exerciseLogId}_${exercise.createdAt}',
                ),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.delete, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        '삭제',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('운동 기록 삭제'),
                      content: Text('${exercise.exerciseName} 기록을 삭제하시겠습니까?'),
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
                },
                onDismissed: (direction) async {
                  try {
                    final user = await _authService.getCurrentUser();
                    if (user != null &&
                        user.memberId != null &&
                        exercise.exerciseLogId != null) {
                      await _exerciseService.deleteExercise(
                        exercise.exerciseLogId!,
                        user.memberId!,
                      );
                      await _loadTodayExercises();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${exercise.exerciseName} 기록이 삭제되었습니다',
                            ),
                            action: SnackBarAction(
                              label: '취소',
                              onPressed: () {
                                // 실제로는 서버 API 복구 필요
                              },
                            ),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('운동 기록 삭제 실패: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: GestureDetector(
                  onTap: () => _showDeleteExerciseDialog(exercise),
                  child: Container(
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
                            ),
                            // 소모된 칼로리 수치
                            Text(
                              exercise.caloriesFormatted,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFF6B6B),
                              ),
                            ),
                          ],
                        ),
                        if (exercise.memo != null &&
                            exercise.memo!.isNotEmpty) ...[
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
                  ),
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  // 친구 그룹 콘텐츠 빌드
  Widget _buildFriendGroupContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 로딩 중
          if (_isLoadingGroups)
            const Center(child: CircularProgressIndicator())
          // 그룹이 없을 때
          else if (_myGroups.isEmpty)
            GestureDetector(
              onTap: () => _showCreateGroupDialog(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 80),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.group_add, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        '그룹이 없습니다',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '친구들과 함께하는 그룹을 만들어보세요',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _myGroups.length,
                itemBuilder: (context, index) {
                  final group = _myGroups[index];
                  final isSelected = _selectedGroup?.groupId == group.groupId;
                  return Container(
                    margin: EdgeInsets.only(
                      right: index == _myGroups.length - 1 ? 0 : 12,
                    ),
                    child: InkWell(
                      onTap: () => _selectGroup(group),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1DB954).withOpacity(0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1DB954).withOpacity(0.6)
                                : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              group.groupName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF1DB954)
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${group.memberCount}명',
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected
                                    ? const Color(0xFF1DB954)
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            if (_selectedGroup == null)
              const SizedBox.shrink()
            else if (_isLoadingGroupMembers)
              const Center(child: CircularProgressIndicator())
            else if (_groupMembersError != null)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Text(
                      _groupMembersError!,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          _loadGroupMembers(_selectedGroup!.groupId),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              )
            else if (_selectedGroupMembers.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  '그룹 멤버가 없습니다',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _selectedGroupMembers.map((member) {
                  return Dismissible(
                    key: ValueKey(
                      'group_${_selectedGroup!.groupId}_member_${member.memberId}',
                    ),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.delete, color: Colors.red),
                    ),
                    confirmDismiss: (_) async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('멤버 삭제'),
                          content: Text('${member.nickname}님을 그룹에서 삭제하시겠습니까?'),
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
                      return result ?? false;
                    },
                    onDismissed: (_) {
                      _removeGroupMember(
                        _selectedGroup!.groupId,
                        member.memberId,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: InkWell(
                        onTap: () => _showMemberDetailDialog(member),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              _buildMemberAvatar(
                                nickname: member.nickname,
                                profileImage: member.profileImage,
                                radius: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member.nickname,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '영양 점수 ${member.nutritionScore}점',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ],
      ),
    );
  }
}
