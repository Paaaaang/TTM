/// 프로필 화면 (단일 스크롤)
import 'package:flutter/material.dart';

/// 배지 모델
class Badge {
  final int id;
  final String name;
  final String icon;
  final String description;
  final bool earned;
  final String? earnedDate;
  final String howToEarn;

  Badge({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.earned,
    this.earnedDate,
    required this.howToEarn,
  });
}

/// 프로필 화면 위젯
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // 사용자 정보 (더미 데이터)
  final String userName = '스인개';
  final String userEmail = 'smhrd@naver.com';
  final String joinDate = '2025.08.26';
  
  // 통계 데이터
  final int totalCalories = 907; // 총 kcal
  final int exerciseCalories = 102; // 운동 kcal
  final int days = 97; // 일차
  
  // 활동 통계
  final int mealCount = 342; // 식단
  final int workoutCount = 128; // 운동
  final int postCount = 24; // 커뮤니티 글
  final int likeCount = 156; // 좋아요

  
  // 배지 목록
  final List<Badge> badges = [
    Badge(id: 1, name: '첫 걸음', icon: '🚶', description: '첫 기록 작성', earned: true, earnedDate: '2024.01.01', howToEarn: '첫 식단 기록하기'),
    Badge(id: 2, name: '운동 초보', icon: '💪', description: '10회 운동', earned: true, earnedDate: '2024.01.15', howToEarn: '운동 10회 기록'),
    Badge(id: 3, name: '꾸준함', icon: '🔥', description: '7일 연속', earned: true, earnedDate: '2024.02.01', howToEarn: '7일 연속 기록'),
    Badge(id: 4, name: '건강 마스터', icon: '🏆', description: '100일 연속', earned: true, earnedDate: '2024.03.01', howToEarn: '100일 연속 기록'),
    Badge(id: 5, name: '완벽한 하루', icon: '⭐', description: '목표 달성', earned: true, earnedDate: '2024.02.14', howToEarn: '하루 목표 달성'),
    Badge(id: 6, name: '운동왕', icon: '🦾', description: '30회 운동', earned: true, earnedDate: '2024.03.10', howToEarn: '총 30회 운동'),
    Badge(id: 7, name: '아침형', icon: '🌅', description: '아침 운동', earned: true, earnedDate: '2024.03.15', howToEarn: '아침 운동 10회'),
    Badge(id: 8, name: '채식 러버', icon: '🥗', description: '채식 위주', earned: true, earnedDate: '2024.03.20', howToEarn: '7일간 채식 중심 먹기'),
    Badge(id: 9, name: '칼로리왕', icon: '🔥', description: '소모 달성', earned: false, howToEarn: '주간 칼로리 목표'),
    Badge(id: 10, name: '파워맨', icon: '💥', description: '근력 운동', earned: false, howToEarn: '웨이트 20회'),
    Badge(id: 11, name: '러닝', icon: '🏃', description: '달리기', earned: false, howToEarn: '100km 달리기'),
    Badge(id: 12, name: '등산', icon: '⛰️', description: '자연인', earned: false, howToEarn: '등산 30회'),
    Badge(id: 13, name: '별', icon: '✨', description: '수집가', earned: false, howToEarn: '수집 이벤트 참여'),
    Badge(id: 14, name: '리액션', icon: '👍', description: '좋아요', earned: false, howToEarn: '좋아요 100개'),
    Badge(id: 15, name: '파티', icon: '🎉', description: '축하', earned: false, howToEarn: '목표 달성 5회'),
    Badge(id: 16, name: '물병자', icon: '💧', description: '수분 섭취', earned: false, howToEarn: '물 2L 7일'),
    Badge(id: 17, name: '번개남', icon: '⚡', description: '천사', earned: false, howToEarn: '완벽한 주 달성'),
    Badge(id: 18, name: '건강식', icon: '🥑', description: '건강한 식단', earned: false, howToEarn: '채소 식단 10일'),
    Badge(id: 19, name: '노력', icon: '🎯', description: '도달지점', earned: false, howToEarn: '도달지점 목표 달성'),
    Badge(id: 20, name: '다이아', icon: '💎', description: '최고의 업적', earned: false, howToEarn: '모든 목표 달성'),
  ];

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
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 내 배지 섹션
  Widget _buildBadgesSection() {
    final earnedCount = badges.where((b) => b.earned).length;
    final totalCount = badges.length;
    
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
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 배지 그리드 (4x5)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: badges.length,
            itemBuilder: (context, index) {
              final badge = badges[index];
              return _buildBadgeItem(badge);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(Badge badge) {
    return GestureDetector(
      onTap: () => _showBadgeDetail(badge),
      child: Container(
        decoration: BoxDecoration(
          color: badge.earned ? const Color(0xFFFFF8E1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: badge.earned
              ? Border.all(color: const Color(0xFFFFD54F), width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              badge.icon,
              style: TextStyle(
                fontSize: 28,
                color: badge.earned ? null : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: badge.earned ? Colors.black87 : Colors.grey[400],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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

  
  void _showBadgeDetail(Badge badge) {/// 배지 상세 보기
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 닫기 버튼
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // 아이콘 (크게)
              Text(
                badge.icon,
                style: TextStyle(
                  fontSize: 96,
                  color: badge.earned ? null : Colors.grey[400],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 배지명
              Text(
                badge.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // 배지 설명
              Text(
                badge.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 획득 상태
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: badge.earned
                      ? const LinearGradient(
                          colors: [
                            Color(0xFFFFF8E1),
                            Color(0xFFFFECB3),
                          ],
                        )
                      : null,
                  color: badge.earned ? null : Colors.grey[100],
                  border: Border.all(
                    color: badge.earned
                        ? const Color(0xFFFFD54F)
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          badge.earned ? '🎉' : '🔒',
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          badge.earned ? '획득 완료!' : '미획득',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: badge.earned
                                ? const Color(0xFFF57C00)
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    if (badge.earned && badge.earnedDate != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '획득일: ${badge.earnedDate}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 획득 방법
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  border: Border.all(
                    color: const Color(0xFF90CAF9),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      '획득 방법',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      badge.howToEarn,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

