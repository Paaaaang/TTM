/// 운동 기록 추가 화면
/// ExerciseDetailScreen.tsx를 Flutter로 변환
import 'package:flutter/material.dart';
import 'package:ttm/services/exercise_service.dart';
import 'package:ttm/services/auth_service.dart';
import 'package:ttm/models/exercise_log.dart';

/// 운동 카테고리
enum ExerciseCategory { cardio, strength, flexibility, sports }

/// 운동 항목 모델
class Exercise {
  final String name;
  final ExerciseCategory category;
  final List<ExerciseDuration> durations;

  Exercise({
    required this.name,
    required this.category,
    required this.durations,
  });
}

/// 운동 시간별 칼로리
class ExerciseDuration {
  final String time;
  final int calories;

  ExerciseDuration({required this.time, required this.calories});
}

/// 운동 추가 화면 위젯
class ExerciseAddScreen extends StatefulWidget {
  const ExerciseAddScreen({Key? key}) : super(key: key);

  @override
  State<ExerciseAddScreen> createState() => _ExerciseAddScreenState();
}

class _ExerciseAddScreenState extends State<ExerciseAddScreen> {
  String _searchQuery = '';
  final List<Map<String, dynamic>> _selectedExercises = [];
  final ExerciseService _exerciseService = ExerciseService();
  final AuthService _authService = AuthService();
  bool _isSaving = false;

  /// 운동 데이터베이스
  final List<Exercise> _exerciseDatabase = [
    // 유산소 운동
    Exercise(
      name: '걷기',
      category: ExerciseCategory.cardio,
      durations: [
        ExerciseDuration(time: '10분', calories: 30),
        ExerciseDuration(time: '20분', calories: 60),
        ExerciseDuration(time: '30분', calories: 90),
        ExerciseDuration(time: '60분', calories: 180),
      ],
    ),
    Exercise(
      name: '런닝',
      category: ExerciseCategory.cardio,
      durations: [
        ExerciseDuration(time: '10분', calories: 80),
        ExerciseDuration(time: '20분', calories: 160),
        ExerciseDuration(time: '30분', calories: 240),
        ExerciseDuration(time: '60분', calories: 480),
      ],
    ),
    Exercise(
      name: '자전거',
      category: ExerciseCategory.cardio,
      durations: [
        ExerciseDuration(time: '10분', calories: 50),
        ExerciseDuration(time: '20분', calories: 100),
        ExerciseDuration(time: '30분', calories: 150),
        ExerciseDuration(time: '60분', calories: 300),
      ],
    ),
    Exercise(
      name: '수영',
      category: ExerciseCategory.cardio,
      durations: [
        ExerciseDuration(time: '10분', calories: 90),
        ExerciseDuration(time: '20분', calories: 180),
        ExerciseDuration(time: '30분', calories: 270),
        ExerciseDuration(time: '60분', calories: 540),
      ],
    ),
    // 근력 운동
    Exercise(
      name: '웨이트 트레이닝',
      category: ExerciseCategory.strength,
      durations: [
        ExerciseDuration(time: '20분', calories: 100),
        ExerciseDuration(time: '30분', calories: 150),
        ExerciseDuration(time: '45분', calories: 225),
        ExerciseDuration(time: '60분', calories: 300),
      ],
    ),
    Exercise(
      name: '푸시업',
      category: ExerciseCategory.strength,
      durations: [
        ExerciseDuration(time: '5분', calories: 30),
        ExerciseDuration(time: '10분', calories: 60),
        ExerciseDuration(time: '15분', calories: 90),
        ExerciseDuration(time: '20분', calories: 120),
      ],
    ),
    // 유연성 운동
    Exercise(
      name: '요가',
      category: ExerciseCategory.flexibility,
      durations: [
        ExerciseDuration(time: '20분', calories: 60),
        ExerciseDuration(time: '30분', calories: 90),
        ExerciseDuration(time: '45분', calories: 135),
        ExerciseDuration(time: '60분', calories: 180),
      ],
    ),
    Exercise(
      name: '스트레칭',
      category: ExerciseCategory.flexibility,
      durations: [
        ExerciseDuration(time: '10분', calories: 25),
        ExerciseDuration(time: '15분', calories: 38),
        ExerciseDuration(time: '20분', calories: 50),
        ExerciseDuration(time: '30분', calories: 75),
      ],
    ),
  ];

