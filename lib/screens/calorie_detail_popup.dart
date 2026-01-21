import 'package:flutter/material.dart';
import 'package:ttm/constants/app_colors.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

/// 오늘의 칼로리 상세 팝업
class CalorieDetailPopup extends StatefulWidget {
  final int intakeCalories;
  final int burnedCalories;
  final int targetCalories;
  final User currentUser; // 현재 사용자 정보
  final VoidCallback? onCalorieGoalUpdated; // 칼로리 목표 업데이트 시 콜백

  // 각 식사별 칼로리
  final int breakfastCalories;
  final int lunchCalories;
  final int dinnerCalories;
  final int snackCalories;

  // 각 식사별 영양소
  final double breakfastCarbs;
  final double breakfastProtein;
  final double breakfastFat;
  final double lunchCarbs;
  final double lunchProtein;
  final double lunchFat;
  final double dinnerCarbs;
  final double dinnerProtein;
  final double dinnerFat;
  final double snackCarbs;
  final double snackProtein;
  final double snackFat;

  // 총 영양소
  final double totalCarbs;
  final double totalProtein;
  final double totalFat;

  const CalorieDetailPopup({
    super.key,
    required this.intakeCalories,
    required this.burnedCalories,
    required this.targetCalories,
    required this.currentUser,
    this.onCalorieGoalUpdated,
    required this.breakfastCalories,
    required this.lunchCalories,
    required this.dinnerCalories,
    required this.snackCalories,
    required this.breakfastCarbs,
    required this.breakfastProtein,
    required this.breakfastFat,
    required this.lunchCarbs,
    required this.lunchProtein,
    required this.lunchFat,
    required this.dinnerCarbs,
    required this.dinnerProtein,
    required this.dinnerFat,
    required this.snackCarbs,
    required this.snackProtein,
    required this.snackFat,
    required this.totalCarbs,
    required this.totalProtein,
    required this.totalFat,
  });

  @override
  State<CalorieDetailPopup> createState() => _CalorieDetailPopupState();
}

class _CalorieDetailPopupState extends State<CalorieDetailPopup> {
  late TextEditingController _targetController;
  bool _isEditing = false;
  int _currentTargetCalories = 0;

  @override
  void initState() {
    super.initState();
    _targetController = TextEditingController(
      text: widget.targetCalories.toString(),
    );
    _currentTargetCalories = widget.targetCalories;
    _targetController.addListener(_handleTargetChange);
  }

  @override
  void dispose() {
    _targetController.removeListener(_handleTargetChange);
    _targetController.dispose();
    super.dispose();
  }

  void _handleTargetChange() {
    final parsed = int.tryParse(_targetController.text);
    if (parsed != null && parsed > 0 && parsed != _currentTargetCalories) {
      setState(() {
        _currentTargetCalories = parsed;
      });
    }
  }

