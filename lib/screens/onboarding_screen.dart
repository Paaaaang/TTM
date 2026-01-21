/// 온보딩 화면
/// 스크린샷 디자인을 Flutter로 구현
import 'package:flutter/material.dart';
import 'package:ttm/constants/app_colors.dart';

/// 온보딩(환영) 화면 위젯
/// 사용자 닉네임과 함께 앱 시작 안내 표시
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 그라데이션 배경
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryLight, // 연한 민트
              AppColors.softBackground, // 연한 배경
              AppColors.primaryLight, // 연한 민트
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: [
                const SizedBox(height: 120),

                // 로고
                Image.asset(
                  'assets/icons/logoIcon.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Icon(
                        Icons.energy_savings_leaf,
                        size: 100,
                        color: Colors.white,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // 부제목
                const Text(
                  '나를 위한 스마트한 변화',
                  style: TextStyle(
                    fontFamily: 'BMJUA',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 12),

                // 설명 텍스트
                const Text(
                  '사진 하나로 영양정보를 빠르게 확인하세요!',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(),

                // 로그인 버튼
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: 로그인 화면으로 이동
                      Navigator.pushNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      overlayColor: AppColors.primary,
                    ),
                    child: const Text(
                      '로그인',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 회원가입 버튼
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      overlayColor: AppColors.primary.withOpacity(0.1),
                    ),
                    child: const Text(
                      '회원가입',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
