/// 도움말 화면
import 'package:flutter/material.dart';
import 'package:ttm/constants/app_colors.dart';

/// 도움말 화면 위젯
class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('도움말'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHelpCard('앱 사용 방법', [
            '1. 식사를 사진으로 촬영하세요',
            '2. AI가 자동으로 영양 정보를 분석합니다',
            '3. 일일 칼로리와 영양소를 확인하세요',
            '4. 운동 기록으로 소모 칼로리를 추적하세요',
          ]),
          const SizedBox(height: 16),
          _buildHelpCard('칼로리 트래킹', [
            '• 목표 칼로리는 프로필에서 설정할 수 있습니다',
            '• 식단과 운동을 기록하여 순 칼로리를 확인하세요',
            '• 통계 화면에서 주간/월간 추이를 볼 수 있습니다',
          ]),
          const SizedBox(height: 16),
          _buildHelpCard('커뮤니티 기능', [
            '• 다른 사용자와 건강 정보를 공유하세요',
            '• 게시글에 좋아요와 댓글을 남길 수 있습니다',
            '• 친구를 추가하여 서로의 진행 상황을 확인하세요',
          ]),
          const SizedBox(height: 16),
          _buildHelpCard('AI 코치', [
            '• AI 코치에게 영양과 운동에 대해 물어보세요',
            '• 개인 맞춤형 조언을 받을 수 있습니다',
            '• 식단 개선 방법을 추천받으세요',
          ]),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.support_agent,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  '추가 도움이 필요하신가요?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'support@ttm.com',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard(String title, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
