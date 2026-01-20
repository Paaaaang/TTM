/// 통계 화면
/// StatsScreen.tsx를 Flutter로 변환
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/meal_service.dart';
import '../services/exercise_service.dart';
import '../services/auth_service.dart';
import '../services/weight_service.dart';
import '../models/user.dart';

/// 통계 화면 위젯
class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  // 기간 선택 (주간/월간)
  bool isWeekly = true;
  
  // 현재 주/월
  DateTime _currentDate = DateTime.now();
  
  // 로딩 상태
  bool _isLoading = true;
  
  // 실제 데이터
  List<Map<String, dynamic>> _statsData = [];

  // 영양 균형 점수/요약
  double _nutritionBalanceScore = 0;
  List<String> _nutritionSummaryLines = [];
  
  final MealService _mealService = MealService();
  final ExerciseService _exerciseService = ExerciseService();
  final AuthService _authService = AuthService();
  final WeightService _weightService = WeightService();
  
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }
  
  Widget _buildNutritionReportCard() {
    final periodLabel = isWeekly ? '주간' : '월간';
    final scoreText = _nutritionBalanceScore.toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_graph_rounded, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              Text(
                '$periodLabel 리포트',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '영양 점수 $scoreText',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_nutritionSummaryLines.isEmpty)
            Text(
              '리포트를 불러오는 중...',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _nutritionSummaryLines
                  .map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 12)),
                          Expanded(
                            child: Text(
                              line,
                              style: const TextStyle(fontSize: 12, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
  
  /// 사용자 정보 로드
  Future<void> _loadUserInfo() async {
    final user = await _authService.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _user = user;
    });
    _loadStats();
  }
  
  /// 통계 데이터 로드
  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    if (_user == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }
    
    try {
      List<Map<String, dynamic>> data = [];
      
      if (isWeekly) {
        // 주간 데이터: 월~일 7일
        final startOfWeek = _getStartOfWeek(_currentDate);
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        final now = DateTime.now();
        
        // 주간 체중 데이터 가져오기 (시작일 이전 데이터도 포함하여 forward-fill 용)
        List<Map<String, dynamic>> weightData = [];
        try {
          // 시작일 이전 30일부터 종료일까지 데이터 가져오기
          weightData = await _weightService.getWeeklyWeightData(
            startDate: startOfWeek.subtract(const Duration(days: 30)),
            endDate: endOfWeek,
          );
          print('체중 데이터 로드 성공: ${weightData.length}개');
        } catch (e) {
          print('체중 데이터 로드 실패: $e');
        }
        
        // 날짜별로 정렬된 체중 기록
        weightData.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
        
        double? lastKnownWeight;
        
        final balanceScores = <double>[];
        for (int i = 0; i < 7; i++) {
          final date = startOfWeek.add(Duration(days: i));
          final dateStr = DateFormat('yyyy-MM-dd').format(date);
          
          // 미래 날짜는 스킵 (오늘까지만 표시)
          if (date.isAfter(DateTime(now.year, now.month, now.day))) {
            continue;
          }
          
          final dayData = await _loadDayStats(_user!.memberId, date);
          final nutritionData = await _loadDayNutrition(_user!.memberId, date);
          balanceScores.add(_calculateBalanceScore(nutritionData));
          
          // 체중 데이터 찾기: forward-fill 방식
          double weight = 0.0;
          
          // 해당 날짜의 기록 찾기
          final todayRecord = weightData.where((r) => r['date'] == dateStr).toList();
          if (todayRecord.isNotEmpty) {
            weight = todayRecord.first['weight'] as double;
            lastKnownWeight = weight;
          } else if (lastKnownWeight != null) {
            // 이전에 알려진 체중 사용
            weight = lastKnownWeight;
          } else {
            // 해당 날짜 이전의 가장 최근 기록 찾기
            double? foundWeight;
            for (var record in weightData) {
              final recordDate = record['date'] as String;
              if (recordDate.compareTo(dateStr) < 0) {
                foundWeight = record['weight'] as double;
              } else {
                break; // 정렬되어 있으므로 날짜를 넘어가면 중단
              }
            }
            if (foundWeight != null) {
              weight = foundWeight;
              lastKnownWeight = weight;
            } else {
              // 이전 기록이 없으면 사용자 프로필 체중 사용
              weight = _user!.weightKg ?? 70.0;
              lastKnownWeight = weight;
            }
          }
          
          data.add({
            'name': DateFormat('E', 'ko').format(date),
            'date': date,
            'calories': dayData['calories'],
            'exercise': dayData['exercise'],
            'weight': weight,
          });
        }
      } else {
        // 월간 데이터: 4주 (미래 주는 제외)
        final startOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
        final endOfMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0);
        final now = DateTime.now();
        
        // 월간 체중 데이터 가져오기
        List<Map<String, dynamic>> weightData = [];
        try {
          // 이전 달 데이터도 포함하여 forward-fill 용
          weightData = await _weightService.getMonthlyWeightData(
            startDate: startOfMonth.subtract(const Duration(days: 30)),
            endDate: endOfMonth,
          );
          print('월간 체중 데이터 로드 성공: ${weightData.length}개');
        } catch (e) {
          print('월간 체중 데이터 로드 실패: $e');
        }
        
        for (int i = 0; i < 4; i++) {
          final weekStart = startOfMonth.add(Duration(days: i * 7));
          final weekEnd = weekStart.add(const Duration(days: 6));
          
          // 미래 주는 스킵
          if (weekStart.isAfter(DateTime(now.year, now.month, now.day))) {
            break;
          }
          
          final weekData = await _loadWeekStats(_user!.memberId, weekStart, weekEnd);
          
          // 해당 주의 평균 체중 계산
          double weekWeight = 70.0; // 기본값
          final weekWeights = weightData
              .where((record) {
                final recordDate = DateTime.parse(record['date'] as String);
                return recordDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                       recordDate.isBefore(weekEnd.add(const Duration(days: 1)));
              })
              .map((record) => record['weight'] as double)
              .toList();
          
          if (weekWeights.isNotEmpty) {
            // 해당 주에 기록이 있으면 평균 사용
            weekWeight = weekWeights.reduce((a, b) => a + b) / weekWeights.length;
          } else {
            // 해당 주 이전의 가장 최근 체중 기록 찾기
            double? foundWeight;
            for (var record in weightData) {
              final recordDate = DateTime.parse(record['date'] as String);
              if (recordDate.isBefore(weekStart)) {
                foundWeight = record['weight'] as double;
              }
            }
            if (foundWeight != null) {
              weekWeight = foundWeight;
            } else {
              // 이전 기록이 없으면 사용자 프로필 체중 사용
              weekWeight = _user!.weightKg ?? 70.0;
            }
          }
          
          data.add({
            'name': '${i + 1}주',
            'weekStart': weekStart,
            'calories': weekData['calories'],
            'exercise': weekData['exercise'],
            'weight': weekWeight,
          });
        }
      }
      
      final report = await _buildNutritionReport(isWeekly);
      if (mounted) {
        setState(() {
          _statsData = data;
          _nutritionBalanceScore = report['score'] as double;
          _nutritionSummaryLines = report['summaryLines'] as List<String>;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('통계 로드 오류: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  /// 하루 통계 로드
  Future<Map<String, int>> _loadDayStats(int userId, DateTime date) async {
    try {
      // 해당 날짜의 00:00:00부터 23:59:59까지
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final meals = await _mealService.getMealsByDateRange(userId, startOfDay, endOfDay);
      final exercises = await _exerciseService.getExercisesByDateRange(userId, startOfDay, endOfDay);
      
      // 각 meal_type별로 최신 식단만 선택하여 합산 (홈 화면과 동일한 로직)
      double totalCalories = 0;
      final mealTypes = ['BREAKFAST', 'LUNCH', 'DINNER', 'SNACK'];
      for (var type in mealTypes) {
        final mealsByType = meals.where((m) => m.mealType == type).toList();
        if (mealsByType.isNotEmpty) {
          // 가장 최근 식단만 선택
          final latestMeal = mealsByType.reduce((a, b) => 
            a.createdAt!.isAfter(b.createdAt!) ? a : b
          );
          totalCalories += latestMeal.totalCalories;
        }
      }
      
      double totalExercise = 0;
      for (var exercise in exercises) {
        totalExercise += exercise.caloriesBurned ?? 0;
      }
      
      return {'calories': totalCalories.round(), 'exercise': totalExercise.round()};
    } catch (e) {
      print('하루 통계 로드 오류: $e');
      return {'calories': 0, 'exercise': 0};
    }
  }
  
  /// 주간 평균 통계 로드
  Future<Map<String, int>> _loadWeekStats(int userId, DateTime start, DateTime end) async {
    try {
      final meals = await _mealService.getMealsByDateRange(userId, start, end.add(const Duration(days: 1)));
      final exercises = await _exerciseService.getExercisesByDateRange(userId, start, end.add(const Duration(days: 1)));
      
      double totalCalories = 0;
      for (var meal in meals) {
        totalCalories += meal.totalCalories;
      }
      
      double totalExercise = 0;
      for (var exercise in exercises) {
        totalExercise += exercise.caloriesBurned ?? 0;
      }
      
      // 7일 평균
      return {
        'calories': (totalCalories / 7).round(),
        'exercise': (totalExercise / 7).round(),
      };
    } catch (e) {
      print('주간 통계 로드 오류: $e');
      return {'calories': 0, 'exercise': 0};
    }
  }

  Future<Map<String, double>> _loadDayNutrition(int userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final meals = await _mealService.getMealsByDateRange(userId, startOfDay, endOfDay);

    double carbs = 0;
    double protein = 0;
    double fat = 0;
    double sugar = 0;
    double sodium = 0;

    for (final meal in meals) {
      carbs += meal.totalCarbohydrates;
      protein += meal.totalProtein;
      fat += meal.totalFat;
      sugar += meal.totalSugar;
      sodium += meal.totalSodium;
    }

    return {
      'carbs': carbs,
      'protein': protein,
      'fat': fat,
      'sugar': sugar,
      'sodium': sodium,
    };
  }

  double _calculateBalanceScore(Map<String, double> totals) {
    final carbsG = totals['carbs'] ?? 0;
    final proteinG = totals['protein'] ?? 0;
    final fatG = totals['fat'] ?? 0;
    final sugarG = totals['sugar'] ?? 0;
    final sodiumMg = totals['sodium'] ?? 0;

    final macroCalories = carbsG * 4 + proteinG * 4 + fatG * 9;
    if (macroCalories <= 0) {
      return 0;
    }

    final carbRatio = (carbsG * 4) / macroCalories;
    final proteinRatio = (proteinG * 4) / macroCalories;
    final fatRatio = (fatG * 9) / macroCalories;

    double score = 100;
    score -= ((carbRatio - 0.5).abs() + (proteinRatio - 0.3).abs() + (fatRatio - 0.2).abs()) * 100;

    // 당류/나트륨 과다 시 감점
    if (sugarG > 50) {
      score -= ((sugarG - 50) / 5).clamp(0, 20);
    }
    if (sodiumMg > 2000) {
      score -= ((sodiumMg - 2000) / 100).clamp(0, 20);
    }

    if (score < 0) return 0;
    if (score > 100) return 100;
    return score;
  }

  Future<Map<String, dynamic>> _buildNutritionReport(bool weekly) async {
    if (_user == null) {
      return {
        'score': 0.0,
        'summaryLines': <String>[],
      };
    }

    DateTime start;
    DateTime end;
    final now = DateTime.now();

    if (weekly) {
      start = _getStartOfWeek(_currentDate);
      end = start.add(const Duration(days: 6));
    } else {
      start = DateTime(_currentDate.year, _currentDate.month, 1);
      end = DateTime(_currentDate.year, _currentDate.month + 1, 0);
    }

    final meals = await _mealService.getMealsByDateRange(
      _user!.memberId,
      start,
      end.add(const Duration(days: 1)),
    );

    final dayTotals = <String, Map<String, double>>{};
    final breakfastDates = <String>{};
    int lowProteinDinnerDays = 0;

    for (final meal in meals) {
      final dateStr = DateFormat('yyyy-MM-dd').format(meal.mealDate);
      final totals = dayTotals.putIfAbsent(dateStr, () => {
            'carbs': 0,
            'protein': 0,
            'fat': 0,
            'sugar': 0,
            'sodium': 0,
          });

      totals['carbs'] = (totals['carbs'] ?? 0) + meal.totalCarbohydrates;
      totals['protein'] = (totals['protein'] ?? 0) + meal.totalProtein;
      totals['fat'] = (totals['fat'] ?? 0) + meal.totalFat;
      totals['sugar'] = (totals['sugar'] ?? 0) + meal.totalSugar;
      totals['sodium'] = (totals['sodium'] ?? 0) + meal.totalSodium;

      if (meal.mealType == 'BREAKFAST') {
        breakfastDates.add(dateStr);
      }
      if (meal.mealType == 'DINNER' && meal.totalProtein < 20) {
        lowProteinDinnerDays += 1;
      }
    }

    final scores = dayTotals.values.map(_calculateBalanceScore).toList();
    final avgScore = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;

    final periodLabel = weekly ? '최근 7일' : '최근 30일';
    final summaryLines = <String>[
      lowProteinDinnerDays >= 3
          ? '$periodLabel 동안 저녁 단백질 섭취가 낮은 날이 많았어요.'
          : '$periodLabel 동안 저녁 단백질 섭취가 낮은 날은 ${lowProteinDinnerDays}일이에요.',
      '아침 식사를 기록한 날은 ${breakfastDates.length}일이에요.',
      '영양 균형 점수는 ${avgScore.toStringAsFixed(0)}점이에요.',
    ];

    // 미래 날짜 제외 보정
    if (end.isAfter(now)) {
      end = DateTime(now.year, now.month, now.day);
    }

    return {
      'score': avgScore,
      'summaryLines': summaryLines,
    };
  }
  
  /// 주의 시작일 (월요일) 구하기
  DateTime _getStartOfWeek(DateTime date) {
    final weekday = date.weekday; // 1(월) ~ 7(일)
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: weekday - 1));
  }
  
  /// 이전 주/월로 이동
  void _previousPeriod() {
    setState(() {
      if (isWeekly) {
        _currentDate = _currentDate.subtract(const Duration(days: 7));
      } else {
        _currentDate = DateTime(_currentDate.year, _currentDate.month - 1);
      }
      _loadStats();
    });
  }
  
  /// 다음 주/월로 이동
  void _nextPeriod() {
    // 미래로는 이동 불가 (현재 주/월까지만)
    final now = DateTime.now();
    DateTime nextDate;
    
    if (isWeekly) {
      nextDate = _currentDate.add(const Duration(days: 7));
      final nextWeekStart = _getStartOfWeek(nextDate);
      final nowWeekStart = _getStartOfWeek(now);
      
      // 다음 주가 미래라면 이동 불가
      if (nextWeekStart.isAfter(nowWeekStart)) {
        return;
      }
    } else {
      nextDate = DateTime(_currentDate.year, _currentDate.month + 1);
      
      // 다음 달이 미래라면 이동 불가
      if (nextDate.year > now.year || 
          (nextDate.year == now.year && nextDate.month > now.month)) {
        return;
      }
    }
    
    setState(() {
      _currentDate = nextDate;
      _loadStats();
    });
  }
  
  /// 다음 버튼 활성화 여부
  bool get _canGoNext {
    final now = DateTime.now();
    
    if (isWeekly) {
      final nextDate = _currentDate.add(const Duration(days: 7));
      final nextWeekStart = _getStartOfWeek(nextDate);
      final nowWeekStart = _getStartOfWeek(now);
      return !nextWeekStart.isAfter(nowWeekStart);
    } else {
      final nextDate = DateTime(_currentDate.year, _currentDate.month + 1);
      return nextDate.year < now.year || 
             (nextDate.year == now.year && nextDate.month <= now.month);
    }
  }
  
  /// 현재 기간 텍스트
  String get _periodText {
    if (isWeekly) {
      final now = DateTime.now();
      final thisWeekStart = _getStartOfWeek(now);
      final currentWeekStart = _getStartOfWeek(_currentDate);
      
      if (thisWeekStart.year == currentWeekStart.year &&
          thisWeekStart.month == currentWeekStart.month &&
          thisWeekStart.day == currentWeekStart.day) {
        return '이번주';
      }
      return '${_currentDate.month}월 ${_getStartOfWeek(_currentDate).day}일 주';
    } else {
      final now = DateTime.now();
      if (now.year == _currentDate.year && now.month == _currentDate.month) {
        return '이번달';
      }
      return '${_currentDate.year}년 ${_currentDate.month}월';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('통계'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    final data = _statsData;
    
    // 통계 계산
    final avgCalories = data.isEmpty ? 0 : (data.fold<double>(0, (sum, item) => sum + item['calories']) / data.length).round();
    final avgExercise = data.isEmpty ? 0 : (data.fold<double>(0, (sum, item) => sum + item['exercise']) / data.length).round();
    final weightChange = data.isEmpty ? 0.0 : data.last['weight'] - data.first['weight'];
    
    // 칼로리 및 운동 변화량 계산 (마지막 - 첫번째)
    final caloriesChange = data.isEmpty ? 0.0 : (data.last['calories'] - data.first['calories']).toDouble();
    final exerciseChange = data.isEmpty ? 0.0 : (data.last['exercise'] - data.first['exercise']).toDouble();
    
    // 오늘 날짜 기준 최신 체중 (data의 마지막 값)
    final currentWeight = data.isEmpty ? (_user?.weightKg ?? 0.0) : data.last['weight'].toDouble();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('통계'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 날짜 네비게이션 (< 이번주/이번달 >) - 고정
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousPeriod,
                ),
                Text(
                  _periodText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right,
                    color: _canGoNext ? Colors.black : Colors.grey[300],
                  ),
                  onPressed: _canGoNext ? _nextPeriod : null,
                ),
              ],
            ),
          ),
          
          // 기간 선택 (주간/월간) - 고정
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildPeriodButton('주간', isWeekly, () {
                    setState(() {
                      isWeekly = true;
                      _currentDate = DateTime.now();
                      _loadStats();
                    });
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPeriodButton('월간', !isWeekly, () {
                    setState(() {
                      isWeekly = false;
                      _currentDate = DateTime.now();
                      _loadStats();
                    });
                  }),
                ),
              ],
            ),
          ),

          // 스크롤 가능한 콘텐츠
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 요약 카드
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              '🔥',
                              'kcal',
                              '평균',
                              avgCalories.toString(),
                              caloriesChange,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              '💪',
                              'kcal',
                              '평균',
                              avgExercise.toString(),
                              exerciseChange,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildWeightCard(
                              '⚖️',
                              'kg',
                              currentWeight,
                              weightChange,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 영양 균형 리포트
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildNutritionReportCard(),
                  ),

                  const SizedBox(height: 16),

                  // 칼로리 차트
                  _buildChartCard(
                    '칼로리 섭취',
                    data,
                    'calories',
                    Colors.orange,
                  ),

                  const SizedBox(height: 16),

                  // 운동 차트
                  _buildChartCard(
                    '운동 칼로리',
                    data,
                    'exercise',
                    Colors.blue,
                  ),

                  const SizedBox(height: 16),

                  // 체중 차트
                  _buildChartCard(
                    '체중 변화',
                    data,
                    'weight',
                    Colors.green,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 체중 기록 버튼 - 체중 그래프 하단으로 이동
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showWeightRecordPopup,
                        icon: const Icon(Icons.edit),
                        label: const Text('체중 기록하기'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),
                ],
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }
  
  /// 체중 기록 팝업
  void _showWeightRecordPopup() {
    final TextEditingController weightController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final BuildContext dialogContext = context; // 다이얼로그 외부의 context 캡처

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('체중 기록'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 체중 입력
                  TextField(
                    controller: weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: '체중 (kg)',
                      border: OutlineInputBorder(),
                      suffixText: 'kg',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 날짜 선택
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext, // 다이얼로그 외부 context 사용
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(), // 미래 날짜 입력 금지
                        locale: const Locale('ko', 'KR'),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                        DateFormat('yyyy년 MM월 dd일').format(selectedDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
                  ),
                ),
              ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final weight = double.tryParse(weightController.text);
                    if (weight == null || weight <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('올바른 체중을 입력해주세요')),
                      );
                      return;
                    }
                    
                    try {
                      // 체중 기록 API 호출
                      await _weightService.createWeightRecord(
                        weightKg: weight,
                        recordedDate: selectedDate,
                      );
                      
                      Navigator.pop(context);
                      
                      // 통계 새로고침
                      await _loadStats();
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('체중이 기록되었습니다')),
                        );
                      }
                    } catch (e) {
                      Navigator.pop(context);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('체중 기록 실패: ${e.toString()}')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('기록하기'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 기간 선택 버튼
  Widget _buildPeriodButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }


  /// 요약 카드 (평균 칼로리, 평균 운동)
  Widget _buildSummaryCard(
    String emoji,
    String unit,
    String label,
    String value,
    double change,
    Color color,
  ) {
    final isIncrease = change > 0;
    final changeText = change == 0.0 
        ? '0.0' 
        : '${isIncrease ? "+" : ""}${change.toStringAsFixed(1)}';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 15),
              ),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    changeText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// 체중 카드
  Widget _buildWeightCard(
    String emoji,
    String unit,
    double currentWeight,
    double weightChange,
    Color color,
  ) {
    final isDecrease = weightChange < 0;
    final changeText = weightChange == 0.0 
        ? '변화없음' 
        : '${isDecrease ? "" : "+"}${weightChange.toStringAsFixed(1)}';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 15),
              ),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '체중',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currentWeight.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (weightChange != 0.0)
                    Row(
                      children: [
                        Icon(
                          isDecrease ? Icons.arrow_downward : Icons.arrow_upward,
                          size: 10,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          changeText,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 차트 카드
  Widget _buildChartCard(
    String title,
    List<Map<String, dynamic>> data,
    String dataKey,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: data.isEmpty
                ? Center(
                    child: Text(
                      '데이터가 없습니다',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _getGridInterval(data, dataKey), // 동적 간격 계산
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < data.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              data[value.toInt()]['name'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: _getGridInterval(data, dataKey), // 동적 간격 계산
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (data.length - 1).toDouble(),
                minY: _getMinY(data, dataKey),
                maxY: _getMaxY(data, dataKey),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value[dataKey].toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: color,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 차트 최소값 계산
  /// Y축 그리드 간격 계산 (최대 10개 보조선)
  double _getGridInterval(List<Map<String, dynamic>> data, String dataKey) {
    if (data.isEmpty) return 1;
    
    final minY = _getMinY(data, dataKey);
    final maxY = _getMaxY(data, dataKey);
    final range = maxY - minY;
    
    if (dataKey == 'weight') {
      // 체중: 항상 10kg 단위 (Y축 보조단위 10단위)
      return 10;
    }
    
    // 칼로리/운동: 범위에 따라 동적 간격
    if (range <= 1000) return 100;
    if (range <= 2000) return 200;
    if (range <= 5000) return 500;
    return (range / 10).ceilToDouble();
  }

  /// 차트 최소값 계산
  double _getMinY(List<Map<String, dynamic>> data, String dataKey) {
    if (data.isEmpty) return 0;
    
    final values = data.map((e) => e[dataKey].toDouble()).toList();
    if (values.isEmpty) return 0;
    
    if (dataKey == 'weight') {
      // 체중: 최소값에서 10kg 아래로 내림 (10단위)
      final min = values.reduce((a, b) => a < b ? a : b);
      return ((min - 10) / 10).floor() * 10.0.clamp(0, double.infinity);
    }
    
    // 칼로리/운동 그래프는 0부터 시작
    return 0;
  }

  /// 차트 최대값 계산
  double _getMaxY(List<Map<String, dynamic>> data, String dataKey) {
    if (data.isEmpty) return 100;
    
    final values = data.map((e) => e[dataKey].toDouble()).toList();
    if (values.isEmpty) return 100;
    
    final max = values.reduce((a, b) => a > b ? a : b);
    
    if (dataKey == 'weight') {
      // 체중: 최대값에서 10kg 위로 올림 (10단위)
      return ((max + 10) / 10).ceil() * 10.0;
    }
    
    // 칼로리/운동: 최대값 + 100kcal 여유 (100kcal 단위로 반올림)
    return ((max + 100) / 100).ceil() * 100;
  }
}