  /// 검색어로 필터링된 운동 목록
  List<Exercise> get _filteredExercises {
    if (_searchQuery.isEmpty) return _exerciseDatabase;
    return _exerciseDatabase
        .where(
          (ex) => ex.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      resizeToAvoidBottomInset: true, // 키보드가 올라올 때 자동으로 화면 조정
      appBar: AppBar(
        title: const Text('운동 추가'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedExercises.isNotEmpty)
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            else
              TextButton(
                onPressed: _saveExercises,
                child: const Text(
                  '저장',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        ],
      ),
      body: Column(
        children: [
          // 검색 바
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: '운동 검색...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // 선택된 운동 목록
          if (_selectedExercises.isNotEmpty)
            Container(
              color: Colors.blue[50],
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '선택된 운동 (${_selectedExercises.length}개)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedExercises.map((ex) {
                      return Chip(
                        label: Text('${ex['name']} ${ex['duration']}'),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            _selectedExercises.remove(ex);
                          });
                        },
                        backgroundColor: Colors.white,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // 운동 목록
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredExercises.length,
              itemBuilder: (context, index) {
                final exercise = _filteredExercises[index];
                return _buildExerciseCard(exercise);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 운동 카드 빌드
  Widget _buildExerciseCard(Exercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // 운동 이름 헤더
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(exercise.category),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getCategoryIcon(exercise.category),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _getCategoryName(exercise.category),
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 시간 옵션
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: exercise.durations.map((duration) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedExercises.add({
                        'name': exercise.name,
                        'duration': duration.time,
                        'calories': duration.calories,
                      });
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${exercise.name} ${duration.time} 추가됨'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      duration.time,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 카테고리별 색상
  Color _getCategoryColor(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.cardio:
        return Colors.orange;
      case ExerciseCategory.strength:
        return Colors.blue;
      case ExerciseCategory.flexibility:
        return Colors.purple;
      case ExerciseCategory.sports:
        return Colors.green;
    }
  }

  /// 카테고리별 아이콘
  IconData _getCategoryIcon(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.cardio:
        return Icons.directions_run;
      case ExerciseCategory.strength:
        return Icons.fitness_center;
      case ExerciseCategory.flexibility:
        return Icons.self_improvement;
      case ExerciseCategory.sports:
        return Icons.sports_soccer;
    }
  }

  /// 카테고리명
  String _getCategoryName(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.cardio:
        return '유산소';
      case ExerciseCategory.strength:
        return '근력';
      case ExerciseCategory.flexibility:
        return '유연성';
      case ExerciseCategory.sports:
        return '스포츠';
    }
  }

  /// 운동 저장
  Future<void> _saveExercises() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('로그인이 필요합니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 각 운동을 DB에 저장
      int successCount = 0;
      for (var exercise in _selectedExercises) {
        // 운동 시간을 분 단위로 변환
        final durationStr = exercise['duration'] as String; // 예: "10분", "20분"
        final durationMinutes =
            int.tryParse(durationStr.replaceAll('분', '')) ?? 0;

        final exerciseLog = ExerciseLog(
          memberId: currentUser.memberId,
          exerciseDate: DateTime.now(),
          exerciseName: exercise['name'] as String,
          durationMinutes: durationMinutes,
          caloriesBurned: (exercise['calories'] as int).toDouble(),
        );

        final result = await _exerciseService.createExercise(exerciseLog);
        if (result != null) {
          successCount++;
        }
      }

      if (mounted) {
        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('운동 ${successCount}개가 추가되었습니다'),
              backgroundColor: const Color(0xFF1DB954),
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('운동 저장에 실패했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('운동 저장 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('운동 저장 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
