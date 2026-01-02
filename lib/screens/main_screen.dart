/// 메인 화면 - 하단 네비게이션 바 포함
/// MainScreen.tsx의 하단 네비게이션을 Flutter로 변환
import 'package:flutter/material.dart';
import 'package:ttm/constants/app_colors.dart';
import 'package:ttm/screens/home_screen.dart';
import 'package:ttm/screens/stats_screen.dart';
import 'package:ttm/screens/ai_coach_screen.dart';
import 'package:ttm/screens/profile_screen.dart';
import 'package:ttm/screens/community_home_screen.dart';

/// 메인 화면 위젯
/// 5개의 하단 탭으로 구성: 홈, 통계, AI 코치(중앙), 커뮤니티, 프로필
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  /// 현재 선택된 탭 인덱스
  int _currentIndex = 0;

  /// 각 탭에 해당하는 화면 목록
  final List<Widget> _screens = [
    const HomeScreen(), // 홈
    const StatsScreen(), // 통계
    const AICoachScreen(), // AI 코치 (중앙 FAB)
    const CommunityHomeScreen(), // 커뮤니티
    const ProfileScreen(), // 프로필
  ];

  /// AI 코치 화면으로 이동
  void _onAICoachPressed() {
    setState(() {
      _currentIndex = 2; // AI 코치는 인덱스 2
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      // 하단 네비게이션 바 with AI Coach FAB
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // 홈 버튼
                    _buildNavItem(
                      icon: Icons.home,
                      label: '홈',
                      index: 0,
                    ),
                    // 통계 버튼
                    _buildNavItem(
                      icon: Icons.bar_chart,
                      label: '통계',
                      index: 1,
                    ),
                    // 중앙 공간 (FAB 자리)
                    const SizedBox(width: 56),
                    // 커뮤니티 버튼
                    _buildNavItem(
                      icon: Icons.people_outline,
                      label: '커뮤니티',
                      index: 3,
                    ),
                    // 프로필 버튼
                    _buildNavItem(
                      icon: Icons.person_outline,
                      label: '프로필',
                      index: 4,
                    ),
                  ],
                ),
              ),
              // 중앙 FAB - AI 코치
              Positioned(
                top: -20,
                child: GestureDetector(
                  onTap: _onAICoachPressed,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF4285F4),
                          Color(0xFF9B72CB),
                          Color(0xFFD96570),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1DB954).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.auto_awesome,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 네비게이션 아이템 빌드
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.secondary : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.secondary : Colors.grey[400],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


