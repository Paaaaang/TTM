import 'package:flutter/material.dart';
import 'package:ttm/models/meal_log.dart';
import 'package:ttm/models/meal_item.dart';
import 'package:ttm/services/meal_service.dart';

/// 식단 수정 팝업
class MealEditPopup extends StatefulWidget {
  final MealLog mealLog;
  final VoidCallback onUpdated;

  const MealEditPopup({
    Key? key,
    required this.mealLog,
    required this.onUpdated,
  }) : super(key: key);

  @override
  State<MealEditPopup> createState() => _MealEditPopupState();
}

class _MealEditPopupState extends State<MealEditPopup> {
  final MealService _mealService = MealService();
  late List<MealItem> _items;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.mealLog.items);
  }

  String get _mealTypeName {
    switch (widget.mealLog.mealType) {
      case 'BREAKFAST':
        return '아침';
      case 'LUNCH':
        return '점심';
      case 'DINNER':
        return '저녁';
      case 'SNACK':
        return '간식';
      default:
        return '식단';
    }
  }

  // 현재 아이템들의 총 칼로리 계산
  double get _totalCalories {
    return _items.fold(0.0, (sum, item) => sum + (item.caloriesKcal ?? 0));
  }

  // 기록 시간 포맷팅
  String get _recordedTime {
    final createdAt = widget.mealLog.createdAt;
    if (createdAt == null) return '';
    final hour = createdAt.hour;
    final minute = createdAt.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$period $displayHour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_mealTypeName 식단',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${_totalCalories.toInt()} kcal',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  if (_recordedTime.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '기록 시간: $_recordedTime',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 음식 리스트
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.foodName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${item.caloriesKcal?.toInt() ?? 0} kcal',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (item.carbohydratesG != null && item.carbohydratesG! > 0)
                                    Text(
                                      '탄 ${item.carbohydratesG!.toStringAsFixed(1)}g',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  const SizedBox(width: 4),
                                  if (item.proteinG != null && item.proteinG! > 0)
                                    Text(
                                      '단 ${item.proteinG!.toStringAsFixed(1)}g',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  const SizedBox(width: 4),
                                  if (item.fatG != null && item.fatG! > 0)
                                    Text(
                                      '지 ${item.fatG!.toStringAsFixed(1)}g',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _deleteItem(index),
                          icon: const Icon(Icons.close),
                          iconSize: 20,
                          color: Colors.grey[400],
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 하단 버튼
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 메뉴 추가하기 버튼
                  OutlinedButton(
                    onPressed: () {
                      // 팝업 닫고 식단 추가 화면으로 이동
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        '/meal/add',
                        arguments: {'mealType': widget.mealLog.mealType},
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      side: BorderSide(color: Colors.grey[400]!, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.grey[700]),
                        const SizedBox(width: 8),
                        Text(
                          '추가할 메뉴가 있으신가요?',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // 저장 / 닫기 버튼
                  Row(
                    children: [
                      // 저장 버튼
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveMeal,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFF1DB954),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  '저장',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 닫기 버튼
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey[400]!, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            '닫기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 음식 아이템 삭제 (UI에서만 제거, 저장 버튼 눌러야 DB 반영)
  void _deleteItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('음식이 제거되었습니다. 저장 버튼을 눌러주세요.'),
        backgroundColor: Color(0xFF1DB954),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // 변경사항 저장
  Future<void> _saveMeal() async {
    if (_items.isEmpty) {
      // 모든 아이템이 삭제된 경우
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('식단 삭제'),
          content: const Text('모든 음식이 제거되었습니다. 이 식단을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // 다이얼로그 닫기
                await _deleteMealCompletely();
              },
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // 기존 식단 삭제
      await _mealService.deleteMeal(widget.mealLog.mealLogId!, widget.mealLog.memberId);
      
      // 새로운 식단으로 다시 생성
      final updatedMealLog = MealLog(
        memberId: widget.mealLog.memberId,
        mealDate: widget.mealLog.mealDate,
        mealType: widget.mealLog.mealType,
        memo: widget.mealLog.memo,
        items: _items,
      );
      await _mealService.createMeal(updatedMealLog);

      if (mounted) {
        Navigator.pop(context); // 팝업 닫기
        widget.onUpdated(); // 홈 화면 새로고침
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('식단이 저장되었습니다'),
            backgroundColor: Color(0xFF1DB954),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 식단 완전 삭제
  Future<void> _deleteMealCompletely() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _mealService.deleteMeal(widget.mealLog.mealLogId!, widget.mealLog.memberId);
      
      if (mounted) {
        Navigator.pop(context); // 팝업 닫기
        widget.onUpdated(); // 홈 화면 새로고침
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('식단이 삭제되었습니다'),
            backgroundColor: Color(0xFF1DB954),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
