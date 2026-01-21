import 'package:flutter/material.dart';
import 'package:ttm/screens/survey/survey_screen.dart';
import 'package:ttm/constants/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  final String nickname;
  final int memberId;

  const WelcomeScreen({
    super.key,
    required this.nickname,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Skip button (Top Right)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Skip logic: maybe go to home directly?
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/main', (route) => false);
                  },
                  child: Text(
                    '건너뛰기',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              // Content
              Column(
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 28,
                        color: AppColors.textPrimary,
                      ),
                      children: [
                        TextSpan(
                          text: nickname,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' 님 환영합니다!'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'TAB TO ME 를 시작하기 전에',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '건강한 식습관과 운동을 위한 첫걸음을 시작하세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),

              // Next Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SurveyScreen(memberId: memberId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '다음',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
