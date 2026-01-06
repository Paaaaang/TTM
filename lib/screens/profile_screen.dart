/// 프로필 화면 (단일 스크롤)
import 'package:flutter/material.dart';
import 'package:ttm/services/auth_service.dart';
import 'package:ttm/services/badge_service.dart';
import 'package:ttm/models/user.dart';
import 'package:ttm/models/badge.dart' as model;

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
  
  /// 현재 사용자 정보
  User? _currentUser;
  
  /// 배지 관련 데이터
  List<model.Badge> _allBadges = [];
  List<model.MemberBadge> _memberBadges = [];
  model.BadgeStats? _badgeStats;
  bool _isLoadingBadges = false;
  
  // 사용자 정보
  String get userName => _currentUser?.nickname ?? '사용자';
  String get userEmail => _currentUser?.email ?? '';
  String get joinDate => '2025.08.26'; // TODO: 실제 가입일 정보가 있으면 사용
  
  // 통계 데이터
  final int totalCalories = 907; // 총 kcal
  final int exerciseCalories = 102; // 운동 kcal
  final int days = 97; // 일차
  
  // 활동 통계
  final int mealCount = 342; // 식단
  final int workoutCount = 128; // 운동
  final int postCount = 24; // 커뮤니티 글
  final int likeCount = 156; // 좋아요
  
  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadBadges();
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
  
  /// 배지 정보 로드
  Future<void> _loadBadges() async {
    if (_currentUser == null) return;
    
    setState(() {
      _isLoadingBadges = true;
    });
    
    try {
      final allBadges = await _badgeService.getAllBadges();
      final memberBadges = await _badgeService.getMemberBadges(_currentUser!.memberId);
      final stats = await _badgeService.getBadgeStats(_currentUser!.memberId);
      
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
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
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
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(
                    Icons.person,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
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
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 통계
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(totalCalories.toString(), '총 Kcal', Colors.orange),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              _buildStatItem(exerciseCalories.toString(), '운동 Kcal', Colors.blue),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              _buildStatItem(days.toString(), '일차', const Color(0xFF1DB954)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
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
    );
  }

  /// 내 활동 섹션
  Widget _buildActivitySection() {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/activity/detail');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
          Row(
            children: [
              Expanded(child: _buildActivityCard('🍽️', mealCount.toString(), '식단')),
              const SizedBox(width: 12),
              Expanded(child: _buildActivityCard('💪', workoutCount.toString(), '운동')),
              const SizedBox(width: 12),
              Expanded(child: _buildActivityCard('📝', postCount.toString(), '커뮤니티 글')),
              const SizedBox(width: 12),
              Expanded(child: _buildActivityCard('❤️', likeCount.toString(), '좋아요')),
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
            const SizedBox(height: 16),
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
            onTap: () {
              Navigator.pushNamed(context, '/settings');
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

