/// 운동 기록 상세 화면
/// WorkoutRecordDetailScreen.tsx를 Flutter로 변환
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 운동 기록 모델
class WorkoutRecord {
  final int id;
  final DateTime date;
  final String type;
  final String duration;
  final int calories;

  WorkoutRecord({
    required this.id,
    required this.date,
    required this.type,
    required this.duration,
    required this.calories,
  });
}

/// 운동 기록 상세 화면 위젯
class ExerciseDetailScreen extends StatelessWidget {
  final WorkoutRecord workout;

  const ExerciseDetailScreen({
    Key? key,
    required this.workout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2196F3),
              Color(0xFF1976D2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 헤더 영역
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        '운동 기록',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // 중앙 정렬을 위한 공간
                  ],
                ),
              ),

              // 메인 콘텐츠
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 운동 정보 카드
                        _buildInfoCard(),
                        const SizedBox(height: 20),

                        // 소모 칼로리 표시
                        _buildCalorieCard(),
                        const SizedBox(height: 20),

                        // 운동 세부 정보
                        _buildDetailsCard(),
                        const SizedBox(height: 20),

                        // 운동 효과
                        _buildEffectsSection(),
                      ],
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

  /// 운동 정보 카드
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 아이콘
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.fitness_center,
              size: 32,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          // 운동 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.type,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('yyyy.MM.dd').format(workout.date),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('HH:mm').format(workout.date),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 칼로리 카드
  Widget _buildCalorieCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.local_fire_department,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          const Text(
            '소모 칼로리',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${workout.calories}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8, left: 4),
                child: Text(
                  'kcal',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 세부 정보 카드
  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '운동 세부 정보',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.timer, '운동 시간', workout.duration),
          const Divider(height: 32),
          _buildDetailRow(Icons.speed, '강도', '보통'),
          const Divider(height: 32),
          _buildDetailRow(
            Icons.local_fire_department,
            '칼로리 소모',
            '${workout.calories} kcal',
          ),
        ],
      ),
    );
  }

  /// 세부 정보 행
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.blue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// 운동 효과 섹션
  Widget _buildEffectsSection() {
    final effects = _getWorkoutEffects(workout.type);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이 운동의 효과',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...effects.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: entry.key < effects.length - 1 ? 12 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// 운동 유형별 효과
  List<String> _getWorkoutEffects(String workoutType) {
    final effectsMap = {
      '걷기': [
        '심혈관 건강 개선',
        '스트레스 감소',
        '체중 관리',
        '관절 부담 최소화',
      ],
      '런닝': [
        '심폐 지구력 향상',
        '체지방 감소',
        '뼈 강화',
        '정신 건강 개선',
      ],
      '자전거': [
        '하체 근력 강화',
        '유산소 능력 향상',
        '관절 보호',
        '칼로리 소모 효과',
      ],
      '수영': [
        '전신 근육 사용',
        '체중 부담 없음',
        '심폐 기능 향상',
        '유연성 증가',
      ],
      '웨이트 트레이닝': [
        '근육량 증가',
        '기초대사량 향상',
        '골밀도 증가',
        '자세 개선',
      ],
      '푸시업': [
        '상체 근력 강화',
        '코어 안정성 향상',
        '자세 교정',
        '언제 어디서나 가능',
      ],
      '요가': [
        '유연성 증가',
        '스트레스 완화',
        '자세 개선',
        '집중력 향상',
      ],
      '스트레칭': [
        '근육 이완',
        '혈액 순환 개선',
        '부상 예방',
        '관절 가동범위 증가',
      ],
    };

    return effectsMap[workoutType] ?? [
      '신체 활동 증가',
      '칼로리 소모',
      '건강 증진',
    ];
  }
}
