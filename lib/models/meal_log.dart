import 'package:ttm/models/meal_item.dart';

/// 식단 기록 모델
/// 
/// DB 테이블: meal_log
/// 매핑 규칙: snake_case(DB) → camelCase(Dart)
/// - meal_log_id (INT PK) → mealLogId
/// - member_id (INT FK) → memberId
/// - meal_date (DATE) → mealDate
/// - meal_type (ENUM: BREAKFAST, LUNCH, DINNER, SNACK) → mealType
/// - memo (TEXT) → memo
/// - created_at (TIMESTAMP) → createdAt
class MealLog {
  final int? mealLogId;
  final DateTime mealDate;
  final String mealType; // BREAKFAST, LUNCH, DINNER, SNACK
  final String? memo;
  final DateTime? createdAt;
  final int memberId;
  final List<MealItem> items;
  final double totalCalories;

  MealLog({
    this.mealLogId,
    required this.mealDate,
    required this.mealType,
    this.memo,
    this.createdAt,
    required this.memberId,
    this.items = const [],
    this.totalCalories = 0.0,
  });

  /// JSON to MealLog
  factory MealLog.fromJson(Map<String, dynamic> json) {
    List<MealItem> itemsList = [];
    if (json['items'] != null) {
      itemsList = (json['items'] as List)
          .map((item) => MealItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return MealLog(
      mealLogId: json['meal_log_id'] as int?,
      mealDate: DateTime.parse(json['meal_date'] as String),
      mealType: json['meal_type'] as String,
      memo: json['memo'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      memberId: json['member_id'] as int,
      items: itemsList,
      totalCalories: json['total_calories'] != null
          ? (json['total_calories'] as num).toDouble()
          : 0.0,
    );
  }

  /// MealLog to JSON
  Map<String, dynamic> toJson() {
    return {
      if (mealLogId != null) 'meal_log_id': mealLogId,
      'meal_date': mealDate.toIso8601String().split('T')[0], // YYYY-MM-DD
      'meal_type': mealType,
      if (memo != null) 'memo': memo,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      'member_id': memberId,
      'items': items.map((item) => item.toJson()).toList(),
      'total_calories': totalCalories,
    };
  }

  /// 식사 타입의 한글 표시명
  String get mealTypeName {
    switch (mealType) {
      case 'BREAKFAST':
        return '아침';
      case 'LUNCH':
        return '점심';
      case 'DINNER':
        return '저녁';
      case 'SNACK':
        return '간식';
      default:
        return mealType;
    }
  }

  /// 총 영양소 계산
  double get totalCarbohydrates =>
      items.fold(0.0, (sum, item) => sum + (item.carbohydratesG ?? 0));

  double get totalProtein =>
      items.fold(0.0, (sum, item) => sum + (item.proteinG ?? 0));

  double get totalFat =>
      items.fold(0.0, (sum, item) => sum + (item.fatG ?? 0));

  /// 복사본 생성
  MealLog copyWith({
    int? mealLogId,
    DateTime? mealDate,
    String? mealType,
    String? memo,
    DateTime? createdAt,
    int? memberId,
    List<MealItem>? items,
    double? totalCalories,
  }) {
    return MealLog(
      mealLogId: mealLogId ?? this.mealLogId,
      mealDate: mealDate ?? this.mealDate,
      mealType: mealType ?? this.mealType,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      memberId: memberId ?? this.memberId,
      items: items ?? this.items,
      totalCalories: totalCalories ?? this.totalCalories,
    );
  }
}
