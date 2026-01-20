/// 식단 항목 모델 (개별 음식)
/// 
/// DB 테이블: meal_item
/// 매핑 규칙: snake_case(DB) → camelCase(Dart)
/// - meal_item_id (INT PK) → mealItemId
/// - meal_log_id (INT FK) → mealLogId
/// - food_name (VARCHAR) → foodName
/// - calories_kcal, carbohydrates_g, protein_g, fat_g (DECIMAL) → caloriesKcal, carbohydratesG, proteinG, fatG
/// - sugar_g, sodium_mg (DECIMAL) → sugarG, sodiumMg
/// - created_at (TIMESTAMP) → createdAt
class MealItem {
  final int? mealItemId;
  final int mealLogId;
  final String foodName;
  final double? caloriesKcal;
  final double? carbohydratesG;
  final double? proteinG;
  final double? fatG;
  final double? sugarG;
  final double? sodiumMg;
  final DateTime? createdAt;

  MealItem({
    this.mealItemId,
    required this.mealLogId,
    required this.foodName,
    this.caloriesKcal,
    this.carbohydratesG,
    this.proteinG,
    this.fatG,
    this.sugarG,
    this.sodiumMg,
    this.createdAt,
  });

  /// JSON to MealItem
  factory MealItem.fromJson(Map<String, dynamic> json) {
    return MealItem(
      mealItemId: json['meal_item_id'] as int?,
      mealLogId: json['meal_log_id'] as int,
      foodName: json['food_name'] as String,
      caloriesKcal: json['calories_kcal'] != null
          ? (json['calories_kcal'] as num).toDouble()
          : null,
      carbohydratesG: json['carbohydrates_g'] != null
          ? (json['carbohydrates_g'] as num).toDouble()
          : null,
      proteinG: json['protein_g'] != null
          ? (json['protein_g'] as num).toDouble()
          : null,
      fatG: json['fat_g'] != null
          ? (json['fat_g'] as num).toDouble()
          : null,
        sugarG: json['sugar_g'] != null
          ? (json['sugar_g'] as num).toDouble()
          : null,
        sodiumMg: json['sodium_mg'] != null
          ? (json['sodium_mg'] as num).toDouble()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// MealItem to JSON
  Map<String, dynamic> toJson() {
    return {
      if (mealItemId != null) 'meal_item_id': mealItemId,
      'meal_log_id': mealLogId,
      'food_name': foodName,
      if (caloriesKcal != null) 'calories_kcal': caloriesKcal,
      if (carbohydratesG != null) 'carbohydrates_g': carbohydratesG,
      if (proteinG != null) 'protein_g': proteinG,
      if (fatG != null) 'fat_g': fatG,
      if (sugarG != null) 'sugar_g': sugarG,
      if (sodiumMg != null) 'sodium_mg': sodiumMg,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  /// 복사본 생성
  MealItem copyWith({
    int? mealItemId,
    int? mealLogId,
    String? foodName,
    double? caloriesKcal,
    double? carbohydratesG,
    double? proteinG,
    double? fatG,
    double? sugarG,
    double? sodiumMg,
    DateTime? createdAt,
  }) {
    return MealItem(
      mealItemId: mealItemId ?? this.mealItemId,
      mealLogId: mealLogId ?? this.mealLogId,
      foodName: foodName ?? this.foodName,
      caloriesKcal: caloriesKcal ?? this.caloriesKcal,
      carbohydratesG: carbohydratesG ?? this.carbohydratesG,
      proteinG: proteinG ?? this.proteinG,
      fatG: fatG ?? this.fatG,
      sugarG: sugarG ?? this.sugarG,
      sodiumMg: sodiumMg ?? this.sodiumMg,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
