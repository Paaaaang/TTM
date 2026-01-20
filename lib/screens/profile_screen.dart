/// 프로필 화면 (단일 스크롤)
import 'package:flutter/material.dart';
import 'package:ttm/services/auth_service.dart';
import 'package:ttm/services/badge_service.dart';
import 'package:ttm/services/profile_service.dart';
import 'package:ttm/models/user.dart';
import 'package:ttm/models/badge.dart' as model;
import 'package:ttm/widgets/profile_avatar.dart';

/// 프로필 화면 위젯
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// 인증 서비스
  final AuthService _authService = AuthService();
  final BadgeService _badgeService = BadgeService();
  final ProfileService _profileService = ProfileService();
  
  /// 현재 사용자 정보
  User? _currentUser;
  
  /// 배지 관련 데이터
  List<model.Badge> _allBadges = [];
  List<model.MemberBadge> _memberBadges = [];
  model.BadgeStats? _badgeStats;
  bool _isLoadingBadges = false;
  
  /// 활동 통계 (DB 연동)
  int _mealCount = 0;
  int _workoutCount = 0;
  int _postCount = 0;
  int _likeCount = 0;
  bool _isLoadingStats = false;
  
  // 사용자 정보
  String get userName => _currentUser?.nickname ?? '사용자';
  String get userEmail => _currentUser?.email ?? '';
  String get joinDate {
    if (_currentUser?.createdAt == null) return '정보 없음';
    final created = _currentUser!.createdAt!;
    return '${created.year}.${created.month.toString().padLeft(2, '0')}.${created.day.toString().padLeft(2, '0')}';
  }
  
  // 출석(접속) 일차 - 가입일로부터 경과일 (날짜 기준 계산)
  int get attendanceDays {
    if (_currentUser?.createdAt == null) return 0;
    
    final now = DateTime.now();
    // 현재 날짜의 자정 (시간 제거)
    final today = DateTime(now.year, now.month, now.day);
    
    final created = _currentUser!.createdAt!;
    // 가입 날짜의 자정 (시간 제거)
    final joinDate = DateTime(created.year, created.month, created.day);
    
    final diff = today.difference(joinDate);
    return diff.inDays + 1; // +1은 가입일도 포함
  }
  
  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  /// 당겨서 새로고침
  Future<void> _handleRefresh() async {
    // 서버에서 최신 정보 동기화
    final user = await _authService.refreshCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
      if (_currentUser != null) {
        // 모든 데이터 로드가 완료될 때까지 대기
        await Future.wait([
          _loadBadges(),
          _loadActivityStats(),
        ]);
      }
    }
  }
  
  /// 사용자 정보 로드
  Future<void> _loadUserInfo() async {
    // 1. 먼저 로컬 캐시된 정보로 빠르게 화면 표시
    var user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
      // 기존 배지/통계 로드
      _loadBadges();
      _loadActivityStats();
    }

    // 2. 서버에서 최신 정보 동기화 (프로필 이미지 등 변경사항 반영)
    final updatedUser = await _authService.refreshCurrentUser();
    if (mounted && updatedUser != null) {
      setState(() {
        _currentUser = updatedUser;
      });
      // 필요한 경우 배지/통계도 다시 로드할 수 있으나, 프로필 정보만 필요한 경우 생략 가능
      // 여기서는 확실한 데이터 동기화를 위해 다시 로드하지 않음 (비용 절감)
      // 만약 닉네임 변경 등이 배지에 영향을 준다면 여기서 다시 로드해야 함
    }
  }
  
  /// 활동 통계 로드 (DB 연동)
  Future<void> _loadActivityStats() async {
    final user = _currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingStats = true;
    });

    try {
      final stats = await _profileService.getActivityStats(user.memberId);
      if (!mounted) return;
      setState(() {
        _mealCount = stats.mealCount;
        _workoutCount = stats.workoutCount;
        _postCount = stats.postCount;
        _likeCount = stats.likeCount;
        _isLoadingStats = false;
      });
    } catch (e) {
      print('활동 통계 로드 오류: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingStats = false;
      });
    }
  }
  
  /// 배지 정보 로드
  Future<void> _loadBadges() async {
    if (_currentUser == null) return;
    
    setState(() {
      _isLoadingBadges = true;
    });
    
    try {
      // forceRefresh: true로 강제 새로고침
      final allBadges = await _badgeService.getAllBadges(forceRefresh: true);
      final memberBadges = await _badgeService.getMemberBadges(_currentUser!.memberId, forceRefresh: true);
      final stats = await _badgeService.getBadgeStats(_currentUser!.memberId, forceRefresh: true);
      
      if (mounted) {
        setState(() {
          _allBadges = allBadges;
          _memberBadges = memberBadges;
          _badgeStats = stats;
          _isLoadingBadges = false;
        });
      }
    } catch (e) {
      print('배지 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isLoadingBadges = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('내 정보', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1DB954),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.pushNamed(context, '/settings');
              // 설정 화면에서 복귀 시 사용자 정보 새로고침
              _loadUserInfo();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // 프로필 카드
              _buildProfileCard(),
              
              const SizedBox(height: 8),
              
              // 내 활동 섹션
              _buildActivitySection(),
              
              const SizedBox(height: 8),
              
              // 내 배지 섹션
              _buildBadgesSection(),
              
              const SizedBox(height: 8),
              
              // 하단 메뉴
              _buildBottomMenu(),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// 프로필 카드
  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // 프로필 아이콘과 정보
          Row(
            children: [
              // 프로필 아이콘
              ProfileAvatar(
                size: 64,
                profileImageUrl: _currentUser?.profileImage,
                borderColor: const Color(0xFF1DB954),
              ),
              
              const SizedBox(width: 16),
              
              // 사용자 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '가입일: $joinDate',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 출석 일차
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1DB954).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '출석 일차',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$attendanceDays일',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1DB954),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 내 활동 섹션
  Widget _buildActivitySection() {
    return InkWell(
      onTap: () {
        // 활동 상세 화면으로 이동
        Navigator.pushNamed(context, '/activity');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_activity, color: Color(0xFF1DB954), size: 20),
                const SizedBox(width: 8),
                const Text(
                  '내 활동',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 활동 통계 그리드
            _isLoadingStats 
              ? const Center(child: CircularProgressIndicator())
              : Row(
                  children: [
                    Expanded(child: _buildActivityCard('🍽️', _mealCount.toString(), '식단')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildActivityCard('💪', _workoutCount.toString(), '운동')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildActivityCard('📝', _postCount.toString(), '작성한 글')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildActivityCard('❤️', _likeCount.toString(), '좋아요')),
                  ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(String emoji, String count, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 내 배지 섹션
  Widget _buildBadgesSection() {
    if (_isLoadingBadges) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    
    final earnedCount = _badgeStats?.acquiredBadges ?? 0;
    final totalCount = _badgeStats?.totalBadges ?? 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Color(0xFF1DB954), size: 20),
              const SizedBox(width: 8),
              Text(
                '내 배지 ($earnedCount/$totalCount)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_badgeStats != null)
                Text(
                  '${_badgeStats!.acquisitionRate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1DB954),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 배지 그리드
          if (_allBadges.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('배지 정보를 불러올 수 없습니다'),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _allBadges.length,
              itemBuilder: (context, index) {
                final badge = _allBadges[index];
                final isEarned = _memberBadges.any((mb) => mb.badgeId == badge.badgeId);
                return _buildBadgeItem(badge, isEarned);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(model.Badge badge, bool isEarned) {
    // 아이콘 추출 (DB에 이모지로 저장되어 있다고 가정)
    final icon = badge.iconPath ?? '🏅';
    
    return GestureDetector(
      onTap: () => _showBadgeDetail(badge, isEarned),
      child: Container(
        decoration: BoxDecoration(
          color: isEarned ? const Color(0xFFFFF8E1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: isEarned
              ? Border.all(color: const Color(0xFFFFD54F), width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: TextStyle(
                fontSize: 28,
                color: isEarned ? null : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              badge.badgeName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isEarned ? Colors.black87 : Colors.grey[400],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  /// 배지 상세 정보 표시
  void _showBadgeDetail(model.Badge badge, bool isEarned) {
    final earnedBadge = _memberBadges.firstWhere(
      (mb) => mb.badgeId == badge.badgeId,
      orElse: () => model.MemberBadge(
        memberBadgeId: 0,
        badgeId: badge.badgeId,
        badgeName: badge.badgeName,
        description: badge.description,
        iconPath: badge.iconPath,
        acquiredAt: DateTime.now(),
      ),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(
              badge.iconPath ?? '🏅',
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                badge.badgeName,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              badge.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            // 획득 조건 표시
            if (badge.badgeCondition != null && badge.badgeCondition!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, 
                      color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        badge.badgeCondition!,
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            if (isEarned)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8F4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, 
                      color: Color(0xFF1DB954), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '획득: ${earnedBadge.acquiredTimeAgo}',
                      style: const TextStyle(
                        color: Color(0xFF1DB954),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock, color: Colors.grey, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '아직 획득하지 못한 배지입니다',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  /// 하단 메뉴
  Widget _buildBottomMenu() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.settings, color: Color(0xFF1DB954)),
            title: const Text('설정'),
            trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
            onTap: () async {
              await Navigator.pushNamed(context, '/settings');
              // 설정 화면에서 복귀 시 사용자 정보 새로고침
              _loadUserInfo();
            },
          ),
          Divider(height: 1, color: Colors.grey[200]),
          ListTile(
            leading: const Icon(Icons.help_outline, color: Color(0xFF1DB954)),
            title: const Text('자주 묻는 질문'),
            trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
            onTap: () {
              Navigator.pushNamed(context, '/help');
            },
          ),
        ],
      ),
    );
  }
}