  void _saveTarget() async {
    final newCalorieGoal = int.tryParse(_targetController.text);

    if (newCalorieGoal == null || newCalorieGoal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('올바른 칼로리 값을 입력해주세요'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final authService = AuthService();
    final success = await authService.updateCalorieGoal(
      widget.currentUser.memberId,
      newCalorieGoal,
    );

    if (success) {
      setState(() => _isEditing = false);

      // 부모 위젯에 업데이트 알림
      widget.onCalorieGoalUpdated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('목표 칼로리가 저장되었습니다'),
            backgroundColor: Color(0xFF1DB954),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('목표 칼로리 저장에 실패했습니다'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Color(0xFF1DB954),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '오늘의 칼로리',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 칼로리 요약
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1DB954).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '칼로리 목표',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (!_isEditing)
                          TextButton.icon(
                            onPressed: () => setState(() => _isEditing = true),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('수정'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF1DB954),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isEditing)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _targetController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                suffixText: 'kcal',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _saveTarget,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1DB954),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('저장'),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.intakeCalories - widget.burnedCalories} kcal',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1DB954),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '현재 칼로리',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${_targetController.text} kcal',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '목표',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 섭취/소모 칼로리
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            '섭취',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${widget.intakeCalories}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const Text(
                            'kcal',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            '소모',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${widget.burnedCalories}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const Text(
                            'kcal',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 상세 영양 정보
              const Text(
                '상세 영양 정보',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // 탄단지 목표 칼로리바 (총량)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // 목표 칼로리 기반 탄단지 목표(50/30/20)
                    // 탄수화물 4kcal/g, 단백질 4kcal/g, 지방 9kcal/g
                    Builder(
                      builder: (context) {
                        final targetCalories = _currentTargetCalories;
                        final targetCarbs = (targetCalories * 0.5 / 4).round();
                        final targetProtein = (targetCalories * 0.3 / 4)
                            .round();
                        final targetFat = (targetCalories * 0.2 / 9).round();
                        return Row(
                          children: [
                            Expanded(
                              child: _buildNutrientColumn(
                                '탄수화물',
                                widget.totalCarbs.toInt(),
                                targetCarbs,
                                AppColors.carbs,
                              ),
                            ),
                            Expanded(
                              child: _buildNutrientColumn(
                                '단백질',
                                widget.totalProtein.toInt(),
                                targetProtein,
                                AppColors.protein,
                              ),
                            ),
                            Expanded(
                              child: _buildNutrientColumn(
                                '지방',
                                widget.totalFat.toInt(),
                                targetFat,
                                AppColors.fat,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // 당류/나트륨 수치 표시 (TODO: 추후 DB에 추가 예정)
                    Text(
                      '당류, 나트륨 정보는 추후 추가 예정',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 식사별 상세 정보
              const Text(
                '식사별 상세',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // 아침
              _buildMealDetail(
                '아침',
                '🌅',
                widget.breakfastCalories,
                widget.breakfastCarbs,
                widget.breakfastProtein,
                widget.breakfastFat,
              ),
              const SizedBox(height: 8),

              // 점심
              _buildMealDetail(
                '점심',
                '🌞',
                widget.lunchCalories,
                widget.lunchCarbs,
                widget.lunchProtein,
                widget.lunchFat,
              ),
              const SizedBox(height: 8),

              // 저녁
              _buildMealDetail(
                '저녁',
                '🌙',
                widget.dinnerCalories,
                widget.dinnerCarbs,
                widget.dinnerProtein,
                widget.dinnerFat,
              ),
              const SizedBox(height: 8),

              // 간식
              _buildMealDetail(
                '간식',
                '🍎',
                widget.snackCalories,
                widget.snackCarbs,
                widget.snackProtein,
                widget.snackFat,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalorieRow(String label, int value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        Text(
          '$value kcal',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildNutrientColumn(
    String label,
    int current,
    int target,
    Color color,
  ) {
    final percentage = (current / target * 100).toInt();

    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
          ),
          child: Center(
            child: Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          '$current / $target g',
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  // 식사별 상세 정보 위젯
  Widget _buildMealDetail(
    String mealName,
    String emoji,
    int calories,
    double carbs,
    double protein,
    double fat,
  ) {
    // 칼로리가 0이면 회색으로 표시
    final hasData = calories > 0;

    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: hasData ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // 이모지 + 식사명
          Text(
            '$emoji $mealName',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: hasData ? Colors.black87 : Colors.grey[500],
            ),
          ),
          const SizedBox(width: 12),

          // 칼로리 수치
          SizedBox(
            width: 70,
            child: Text(
              '$calories kcal',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: hasData ? const Color(0xFF1DB954) : Colors.grey[500],
              ),
              textAlign: TextAlign.end,
            ),
          ),

          const SizedBox(width: 12),

          // 영양소 정보 (탄단지)
          Row(
            children: [
              _buildNutrientBadge('탄', carbs, AppColors.carbs),
              const SizedBox(width: 4),
              _buildNutrientBadge('단', protein, AppColors.protein),
              const SizedBox(width: 4),
              _buildNutrientBadge('지', fat, AppColors.fat),
            ],
          ),
        ],
      ),
    );
  }

  // 영양소 뱃지 위젯
  Widget _buildNutrientBadge(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label ${value.toStringAsFixed(0)}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
