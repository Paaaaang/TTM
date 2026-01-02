import 'package:flutter/material.dart';

/// 내 활동 상세 화면
class ActivityDetailScreen extends StatelessWidget {
  const ActivityDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1DB954),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            '내 활동',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            tabs: [
              Tab(text: '식단'),
              Tab(text: '운동'),
              Tab(text: '커뮤니티'),
              Tab(text: '좋아요'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMealTab(),
            _buildWorkoutTab(),
            _buildCommunityTab(),
            _buildLikesTab(),
          ],
        ),
      ),
    );
  }

  /// 식단 탭
  Widget _buildMealTab() {
    final meals = [
      {'date': '2026.01.02', 'time': '아침', 'calories': 450, 'foods': '계란, 토스트, 우유'},
      {'date': '2026.01.02', 'time': '점심', 'calories': 650, 'foods': '김치찌개, 밥, 반찬'},
      {'date': '2026.01.01', 'time': '저녁', 'calories': 520, 'foods': '연어구이, 샐러드'},
      {'date': '2026.01.01', 'time': '점심', 'calories': 580, 'foods': '치킨샐러드'},
      {'date': '2025.12.31', 'time': '아침', 'calories': 0, 'foods': '단식'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: meals.length,
      itemBuilder: (context, index) {
        final meal = meals[index];
        final isFasting = meal['calories'] == 0;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 아이콘
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isFasting
                      ? Colors.grey[100]
                      : const Color(0xFF1DB954).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isFasting ? Icons.local_cafe_outlined : Icons.restaurant,
                  color: isFasting ? Colors.grey[400] : const Color(0xFF1DB954),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          meal['date'].toString(),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1DB954).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            meal['time'].toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1DB954),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      meal['foods'].toString(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // 칼로리
              Text(
                isFasting ? '단식' : '${meal['calories']} kcal',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isFasting ? Colors.grey[500] : const Color(0xFF1DB954),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 운동 탭
  Widget _buildWorkoutTab() {
    final workouts = [
      {'date': '2026.01.02', 'name': '런닝', 'duration': 30, 'calories': 250},
      {'date': '2026.01.01', 'name': '웨이트 트레이닝', 'duration': 45, 'calories': 320},
      {'date': '2025.12.31', 'name': '요가', 'duration': 60, 'calories': 180},
      {'date': '2025.12.30', 'name': '사이클', 'duration': 40, 'calories': 280},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        final workout = workouts[index];
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 아이콘
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout['date'].toString(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      workout['name'].toString(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${workout['duration']}분',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              // 칼로리
              Text(
                '${workout['calories']} kcal',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 커뮤니티 탭
  Widget _buildCommunityTab() {
    final posts = [
      {'date': '2026.01.02', 'title': '다이어트 꿀팁 공유합니다', 'likes': 45, 'comments': 12},
      {'date': '2026.01.01', 'title': '오늘 아침 런닝 인증!', 'likes': 32, 'comments': 8},
      {'date': '2025.12.30', 'title': '저칼로리 식단 레시피', 'likes': 67, 'comments': 23},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post['date'].toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                post['title'].toString(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.favorite, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    post['likes'].toString(),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.comment, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    post['comments'].toString(),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// 좋아요 탭
  Widget _buildLikesTab() {
    final likes = [
      {'date': '2026.01.02', 'author': '건강왕', 'title': '아침 런닝 인증!', 'type': 'post'},
      {'date': '2026.01.01', 'author': '다이어터', 'title': '샐러드 레시피', 'type': 'post'},
      {'date': '2025.12.31', 'author': '요가마스터', 'title': '요가 30분 루틴', 'type': 'post'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: likes.length,
      itemBuilder: (context, index) {
        final like = likes[index];
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 하트 아이콘
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              // 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      like['author'].toString(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1DB954),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      like['title'].toString(),
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      like['date'].toString(),
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
        );
      },
    );
  }
}
