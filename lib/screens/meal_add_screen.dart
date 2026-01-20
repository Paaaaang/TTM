/// 식단 추가 화면
/// 사용자가 식사 정보를 추가할 수 있는 화면
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ttm/services/meal_service.dart';
import 'package:ttm/services/auth_service.dart';
import 'package:ttm/models/meal_log.dart';
import 'package:ttm/models/meal_item.dart';

/// 식품 항목 모델
class FoodItem {
  final String name;
  final int calories;
  final String category;
  final double grams; // 기본 제공량 (g)
  final double carbs; // 탄수화물 (g)
  final double protein; // 단백질 (g)
  final double fat; // 지방 (g)

  FoodItem({
    required this.name,
    required this.calories,
    required this.category,
    this.grams = 100.0,
    this.carbs = 0.0,
    this.protein = 0.0,
    this.fat = 0.0,
  });

  // 수량 배수 적용
  FoodItem copyWithQuantity(int quantity) {
    return FoodItem(
      name: name,
      calories: (calories * quantity).round(),
      category: category,
      grams: grams * quantity,
      carbs: carbs * quantity,
      protein: protein * quantity,
      fat: fat * quantity,
    );
  }
}

/// 선택된 음식 항목 (수량 포함)
class SelectedFoodItem {
  final FoodItem food;
  int quantity;

  SelectedFoodItem({
    required this.food,
    this.quantity = 1,
  });

  int get totalCalories => (food.calories * quantity).round();
  double get totalGrams => food.grams * quantity;
  double get totalCarbs => food.carbs * quantity;
  double get totalProtein => food.protein * quantity;
  double get totalFat => food.fat * quantity;
}

/// 식단 추가 화면 위젯
class MealAddScreen extends StatefulWidget {
  final DateTime? selectedDate; // 선택된 날짜
  final String? mealType; // 전달받은 식사 유형
  
  const MealAddScreen({
    Key? key,
    this.selectedDate,
    this.mealType,
  }) : super(key: key);

  @override
  State<MealAddScreen> createState() => _MealAddScreenState();
}

class _MealAddScreenState extends State<MealAddScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MealService _mealService = MealService();
  final AuthService _authService = AuthService();
  late String _selectedMealType; // 아침, 점심, 저녁, 간식
  late DateTime _mealDate; // 식단 날짜
  String _searchQuery = '';
  String? _selectedCategory; // 선택된 카테고리 (null이면 전체)
  final List<SelectedFoodItem> _selectedFoods = [];
  bool _isSaving = false;
  Timer? _debounce; // 검색 디바운싱용
  Map<String, List<FoodItem>>? _cachedGroupedFoods; // 캐시
  
  @override
  void initState() {
    super.initState();
    // 전달받은 날짜 또는 오늘 날짜 사용
    _mealDate = widget.selectedDate ?? DateTime.now();
    // 전달받은 식사 유형 또는 기본값 '아침' 사용
    _selectedMealType = widget.mealType ?? '아침';
  }

// 음식 데이터베이스 (총 400개)
  final List<FoodItem> _foodDatabase = [
    FoodItem(name: '쌀밥', calories: 334, category: '밥류', grams: 210, carbs: 73.7, protein: 5.8, fat: 0.4),
    FoodItem(name: '기타잡곡밥', calories: 302, category: '밥류', grams: 200, carbs: 65.5, protein: 6.7, fat: 0.7),
    FoodItem(name: '콩밥', calories: 322, category: '밥류', grams: 200, carbs: 65.8, protein: 8.4, fat: 1.7),
    FoodItem(name: '보리밥', calories: 316, category: '밥류', grams: 200, carbs: 70.6, protein: 5.5, fat: 0.1),
    FoodItem(name: '돌솥밥', calories: 528, category: '밥류', grams: 350, carbs: 101.8, protein: 10.2, fat: 8.3),
    FoodItem(name: '현미밥', calories: 351, category: '밥류', grams: 230, carbs: 77.9, protein: 6.7, fat: 1.1),
    FoodItem(name: '흑미밥', calories: 318, category: '밥류', grams: 200, carbs: 70.3, protein: 5.4, fat: 0.4),
    FoodItem(name: '감자밥', calories: 308, category: '밥류', grams: 200, carbs: 68.6, protein: 5.7, fat: 0.1),
    FoodItem(name: '곤드레밥', calories: 506, category: '밥류', grams: 350, carbs: 108.1, protein: 14.1, fat: 8.4),
    FoodItem(name: '김치볶음밥', calories: 656, category: '밥류', grams: 500, carbs: 79.3, protein: 8.7, fat: 5.1),
    FoodItem(name: '주먹밥', calories: 209, category: '밥류', grams: 150, carbs: 36.2, protein: 6.7, fat: 3.5),
    FoodItem(name: '볶음밥', calories: 687, category: '밥류', grams: 400, carbs: 100.3, protein: 24.5, fat: 19.3),
    FoodItem(name: '일반비빔밥', calories: 702, category: '밥류', grams: 500, carbs: 95.7, protein: 22.6, fat: 25.3),
    FoodItem(name: '전주비빔밥', calories: 662, category: '밥류', grams: 450, carbs: 93.0, protein: 15.8, fat: 13.0),
    FoodItem(name: '삼선볶음밥', calories: 683, category: '밥류', grams: 400, carbs: 113.4, protein: 19.3, fat: 16.8),
    FoodItem(name: '새우볶음밥', calories: 634, category: '밥류', grams: 400, carbs: 91.6, protein: 24.1, fat: 17.9),
    FoodItem(name: '알밥', calories: 606, category: '밥류', grams: 400, carbs: 92.1, protein: 15.2, fat: 3.5),
    FoodItem(name: '산채비빔밥 ', calories: 495, category: '밥류', grams: 400, carbs: 89.7, protein: 10.7, fat: 11.0),
    FoodItem(name: '오므라이스', calories: 684, category: '기타', grams: 450, carbs: 101.6, protein: 23.1, fat: 19.8),
    FoodItem(name: '육회비빔밥', calories: 661, category: '밥류', grams: 450, carbs: 91.7, protein: 32.0, fat: 17.5),
    FoodItem(name: '해물볶음밥', calories: 659, category: '밥류', grams: 400, carbs: 85.2, protein: 22.7, fat: 23.7),
    FoodItem(name: '열무비빔밥', calories: 445, category: '밥류', grams: 400, carbs: 90.0, protein: 13.0, fat: 3.2),
    FoodItem(name: '불고기덮밥', calories: 699, category: '밥류', grams: 500, carbs: 92.1, protein: 29.3, fat: 21.4),
    FoodItem(name: '소고기국밥', calories: 331, category: '밥류', grams: 700, carbs: 54.9, protein: 16.0, fat: 4.7),
    FoodItem(name: '송이덮밥', calories: 600, category: '밥류', grams: 600, carbs: 103.6, protein: 16.3, fat: 14.4),
    FoodItem(name: '오징어덮밥', calories: 693, category: '밥류', grams: 500, carbs: 83.4, protein: 40.6, fat: 20.9),
    FoodItem(name: '자장밥', calories: 729, category: '밥류', grams: 500, carbs: 98.1, protein: 25.8, fat: 24.9),
    FoodItem(name: '잡채밥', calories: 851, category: '밥류', grams: 650, carbs: 125.7, protein: 21.1, fat: 28.6),
    FoodItem(name: '잡탕밥', calories: 737, category: '밥류', grams: 750, carbs: 100.6, protein: 29.0, fat: 22.5),
    FoodItem(name: '장어덮밥', calories: 671, category: '밥류', grams: 400, carbs: 103.0, protein: 26.1, fat: 19.2),
    FoodItem(name: '제육덮밥', calories: 796, category: '밥류', grams: 500, carbs: 95.8, protein: 37.8, fat: 27.5),
    FoodItem(name: '짬뽕밥', calories: 696, category: '밥류', grams: 900, carbs: 93.4, protein: 41.8, fat: 22.4),
    FoodItem(name: '순대국밥', calories: 690, category: '밥류', grams: 900, carbs: 34.2, protein: 17.3, fat: 16.5),
    FoodItem(name: '카레라이스', calories: 653, category: '기타', grams: 500, carbs: 92.6, protein: 13.4, fat: 10.7),
    FoodItem(name: '전주콩나물국밥', calories: 432, category: '밥류', grams: 900, carbs: 88.7, protein: 12.5, fat: 3.5),
    FoodItem(name: '해물덮밥', calories: 837, category: '밥류', grams: 700, carbs: 100.1, protein: 51.8, fat: 29.0),
    FoodItem(name: '회덮밥', calories: 697, category: '밥류', grams: 500, carbs: 101.8, protein: 43.0, fat: 11.4),
    FoodItem(name: '소머리국밥', calories: 891, category: '밥류', grams: 1100, carbs: 77.1, protein: 48.9, fat: 40.8),
    FoodItem(name: '돼지국밥', calories: 811, category: '밥류', grams: 1200, carbs: 78.3, protein: 56.8, fat: 36.5),
    FoodItem(name: '하이라이스', calories: 477, category: '기타', grams: 360, carbs: 84.6, protein: 7.9, fat: 9.7),
    FoodItem(name: '김치김밥', calories: 377, category: '밥류', grams: 250, carbs: 71.8, protein: 11.4, fat: 4.6),
    FoodItem(name: '농어초밥', calories: 414, category: '밥류', grams: 250, carbs: 74.1, protein: 19.9, fat: 2.4),
    FoodItem(name: '문어초밥', calories: 377, category: '밥류', grams: 250, carbs: 71.8, protein: 16.9, fat: 1.0),
    FoodItem(name: '새우초밥', calories: 395, category: '밥류', grams: 250, carbs: 69.5, protein: 22.7, fat: 1.2),
    FoodItem(name: '새우튀김롤', calories: 572, category: '기타', grams: 300, carbs: 81.5, protein: 21.1, fat: 18.9),
    FoodItem(name: '샐러드김밥', calories: 422, category: '밥류', grams: 250, carbs: 75.8, protein: 12.8, fat: 7.5),
    FoodItem(name: '광어초밥', calories: 471, category: '밥류', grams: 300, carbs: 72.5, protein: 33.7, fat: 3.2),
    FoodItem(name: '소고기김밥', calories: 425, category: '밥류', grams: 250, carbs: 76.1, protein: 14.7, fat: 6.6),
    FoodItem(name: '갈비삼각김밥', calories: 183, category: '밥류', grams: 100, carbs: 32.7, protein: 6.9, fat: 2.6),
    FoodItem(name: '연어롤 ', calories: 518, category: '고기/생선', grams: 300, carbs: 76.1, protein: 20.7, fat: 14.7),
    FoodItem(name: '연어초밥', calories: 451, category: '밥류', grams: 250, carbs: 70.9, protein: 24.9, fat: 5.8),
    FoodItem(name: '유부초밥', calories: 463, category: '밥류', grams: 250, carbs: 78.5, protein: 12.4, fat: 11.2),
    FoodItem(name: '장어초밥', calories: 486, category: '밥류', grams: 400, carbs: 74.8, protein: 16.3, fat: 12.7),
    FoodItem(name: '참치김밥', calories: 401, category: '밥류', grams: 250, carbs: 47.6, protein: 19.8, fat: 14.6),
    FoodItem(name: '참치마요삼각김밥', calories: 189, category: '밥류', grams: 100, carbs: 31.9, protein: 8.1, fat: 2.9),
    FoodItem(name: '치즈김밥 ', calories: 462, category: '밥류', grams: 250, carbs: 77.1, protein: 17.1, fat: 8.8),
    FoodItem(name: '캘리포니아롤', calories: 468, category: '기타', grams: 300, carbs: 81.2, protein: 12.8, fat: 9.7),
    FoodItem(name: '한치초밥', calories: 389, category: '밥류', grams: 250, carbs: 77.3, protein: 13.5, fat: 1.2),
    FoodItem(name: '일반김밥', calories: 348, category: '밥류', grams: 200, carbs: 63.6, protein: 10.3, fat: 5.4),
    FoodItem(name: '간자장', calories: 807, category: '기타', grams: 650, carbs: 121.7, protein: 29.3, fat: 26.4),
    FoodItem(name: '굴짬뽕', calories: 640, category: '면류', grams: 900, carbs: 115.8, protein: 37.4, fat: 7.8),
    FoodItem(name: '기스면', calories: 645, category: '면류', grams: 1000, carbs: 98.3, protein: 43.5, fat: 11.0),
    FoodItem(name: '김치라면', calories: 512, category: '채소/샐러드', grams: 650, carbs: 80.6, protein: 13.0, fat: 20.3),
    FoodItem(name: '김치우동', calories: 512, category: '채소/샐러드', grams: 800, carbs: 99.1, protein: 16.7, fat: 4.7),
    FoodItem(name: '김치말이국수', calories: 310, category: '국/찌개', grams: 600, carbs: 60.8, protein: 10.4, fat: 2.5),
    FoodItem(name: '닭칼국수', calories: 643, category: '국/찌개', grams: 900, carbs: 70.2, protein: 39.9, fat: 19.6),
    FoodItem(name: '들깨칼국수', calories: 442, category: '국/찌개', grams: 600, carbs: 76.7, protein: 17.5, fat: 6.8),
    FoodItem(name: '떡라면', calories: 672, category: '면류', grams: 700, carbs: 121.1, protein: 15.5, fat: 17.6),
    FoodItem(name: '라면', calories: 509, category: '면류', grams: 550, carbs: 83.2, protein: 14.1, fat: 17.7),
    FoodItem(name: '막국수', calories: 566, category: '국/찌개', grams: 550, carbs: 111.3, protein: 26.9, fat: 5.1),
    FoodItem(name: '메밀국수', calories: 588, category: '국/찌개', grams: 600, carbs: 120.1, protein: 25.3, fat: 4.5),
    FoodItem(name: '물냉면', calories: 579, category: '면류', grams: 800, carbs: 96.4, protein: 28.8, fat: 9.8),
    FoodItem(name: '비빔국수', calories: 577, category: '국/찌개', grams: 550, carbs: 114.5, protein: 16.7, fat: 9.5),
    FoodItem(name: '비빔냉면', calories: 594, category: '면류', grams: 550, carbs: 91.5, protein: 23.7, fat: 9.1),
    FoodItem(name: '삼선우동', calories: 692, category: '면류', grams: 1000, carbs: 89.2, protein: 56.2, fat: 10.5),
    FoodItem(name: '삼선자장면', calories: 787, category: '면류', grams: 700, carbs: 111.6, protein: 38.3, fat: 24.7),
    FoodItem(name: '삼선짬뽕', calories: 629, category: '면류', grams: 900, carbs: 89.3, protein: 39.2, fat: 13.5),
    FoodItem(name: '수제비', calories: 622, category: '기타', grams: 800, carbs: 99.2, protein: 38.5, fat: 6.5),
    FoodItem(name: '쌀국수', calories: 321, category: '국/찌개', grams: 600, carbs: 46.2, protein: 21.8, fat: 5.8),
    FoodItem(name: '열무김치국수', calories: 488, category: '국/찌개', grams: 800, carbs: 81.6, protein: 21.9, fat: 8.2),
    FoodItem(name: '오일소스스파게티', calories: 626, category: '음료', grams: 400, carbs: 99.2, protein: 14.7, fat: 16.6),
    FoodItem(name: '일식우동', calories: 420, category: '면류', grams: 700, carbs: 81.2, protein: 16.9, fat: 1.7),
    FoodItem(name: '볶음우동', calories: 377, category: '면류', grams: 300, carbs: 62.3, protein: 9.6, fat: 10.8),
    FoodItem(name: '자장면', calories: 760, category: '면류', grams: 650, carbs: 134.3, protein: 15.7, fat: 23.2),
    FoodItem(name: '잔치국수', calories: 564, category: '국/찌개', grams: 700, carbs: 104.7, protein: 20.3, fat: 6.2),
    FoodItem(name: '짬뽕', calories: 650, category: '면류', grams: 1000, carbs: 118.5, protein: 25.5, fat: 13.5),
    FoodItem(name: '짬뽕라면', calories: 633, category: '면류', grams: 750, carbs: 88.8, protein: 31.4, fat: 24.6),
    FoodItem(name: '쫄면', calories: 622, category: '면류', grams: 450, carbs: 110.9, protein: 12.4, fat: 6.9),
    FoodItem(name: '치즈라면', calories: 598, category: '간식', grams: 600, carbs: 83.5, protein: 23.3, fat: 23.3),
    FoodItem(name: '콩국수', calories: 623, category: '국/찌개', grams: 800, carbs: 67.1, protein: 47.8, fat: 20.4),
    FoodItem(name: '크림소스스파게티', calories: 825, category: '음료', grams: 400, carbs: 85.9, protein: 19.4, fat: 45.4),
    FoodItem(name: '토마토소스스파게티', calories: 642, category: '음료', grams: 500, carbs: 102.1, protein: 20.2, fat: 17.4),
    FoodItem(name: '해물칼국수', calories: 621, category: '국/찌개', grams: 900, carbs: 124.2, protein: 24.9, fat: 4.0),
    FoodItem(name: '회냉면', calories: 638, category: '면류', grams: 550, carbs: 131.9, protein: 20.2, fat: 8.8),
    FoodItem(name: '떡국', calories: 714, category: '국/찌개', grams: 800, carbs: 144.0, protein: 21.9, fat: 5.4),
    FoodItem(name: '떡만둣국', calories: 625, category: '국/찌개', grams: 700, carbs: 114.0, protein: 22.7, fat: 9.4),
    FoodItem(name: '짜장라면', calories: 409, category: '면류', grams: 250, carbs: 63.8, protein: 12.0, fat: 14.9),
    FoodItem(name: '고기만두', calories: 454, category: '고기/생선', grams: 250, carbs: 55.3, protein: 18.7, fat: 18.2),
    FoodItem(name: '군만두', calories: 684, category: '기타', grams: 250, carbs: 76.2, protein: 19.8, fat: 31.2),
    FoodItem(name: '김치만두', calories: 424, category: '채소/샐러드', grams: 250, carbs: 60.8, protein: 18.4, fat: 13.1),
    FoodItem(name: '물만두', calories: 158, category: '기타', grams: 120, carbs: 20.5, protein: 5.9, fat: 5.8),
    FoodItem(name: '만둣국', calories: 432, category: '국/찌개', grams: 700, carbs: 53.3, protein: 19.2, fat: 14.9),
    FoodItem(name: '게살죽', calories: 554, category: '밥류', grams: 800, carbs: 103.6, protein: 18.1, fat: 7.6),
    FoodItem(name: '깨죽', calories: 505, category: '밥류', grams: 800, carbs: 71.1, protein: 13.4, fat: 18.9),
    FoodItem(name: '닭죽', calories: 1181, category: '밥류', grams: 1000, carbs: 92.5, protein: 75.9, fat: 48.2),
    FoodItem(name: '소고기버섯죽', calories: 573, category: '밥류', grams: 800, carbs: 102.9, protein: 20.5, fat: 6.5),
    FoodItem(name: '어죽', calories: 559, category: '밥류', grams: 800, carbs: 90.5, protein: 15.5, fat: 6.1),
    FoodItem(name: '잣죽', calories: 872, category: '밥류', grams: 700, carbs: 153.8, protein: 15.8, fat: 20.3),
    FoodItem(name: '전복죽', calories: 587, category: '밥류', grams: 800, carbs: 105.0, protein: 14.6, fat: 11.5),
    FoodItem(name: '참치죽', calories: 658, category: '밥류', grams: 800, carbs: 105.9, protein: 26.1, fat: 13.9),
    FoodItem(name: '채소죽', calories: 514, category: '밥류', grams: 800, carbs: 100.8, protein: 11.9, fat: 5.1),
    FoodItem(name: '팥죽', calories: 482, category: '밥류', grams: 600, carbs: 100.7, protein: 20.6, fat: 0.6),
    FoodItem(name: '호박죽', calories: 430, category: '밥류', grams: 600, carbs: 111.4, protein: 8.1, fat: 0.7),
    FoodItem(name: '콘스프', calories: 280, category: '기타', grams: 400, carbs: 35.4, protein: 5.8, fat: 14.0),
    FoodItem(name: '토마토스프', calories: 382, category: '기타', grams: 400, carbs: 12.4, protein: 18.2, fat: 25.4),
    FoodItem(name: '굴국', calories: 194, category: '국/찌개', grams: 450, carbs: 11.4, protein: 22.8, fat: 8.6),
    FoodItem(name: '김치국', calories: 85, category: '국/찌개', grams: 450, carbs: 13.0, protein: 6.0, fat: 3.4),
    FoodItem(name: '달걀국', calories: 193, category: '국/찌개', grams: 450, carbs: 5.4, protein: 16.2, fat: 11.1),
    FoodItem(name: '감자국', calories: 220, category: '국/찌개', grams: 700, carbs: 37.0, protein: 17.0, fat: 2.2),
    FoodItem(name: '미역국', calories: 50, category: '국/찌개', grams: 500, carbs: 4.7, protein: 2.7, fat: 4.3),
    FoodItem(name: '바지락조개국', calories: 159, category: '국/찌개', grams: 550, carbs: 8.5, protein: 25.8, fat: 1.8),
    FoodItem(name: '소고기무국', calories: 125, category: '국/찌개', grams: 400, carbs: 8.1, protein: 13.5, fat: 4.7),
    FoodItem(name: '소고기미역국', calories: 154, category: '국/찌개', grams: 650, carbs: 6.9, protein: 20.2, fat: 6.8),
    FoodItem(name: '순대국', calories: 550, category: '국/찌개', grams: 800, carbs: 22.8, protein: 41.2, fat: 32.9),
    FoodItem(name: '어묵국', calories: 252, category: '국/찌개', grams: 600, carbs: 37.2, protein: 22.9, fat: 4.2),
    FoodItem(name: '오징어국', calories: 169, category: '국/찌개', grams: 500, carbs: 10.6, protein: 27.7, fat: 2.4),
    FoodItem(name: '토란국', calories: 462, category: '국/찌개', grams: 250, carbs: 85.2, protein: 23.9, fat: 7.1),
    FoodItem(name: '탕국', calories: 94, category: '국/찌개', grams: 250, carbs: 2.6, protein: 12.1, fat: 4.3),
    FoodItem(name: '홍합미역국', calories: 168, category: '국/찌개', grams: 650, carbs: 14.1, protein: 20.0, fat: 6.4),
    FoodItem(name: '황태해장국', calories: 184, category: '국/찌개', grams: 600, carbs: 6.4, protein: 25.2, fat: 7.2),
    FoodItem(name: '근대된장국', calories: 109, category: '국/찌개', grams: 450, carbs: 8.1, protein: 15.3, fat: 3.2),
    FoodItem(name: '미소된장국', calories: 37, category: '국/찌개', grams: 150, carbs: 1.7, protein: 4.1, fat: 1.7),
    FoodItem(name: '배추된장국', calories: 121, category: '국/찌개', grams: 700, carbs: 11.0, protein: 14.0, fat: 3.6),
    FoodItem(name: '뼈다귀해장국 ', calories: 715, category: '국/찌개', grams: 1000, carbs: 29.7, protein: 53.6, fat: 45.4),
    FoodItem(name: '선지(해장)국', calories: 314, category: '국/찌개', grams: 1000, carbs: 22.3, protein: 48.1, fat: 5.0),
    FoodItem(name: '콩나물국', calories: 22, category: '국/찌개', grams: 400, carbs: 1.3, protein: 1.8, fat: 1.4),
    FoodItem(name: '시금치된장국', calories: 121, category: '국/찌개', grams: 400, carbs: 9.9, protein: 16.7, fat: 3.4),
    FoodItem(name: '시래기된장국', calories: 99, category: '국/찌개', grams: 450, carbs: 10.7, protein: 10.0, fat: 2.5),
    FoodItem(name: '쑥된장국', calories: 117, category: '국/찌개', grams: 450, carbs: 17.2, protein: 13.2, fat: 2.6),
    FoodItem(name: '아욱된장국', calories: 103, category: '국/찌개', grams: 450, carbs: 10.0, protein: 12.0, fat: 2.9),
    FoodItem(name: '우거지된장국', calories: 85, category: '국/찌개', grams: 450, carbs: 13.7, protein: 6.4, fat: 1.8),
    FoodItem(name: '우거지해장국', calories: 158, category: '국/찌개', grams: 600, carbs: 14.9, protein: 14.2, fat: 5.7),
    FoodItem(name: '우렁된장국', calories: 245, category: '국/찌개', grams: 500, carbs: 21.2, protein: 24.7, fat: 7.0),
    FoodItem(name: '갈비탕', calories: 240, category: '국/찌개', grams: 600, carbs: 8.2, protein: 18.7, fat: 14.3),
    FoodItem(name: '감자탕', calories: 963, category: '국/찌개', grams: 900, carbs: 49.6, protein: 60.6, fat: 58.3),
    FoodItem(name: '곰탕', calories: 181, category: '국/찌개', grams: 300, carbs: 15.5, protein: 16.6, fat: 5.4),
    FoodItem(name: '매운탕', calories: 402, category: '국/찌개', grams: 600, carbs: 18.8, protein: 37.2, fat: 21.6),
    FoodItem(name: '꼬리곰탕', calories: 750, category: '국/찌개', grams: 700, carbs: 10.9, protein: 54.9, fat: 52.8),
    FoodItem(name: '꽃게탕', calories: 240, category: '국/찌개', grams: 600, carbs: 20.8, protein: 31.7, fat: 5.5),
    FoodItem(name: '낙지탕', calories: 186, category: '국/찌개', grams: 600, carbs: 11.8, protein: 29.2, fat: 2.7),
    FoodItem(name: '내장탕', calories: 549, category: '국/찌개', grams: 700, carbs: 13.7, protein: 57.0, fat: 31.5),
    FoodItem(name: '닭곰탕', calories: 527, category: '국/찌개', grams: 650, carbs: 15.4, protein: 58.9, fat: 24.1),
    FoodItem(name: '닭볶음탕', calories: 371, category: '국/찌개', grams: 300, carbs: 19.2, protein: 33.8, fat: 17.3),
    FoodItem(name: '지리탕', calories: 260, category: '국/찌개', grams: 600, carbs: 10.5, protein: 38.3, fat: 8.4),
    FoodItem(name: '도가니탕', calories: 563, category: '국/찌개', grams: 800, carbs: 5.6, protein: 54.6, fat: 34.8),
    FoodItem(name: '삼계탕', calories: 881, category: '국/찌개', grams: 1000, carbs: 44.1, protein: 76.6, fat: 40.6),
    FoodItem(name: '설렁탕', calories: 422, category: '국/찌개', grams: 600, carbs: 10.9, protein: 52.7, fat: 18.2),
    FoodItem(name: '알탕', calories: 424, category: '국/찌개', grams: 700, carbs: 49.5, protein: 49.2, fat: 7.0),
    FoodItem(name: '연포탕', calories: 541, category: '국/찌개', grams: 1000, carbs: 21.6, protein: 91.7, fat: 9.2),
    FoodItem(name: '오리탕', calories: 480, category: '국/찌개', grams: 600, carbs: 24.2, protein: 43.2, fat: 21.6),
    FoodItem(name: '추어탕', calories: 338, category: '국/찌개', grams: 700, carbs: 24.4, protein: 37.4, fat: 11.5),
    FoodItem(name: '해물탕', calories: 272, category: '국/찌개', grams: 600, carbs: 19.6, protein: 41.7, fat: 3.4),
    FoodItem(name: '닭개장', calories: 317, category: '고기/생선', grams: 700, carbs: 19.2, protein: 33.7, fat: 14.9),
    FoodItem(name: '육개장', calories: 137, category: '기타', grams: 440, carbs: 11.6, protein: 13.4, fat: 5.9),
    FoodItem(name: '뼈해장국', calories: 692, category: '국/찌개', grams: 1000, carbs: 25.4, protein: 67.9, fat: 37.2),
    FoodItem(name: '미역오이냉국', calories: 77, category: '국/찌개', grams: 450, carbs: 19.7, protein: 5.6, fat: 1.4),
    FoodItem(name: '고등어찌개', calories: 605, category: '국/찌개', grams: 600, carbs: 32.0, protein: 59.2, fat: 28.2),
    FoodItem(name: '꽁치찌개', calories: 356, category: '국/찌개', grams: 300, carbs: 14.5, protein: 29.5, fat: 20.7),
    FoodItem(name: '동태찌개', calories: 369, category: '국/찌개', grams: 800, carbs: 18.9, protein: 59.6, fat: 7.8),
    FoodItem(name: '부대찌개', calories: 525, category: '국/찌개', grams: 600, carbs: 46.8, protein: 27.7, fat: 28.5),
    FoodItem(name: '된장찌개', calories: 147, category: '국/찌개', grams: 400, carbs: 16.0, protein: 11.7, fat: 5.3),
    FoodItem(name: '청국장찌개', calories: 275, category: '국/찌개', grams: 400, carbs: 15.0, protein: 25.8, fat: 14.4),
    FoodItem(name: '두부전골', calories: 315, category: '국/찌개', grams: 500, carbs: 16.2, protein: 29.1, fat: 19.2),
    FoodItem(name: '곱창전골', calories: 532, category: '국/찌개', grams: 600, carbs: 26.9, protein: 38.3, fat: 34.7),
    FoodItem(name: '소고기전골', calories: 203, category: '국/찌개', grams: 300, carbs: 16.5, protein: 19.5, fat: 7.5),
    FoodItem(name: '국수전골', calories: 643, category: '국/찌개', grams: 400, carbs: 66.9, protein: 45.3, fat: 22.4),
    FoodItem(name: '돼지고기김치찌개', calories: 246, category: '국/찌개', grams: 400, carbs: 9.3, protein: 15.5, fat: 18.3),
    FoodItem(name: '버섯찌개', calories: 171, category: '국/찌개', grams: 400, carbs: 15.3, protein: 16.6, fat: 7.5),
    FoodItem(name: '참치김치찌개', calories: 193, category: '국/찌개', grams: 400, carbs: 13.3, protein: 16.9, fat: 10.9),
    FoodItem(name: '순두부찌개', calories: 198, category: '국/찌개', grams: 400, carbs: 8.8, protein: 14.7, fat: 14.0),
    FoodItem(name: '콩비지찌개', calories: 248, category: '국/찌개', grams: 400, carbs: 24.5, protein: 16.0, fat: 12.8),
    FoodItem(name: '햄김치찌개', calories: 190, category: '국/찌개', grams: 300, carbs: 15.4, protein: 11.6, fat: 10.7),
    FoodItem(name: '호박찌개', calories: 98, category: '국/찌개', grams: 300, carbs: 12.7, protein: 7.8, fat: 2.3),
    FoodItem(name: '고추장찌개', calories: 263, category: '국/찌개', grams: 500, carbs: 20.1, protein: 25.6, fat: 12.3),
    FoodItem(name: '대구찜', calories: 372, category: '고기/생선', grams: 500, carbs: 26.4, protein: 54.1, fat: 8.4),
    FoodItem(name: '도미찜', calories: 126, category: '기타', grams: 100, carbs: 0.8, protein: 21.0, fat: 3.7),
    FoodItem(name: '문어숙회', calories: 67, category: '기타', grams: 80, carbs: 0.2, protein: 14.1, fat: 0.7),
    FoodItem(name: '아귀찜', calories: 310, category: '기타', grams: 400, carbs: 17.6, protein: 48.8, fat: 6.7),
    FoodItem(name: '조기찜', calories: 185, category: '고기/생선', grams: 100, carbs: 1.8, protein: 22.3, fat: 9.2),
    FoodItem(name: '참꼬막', calories: 89, category: '기타', grams: 80, carbs: 4.9, protein: 13.0, fat: 2.2),
    FoodItem(name: '해물찜', calories: 397, category: '기타', grams: 500, carbs: 36.0, protein: 50.3, fat: 8.9),
    FoodItem(name: '소갈비찜', calories: 500, category: '고기/생선', grams: 250, carbs: 11.3, protein: 42.5, fat: 29.2),
    FoodItem(name: '돼지갈비찜', calories: 249, category: '고기/생선', grams: 170, carbs: 8.8, protein: 20.6, fat: 14.4),
    FoodItem(name: '돼지고기수육', calories: 1218, category: '고기/생선', grams: 300, carbs: 8.7, protein: 61.5, fat: 99.5),
    FoodItem(name: '찜닭', calories: 1358, category: '고기/생선', grams: 1500, carbs: 140.6, protein: 114.9, fat: 36.5),
    FoodItem(name: '족발', calories: 381, category: '기타', grams: 150, carbs: 32.3, protein: 26.0, fat: 16.6),
    FoodItem(name: '달걀찜', calories: 190, category: '고기/생선', grams: 250, carbs: 4.8, protein: 16.2, fat: 10.9),
    FoodItem(name: '닭갈비', calories: 562, category: '고기/생선', grams: 300, carbs: 24.5, protein: 52.3, fat: 28.9),
    FoodItem(name: '닭꼬치', calories: 177, category: '고기/생선', grams: 70, carbs: 12.9, protein: 12.3, fat: 7.9),
    FoodItem(name: '돼지갈비', calories: 248, category: '고기/생선', grams: 100, carbs: 7.6, protein: 19.9, fat: 14.7),
    FoodItem(name: '떡갈비', calories: 762, category: '고기/생선', grams: 250, carbs: 26.6, protein: 43.1, fat: 51.6),
    FoodItem(name: '불고기', calories: 386, category: '고기/생선', grams: 150, carbs: 13.1, protein: 32.9, fat: 21.8),
    FoodItem(name: '소곱창구이', calories: 639, category: '기타', grams: 150, carbs: 6.5, protein: 35.6, fat: 51.7),
    FoodItem(name: '소양념갈비구이', calories: 986, category: '고기/생선', grams: 300, carbs: 27.7, protein: 62.0, fat: 66.5),
    FoodItem(name: '소불고기', calories: 174, category: '고기/생선', grams: 200, carbs: 19.6, protein: 14.2, fat: 4.7),
    FoodItem(name: '양념왕갈비', calories: 485, category: '고기/생선', grams: 150, carbs: 15.0, protein: 29.3, fat: 33.7),
    FoodItem(name: '햄버거스테이크', calories: 436, category: '기타', grams: 200, carbs: 21.4, protein: 24.9, fat: 28.1),
    FoodItem(name: '훈제오리', calories: 789, category: '고기/생선', grams: 250, carbs: 11.8, protein: 38.2, fat: 64.7),
    FoodItem(name: '치킨데리야끼', calories: 692, category: '고기/생선', grams: 340, carbs: 50.7, protein: 47.3, fat: 32.2),
    FoodItem(name: '치킨윙', calories: 219, category: '고기/생선', grams: 100, carbs: 10.0, protein: 11.4, fat: 14.2),
    FoodItem(name: '더덕구이', calories: 183, category: '기타', grams: 100, carbs: 31.8, protein: 5.8, fat: 5.6),
    FoodItem(name: '양배추구이', calories: 60, category: '기타', grams: 100, carbs: 7.6, protein: 2.7, fat: 2.7),
    FoodItem(name: '두부구이', calories: 90, category: '기타', grams: 100, carbs: 1.5, protein: 9.4, fat: 6.3),
    FoodItem(name: '삼치구이', calories: 355, category: '고기/생선', grams: 200, carbs: 8.5, protein: 37.8, fat: 18.0),
    FoodItem(name: '가자미전', calories: 220, category: '고기/생선', grams: 150, carbs: 6.7, protein: 30.0, fat: 7.1),
    FoodItem(name: '굴전', calories: 192, category: '기타', grams: 100, carbs: 13.9, protein: 12.6, fat: 9.1),
    FoodItem(name: '동태전', calories: 265, category: '기타', grams: 150, carbs: 11.5, protein: 19.9, fat: 16.1),
    FoodItem(name: '해물파전', calories: 267, category: '기타', grams: 150, carbs: 27.7, protein: 12.9, fat: 12.6),
    FoodItem(name: '동그랑땡', calories: 312, category: '기타', grams: 150, carbs: 14.7, protein: 19.7, fat: 18.7),
    FoodItem(name: '햄부침', calories: 232, category: '기타', grams: 100, carbs: 9.7, protein: 13.1, fat: 15.5),
    FoodItem(name: '육전', calories: 197, category: '기타', grams: 100, carbs: 6.7, protein: 19.6, fat: 9.5),
    FoodItem(name: '감자전', calories: 366, category: '기타', grams: 200, carbs: 53.8, protein: 9.7, fat: 13.6),
    FoodItem(name: '고추전', calories: 261, category: '기타', grams: 150, carbs: 17.8, protein: 13.9, fat: 14.9),
    FoodItem(name: '김치전', calories: 285, category: '채소/샐러드', grams: 150, carbs: 32.1, protein: 13.2, fat: 12.5),
    FoodItem(name: '깻잎전', calories: 357, category: '기타', grams: 150, carbs: 16.7, protein: 18.3, fat: 24.6),
    FoodItem(name: '녹두빈대떡', calories: 200, category: '기타', grams: 100, carbs: 18.6, protein: 10.0, fat: 8.3),
    FoodItem(name: '미나리전', calories: 215, category: '채소/샐러드', grams: 150, carbs: 30.1, protein: 6.1, fat: 8.6),
    FoodItem(name: '배추전', calories: 241, category: '기타', grams: 150, carbs: 32.5, protein: 6.4, fat: 10.5),
    FoodItem(name: '버섯전', calories: 239, category: '기타', grams: 150, carbs: 18.6, protein: 11.9, fat: 12.9),
    FoodItem(name: '부추전', calories: 241, category: '기타', grams: 150, carbs: 32.0, protein: 7.1, fat: 9.5),
    FoodItem(name: '야채전', calories: 194, category: '기타', grams: 100, carbs: 25.0, protein: 4.9, fat: 8.8),
    FoodItem(name: '파전', calories: 280, category: '기타', grams: 150, carbs: 37.5, protein: 7.7, fat: 12.0),
    FoodItem(name: '호박부침개', calories: 130, category: '기타', grams: 100, carbs: 8.7, protein: 3.4, fat: 9.2),
    FoodItem(name: '호박전', calories: 215, category: '기타', grams: 150, carbs: 16.6, protein: 6.6, fat: 14.4),
    FoodItem(name: '달걀말이', calories: 172, category: '고기/생선', grams: 100, carbs: 4.7, protein: 12.0, fat: 11.2),
    FoodItem(name: '두부부침', calories: 134, category: '기타', grams: 100, carbs: 4.3, protein: 9.9, fat: 8.8),
    FoodItem(name: '두부전', calories: 253, category: '기타', grams: 150, carbs: 8.1, protein: 18.7, fat: 18.0),
    FoodItem(name: '건새우볶음', calories: 69, category: '기타', grams: 20, carbs: 4.8, protein: 7.2, fat: 2.3),
    FoodItem(name: '낙지볶음', calories: 180, category: '기타', grams: 200, carbs: 23.5, protein: 17.9, fat: 3.0),
    FoodItem(name: '멸치볶음', calories: 69, category: '기타', grams: 20, carbs: 5.7, protein: 7.0, fat: 2.0),
    FoodItem(name: '어묵볶음', calories: 281, category: '기타', grams: 150, carbs: 36.3, protein: 18.0, fat: 8.1),
    FoodItem(name: '오징어볶음', calories: 243, category: '기타', grams: 200, carbs: 27.4, protein: 20.4, fat: 6.8),
    FoodItem(name: '오징어채볶음', calories: 55, category: '기타', grams: 20, carbs: 7.0, protein: 5.4, fat: 0.7),
    FoodItem(name: '주꾸미볶음', calories: 211, category: '기타', grams: 200, carbs: 21.7, protein: 20.2, fat: 6.1),
    FoodItem(name: '해물볶음', calories: 420, category: '기타', grams: 400, carbs: 36.5, protein: 37.5, fat: 15.3),
    FoodItem(name: '감자볶음', calories: 57, category: '기타', grams: 50, carbs: 8.2, protein: 1.3, fat: 2.5),
    FoodItem(name: '김치볶음', calories: 189, category: '채소/샐러드', grams: 200, carbs: 21.8, protein: 5.3, fat: 12.1),
    FoodItem(name: '깻잎나물볶음', calories: 212, category: '채소/샐러드', grams: 200, carbs: 17.3, protein: 8.0, fat: 16.4),
    FoodItem(name: '느타리버섯볶음', calories: 133, category: '기타', grams: 150, carbs: 14.2, protein: 4.4, fat: 8.9),
    FoodItem(name: '두부김치', calories: 292, category: '채소/샐러드', grams: 250, carbs: 13.8, protein: 19.1, fat: 21.3),
    FoodItem(name: '머위나물볶음', calories: 102, category: '채소/샐러드', grams: 150, carbs: 7.7, protein: 4.3, fat: 8.0),
    FoodItem(name: '양송이버섯볶음', calories: 132, category: '기타', grams: 150, carbs: 10.6, protein: 5.5, fat: 9.8),
    FoodItem(name: '표고버섯볶음', calories: 143, category: '기타', grams: 150, carbs: 14.3, protein: 4.0, fat: 7.4),
    FoodItem(name: '고추잡채', calories: 264, category: '기타', grams: 200, carbs: 22.1, protein: 12.9, fat: 12.7),
    FoodItem(name: '호박볶음', calories: 29, category: '기타', grams: 50, carbs: 3.1, protein: 0.8, fat: 2.0),
    FoodItem(name: '돼지고기볶음', calories: 353, category: '고기/생선', grams: 200, carbs: 15.3, protein: 25.7, fat: 20.9),
    FoodItem(name: '돼지껍데기볶음', calories: 346, category: '기타', grams: 150, carbs: 22.7, protein: 22.4, fat: 19.2),
    FoodItem(name: '소세지볶음', calories: 476, category: '기타', grams: 200, carbs: 28.8, protein: 17.0, fat: 33.2),
    FoodItem(name: '순대볶음', calories: 579, category: '기타', grams: 400, carbs: 71.0, protein: 17.6, fat: 25.6),
    FoodItem(name: '오리불고기', calories: 559, category: '고기/생선', grams: 250, carbs: 24.5, protein: 38.2, fat: 34.2),
    FoodItem(name: '오삼불고기', calories: 356, category: '고기/생선', grams: 200, carbs: 21.5, protein: 23.3, fat: 20.2),
    FoodItem(name: '떡볶이', calories: 300, category: '기타', grams: 200, carbs: 58.9, protein: 8.7, fat: 3.0),
    FoodItem(name: '라볶이', calories: 266, category: '기타', grams: 200, carbs: 41.1, protein: 8.0, fat: 9.6),
    FoodItem(name: '마파두부', calories: 226, category: '기타', grams: 200, carbs: 11.0, protein: 16.9, fat: 12.0),
    FoodItem(name: '가자미조림', calories: 301, category: '고기/생선', grams: 300, carbs: 20.3, protein: 40.7, fat: 6.9),
    FoodItem(name: '갈치조림', calories: 99, category: '고기/생선', grams: 100, carbs: 5.5, protein: 10.7, fat: 3.9),
    FoodItem(name: '고등어조림', calories: 459, category: '고기/생선', grams: 250, carbs: 11.0, protein: 45.4, fat: 25.4),
    FoodItem(name: '꽁치조림', calories: 280, category: '기타', grams: 150, carbs: 8.4, protein: 22.6, fat: 16.7),
    FoodItem(name: '동태조림', calories: 270, category: '기타', grams: 250, carbs: 16.8, protein: 39.0, fat: 4.1),
    FoodItem(name: '북어조림', calories: 184, category: '기타', grams: 100, carbs: 15.7, protein: 23.9, fat: 3.0),
    FoodItem(name: '조기조림', calories: 378, category: '고기/생선', grams: 300, carbs: 14.2, protein: 41.4, fat: 16.3),
    FoodItem(name: '코다리조림', calories: 146, category: '기타', grams: 100, carbs: 4.6, protein: 18.5, fat: 5.6),
    FoodItem(name: '달걀장조림', calories: 133, category: '고기/생선', grams: 100, carbs: 10.0, protein: 8.8, fat: 6.4),
    FoodItem(name: '메추리알장조림', calories: 205, category: '기타', grams: 100, carbs: 7.4, protein: 12.1, fat: 13.7),
    FoodItem(name: '돼지고기메추리알장조림', calories: 62, category: '고기/생선', grams: 50, carbs: 3.1, protein: 7.6, fat: 2.1),
    FoodItem(name: '소고기메추리알장조림', calories: 61, category: '고기/생선', grams: 50, carbs: 3.4, protein: 6.7, fat: 2.2),
    FoodItem(name: '고추조림', calories: 105, category: '기타', grams: 100, carbs: 14.8, protein: 2.9, fat: 4.2),
    FoodItem(name: '감자조림', calories: 39, category: '기타', grams: 50, carbs: 8.4, protein: 1.6, fat: 0.2),
    FoodItem(name: '우엉조림', calories: 68, category: '기타', grams: 30, carbs: 15.5, protein: 1.1, fat: 0.3),
    FoodItem(name: '알감자조림', calories: 56, category: '기타', grams: 50, carbs: 10.5, protein: 1.4, fat: 1.3),
    FoodItem(name: '(검은)콩조림', calories: 56, category: '기타', grams: 20, carbs: 7.0, protein: 3.8, fat: 2.1),
    FoodItem(name: '콩조림', calories: 59, category: '기타', grams: 20, carbs: 7.8, protein: 3.6, fat: 1.9),
    FoodItem(name: '두부고추장조림', calories: 67, category: '기타', grams: 50, carbs: 4.0, protein: 5.1, fat: 4.0),
    FoodItem(name: '땅콩조림', calories: 80, category: '간식', grams: 20, carbs: 6.5, protein: 2.9, fat: 5.1),
    FoodItem(name: '미꾸라지튀김', calories: 382, category: '기타', grams: 100, carbs: 30.6, protein: 12.7, fat: 22.5),
    FoodItem(name: '새우튀김', calories: 311, category: '기타', grams: 100, carbs: 21.8, protein: 11.8, fat: 19.6),
    FoodItem(name: '생선가스', calories: 646, category: '고기/생선', grams: 200, carbs: 57.4, protein: 24.5, fat: 37.1),
    FoodItem(name: '쥐포튀김', calories: 353, category: '기타', grams: 100, carbs: 38.0, protein: 11.2, fat: 16.5),
    FoodItem(name: '오징어튀김', calories: 308, category: '기타', grams: 100, carbs: 26.0, protein: 13.5, fat: 16.5),
    FoodItem(name: '닭강정', calories: 323, category: '고기/생선', grams: 100, carbs: 24.2, protein: 18.3, fat: 15.6),
    FoodItem(name: '닭튀김', calories: 909, category: '고기/생선', grams: 300, carbs: 45.9, protein: 54.5, fat: 52.3),
    FoodItem(name: '돈가스', calories: 620, category: '기타', grams: 200, carbs: 36.6, protein: 27.8, fat: 39.1),
    FoodItem(name: '모래집튀김', calories: 457, category: '기타', grams: 150, carbs: 31.9, protein: 22.3, fat: 25.9),
    FoodItem(name: '양념치킨', calories: 567, category: '고기/생선', grams: 200, carbs: 38.8, protein: 30.5, fat: 31.1),
    FoodItem(name: '치즈돈가스', calories: 758, category: '간식', grams: 250, carbs: 45.5, protein: 36.0, fat: 46.1),
    FoodItem(name: '치킨가스', calories: 582, category: '고기/생선', grams: 200, carbs: 51.3, protein: 31.0, fat: 28.6),
    FoodItem(name: '탕수육', calories: 454, category: '국/찌개', grams: 200, carbs: 56.5, protein: 17.1, fat: 16.6),
    FoodItem(name: '깐풍기', calories: 585, category: '기타', grams: 200, carbs: 43.4, protein: 27.8, fat: 33.3),
    FoodItem(name: '감자튀김', calories: 462, category: '기타', grams: 150, carbs: 50.1, protein: 6.2, fat: 25.8),
    FoodItem(name: '고구마맛탕', calories: 490, category: '국/찌개', grams: 200, carbs: 90.2, protein: 3.3, fat: 13.5),
    FoodItem(name: '고구마튀김', calories: 241, category: '기타', grams: 100, carbs: 34.1, protein: 3.2, fat: 10.8),
    FoodItem(name: '고추튀김', calories: 198, category: '기타', grams: 100, carbs: 12.7, protein: 6.5, fat: 13.6),
    FoodItem(name: '김말이튀김', calories: 240, category: '기타', grams: 100, carbs: 32.5, protein: 2.2, fat: 12.4),
    FoodItem(name: '채소튀김', calories: 311, category: '기타', grams: 100, carbs: 36.3, protein: 3.0, fat: 18.5),
    FoodItem(name: '노각무침', calories: 81, category: '채소/샐러드', grams: 150, carbs: 16.4, protein: 3.1, fat: 2.1),
    FoodItem(name: '단무지무침', calories: 19, category: '채소/샐러드', grams: 50, carbs: 3.2, protein: 0.5, fat: 0.9),
    FoodItem(name: '달래나물무침', calories: 132, category: '채소/샐러드', grams: 150, carbs: 25.3, protein: 4.8, fat: 3.3),
    FoodItem(name: '더덕무침', calories: 220, category: '채소/샐러드', grams: 150, carbs: 48.4, protein: 4.9, fat: 2.7),
    FoodItem(name: '도라지생채', calories: 165, category: '기타', grams: 150, carbs: 38.6, protein: 4.1, fat: 1.7),
    FoodItem(name: '도토리묵', calories: 43, category: '기타', grams: 100, carbs: 9.9, protein: 0.4, fat: 0.3),
    FoodItem(name: '마늘쫑무침', calories: 38, category: '채소/샐러드', grams: 30, carbs: 9.4, protein: 1.0, fat: 0.3),
    FoodItem(name: '무생채', calories: 73, category: '기타', grams: 150, carbs: 16.0, protein: 2.6, fat: 1.3),
    FoodItem(name: '무말랭이', calories: 39, category: '기타', grams: 30, carbs: 9.6, protein: 1.4, fat: 0.3),
    FoodItem(name: '오이생채', calories: 23, category: '기타', grams: 50, carbs: 4.6, protein: 0.9, fat: 0.5),
    FoodItem(name: '파무침', calories: 124, category: '채소/샐러드', grams: 150, carbs: 19.5, protein: 3.8, fat: 5.4),
    FoodItem(name: '상추겉절이', calories: 130, category: '채소/샐러드', grams: 200, carbs: 18.0, protein: 5.6, fat: 6.2),
    FoodItem(name: '쑥갓나물무침', calories: 94, category: '채소/샐러드', grams: 150, carbs: 8.8, protein: 5.5, fat: 6.5),
    FoodItem(name: '청포묵무침', calories: 157, category: '채소/샐러드', grams: 250, carbs: 19.7, protein: 3.0, fat: 4.2),
    FoodItem(name: '해파리냉채', calories: 87, category: '기타', grams: 150, carbs: 13.8, protein: 6.6, fat: 1.5),
    FoodItem(name: '가지나물', calories: 21, category: '채소/샐러드', grams: 50, carbs: 3.0, protein: 0.7, fat: 1.3),
    FoodItem(name: '고사리나물', calories: 43, category: '채소/샐러드', grams: 50, carbs: 3.8, protein: 2.0, fat: 3.3),
    FoodItem(name: '도라지나물', calories: 54, category: '채소/샐러드', grams: 50, carbs: 5.3, protein: 0.7, fat: 3.8),
    FoodItem(name: '무나물', calories: 34, category: '채소/샐러드', grams: 50, carbs: 3.0, protein: 0.6, fat: 2.6),
    FoodItem(name: '미나리나물', calories: 28, category: '채소/샐러드', grams: 50, carbs: 2.6, protein: 1.0, fat: 2.1),
    FoodItem(name: '숙주나물', calories: 19, category: '채소/샐러드', grams: 50, carbs: 1.6, protein: 1.3, fat: 1.3),
    FoodItem(name: '시금치나물', calories: 37, category: '채소/샐러드', grams: 50, carbs: 3.8, protein: 2.1, fat: 2.4),
    FoodItem(name: '취나물', calories: 72, category: '채소/샐러드', grams: 50, carbs: 3.5, protein: 1.6, fat: 6.7),
    FoodItem(name: '콩나물', calories: 24, category: '채소/샐러드', grams: 50, carbs: 1.1, protein: 1.6, fat: 2.0),
    FoodItem(name: '고구마줄기나물', calories: 30, category: '채소/샐러드', grams: 50, carbs: 3.0, protein: 0.6, fat: 2.2),
    FoodItem(name: '우거지나물무침', calories: 126, category: '채소/샐러드', grams: 150, carbs: 10.3, protein: 5.1, fat: 8.7),
    FoodItem(name: '골뱅이무침', calories: 107, category: '채소/샐러드', grams: 100, carbs: 15.6, protein: 7.9, fat: 2.3),
    FoodItem(name: '김무침', calories: 81, category: '채소/샐러드', grams: 30, carbs: 12.2, protein: 4.7, fat: 4.1),
    FoodItem(name: '미역초무침', calories: 24, category: '채소/샐러드', grams: 50, carbs: 5.7, protein: 1.1, fat: 0.5),
    FoodItem(name: '북어채무침', calories: 332, category: '채소/샐러드', grams: 150, carbs: 31.3, protein: 37.4, fat: 5.8),
    FoodItem(name: '회무침', calories: 311, category: '채소/샐러드', grams: 300, carbs: 42.9, protein: 27.2, fat: 4.3),
    FoodItem(name: '쥐치채', calories: 53, category: '기타', grams: 20, carbs: 10.2, protein: 2.8, fat: 0.2),
    FoodItem(name: '파래무침', calories: 31, category: '채소/샐러드', grams: 30, carbs: 5.4, protein: 2.3, fat: 0.7),
    FoodItem(name: '홍어무침', calories: 193, category: '채소/샐러드', grams: 200, carbs: 24.9, protein: 21.6, fat: 2.3),
    FoodItem(name: '골뱅이국수무침', calories: 256, category: '국/찌개', grams: 230, carbs: 39.6, protein: 10.5, fat: 7.0),
    FoodItem(name: '오징어무침', calories: 249, category: '채소/샐러드', grams: 200, carbs: 13.6, protein: 38.7, fat: 4.2),
    FoodItem(name: '잡채', calories: 198, category: '기타', grams: 150, carbs: 37.5, protein: 2.6, fat: 4.7),
    FoodItem(name: '탕평채', calories: 101, category: '국/찌개', grams: 100, carbs: 10.2, protein: 3.5, fat: 3.1),
    FoodItem(name: '갓김치', calories: 27, category: '채소/샐러드', grams: 50, carbs: 5.2, protein: 2.0, fat: 0.7),
    FoodItem(name: '고들빼기', calories: 55, category: '기타', grams: 50, carbs: 12.0, protein: 2.2, fat: 0.6),
    FoodItem(name: '깍두기', calories: 17, category: '기타', grams: 50, carbs: 3.9, protein: 1.0, fat: 0.2),
    FoodItem(name: '깻잎김치', calories: 124, category: '채소/샐러드', grams: 150, carbs: 23.3, protein: 6.1, fat: 3.2),
    FoodItem(name: '나박김치', calories: 14, category: '채소/샐러드', grams: 100, carbs: 2.3, protein: 0.6, fat: 0.4),
    FoodItem(name: '동치미', calories: 57, category: '기타', grams: 400, carbs: 14.3, protein: 2.7, fat: 0.6),
    FoodItem(name: '배추겉절이', calories: 21, category: '채소/샐러드', grams: 50, carbs: 4.5, protein: 0.9, fat: 0.5),
    FoodItem(name: '배추김치', calories: 18, category: '채소/샐러드', grams: 50, carbs: 4.2, protein: 1.1, fat: 0.3),
    FoodItem(name: '백김치', calories: 19, category: '채소/샐러드', grams: 50, carbs: 4.4, protein: 0.8, fat: 0.3),
    FoodItem(name: '부추김치', calories: 32, category: '채소/샐러드', grams: 50, carbs: 6.3, protein: 1.9, fat: 0.6),
    FoodItem(name: '열무김치', calories: 16, category: '채소/샐러드', grams: 50, carbs: 3.2, protein: 1.3, fat: 0.3),
    FoodItem(name: '열무얼갈이김치', calories: 16, category: '채소/샐러드', grams: 50, carbs: 3.0, protein: 1.3, fat: 0.4),
    FoodItem(name: '오이소박이', calories: 16, category: '기타', grams: 50, carbs: 3.0, protein: 0.9, fat: 0.5),
    FoodItem(name: '총각김치', calories: 17, category: '채소/샐러드', grams: 50, carbs: 3.4, protein: 1.0, fat: 0.4),
    FoodItem(name: '파김치', calories: 28, category: '채소/샐러드', grams: 50, carbs: 5.5, protein: 1.6, fat: 0.7),
    FoodItem(name: '간장게장', calories: 292, category: '기타', grams: 250, carbs: 13.9, protein: 32.7, fat: 2.1),
    FoodItem(name: '마늘쫑장아찌', calories: 28, category: '기타', grams: 50, carbs: 6.2, protein: 1.0, fat: 0.1),
    FoodItem(name: '고추장아찌', calories: 22, category: '기타', grams: 30, carbs: 4.2, protein: 0.8, fat: 0.1),
    FoodItem(name: '깻잎장아찌', calories: 33, category: '기타', grams: 30, carbs: 7.9, protein: 2.1, fat: 0.4),
    FoodItem(name: '마늘장아찌', calories: 16, category: '기타', grams: 30, carbs: 3.1, protein: 0.8, fat: 0.0),
    FoodItem(name: '무장아찌', calories: 27, category: '기타', grams: 30, carbs: 5.3, protein: 0.6, fat: 0.3),
    FoodItem(name: '양념게장', calories: 275, category: '기타', grams: 200, carbs: 46.3, protein: 20.4, fat: 2.1),
    FoodItem(name: '양파장아찌', calories: 19, category: '기타', grams: 50, carbs: 3.5, protein: 0.6, fat: 0.1),
    FoodItem(name: '오이지', calories: 11, category: '기타', grams: 50, carbs: 2.4, protein: 1.1, fat: 0.3),
    FoodItem(name: '무피클', calories: 17, category: '기타', grams: 50, carbs: 4.2, protein: 0.4, fat: 0.1),
    FoodItem(name: '오이피클', calories: 54, category: '기타', grams: 50, carbs: 14.6, protein: 0.3, fat: 0.2),
    FoodItem(name: '단무지', calories: 3, category: '기타', grams: 30, carbs: 0.7, protein: 0.1, fat: 0.2),
    FoodItem(name: '오징어젓갈', calories: 6, category: '기타', grams: 10, carbs: 0.3, protein: 1.2, fat: 0.1),
    FoodItem(name: '명란젓', calories: 12, category: '기타', grams: 10, carbs: 0.3, protein: 2.1, fat: 0.3),
    FoodItem(name: '생연어', calories: 110, category: '고기/생선', grams: 100, carbs: 1.0, protein: 20.9, fat: 1.9),
    FoodItem(name: '생선물회', calories: 575, category: '고기/생선', grams: 800, carbs: 81.5, protein: 36.8, fat: 14.1),
    FoodItem(name: '광어회 ', calories: 116, category: '고기/생선', grams: 100, carbs: 9.3, protein: 17.2, fat: 1.4),
    FoodItem(name: '훈제연어', calories: 169, category: '고기/생선', grams: 100, carbs: 9.3, protein: 19.3, fat: 6.2),
    FoodItem(name: '육회', calories: 236, category: '기타', grams: 150, carbs: 15.9, protein: 25.0, fat: 8.0),
    FoodItem(name: '육사시미', calories: 203, category: '기타', grams: 150, carbs: 7.0, protein: 29.3, fat: 6.1),
    FoodItem(name: '가래떡', calories: 205, category: '기타', grams: 100, carbs: 45.0, protein: 3.5, fat: 0.3),
    FoodItem(name: '경단', calories: 303, category: '기타', grams: 100, carbs: 67.0, protein: 6.6, fat: 0.5),
    FoodItem(name: '꿀떡', calories: 225, category: '기타', grams: 100, carbs: 50.4, protein: 3.2, fat: 0.8),
    FoodItem(name: '시루떡', calories: 223, category: '기타', grams: 100, carbs: 49.0, protein: 5.5, fat: 0.3),
    FoodItem(name: '메밀전병', calories: 166, category: '기타', grams: 100, carbs: 24.8, protein: 5.8, fat: 5.5),
    FoodItem(name: '찰떡', calories: 216, category: '기타', grams: 100, carbs: 44.9, protein: 5.8, fat: 1.2),
    FoodItem(name: '무지개떡', calories: 218, category: '기타', grams: 100, carbs: 48.7, protein: 4.0, fat: 0.9),
    FoodItem(name: '백설기', calories: 218, category: '기타', grams: 100, carbs: 48.2, protein: 4.0, fat: 0.8),
    FoodItem(name: '송편', calories: 234, category: '기타', grams: 100, carbs: 46.8, protein: 4.2, fat: 2.7),
    FoodItem(name: '수수부꾸미', calories: 258, category: '기타', grams: 100, carbs: 46.2, protein: 5.5, fat: 5.7),
    FoodItem(name: '수수팥떡', calories: 212, category: '기타', grams: 100, carbs: 45.2, protein: 6.0, fat: 0.7),
    FoodItem(name: '쑥떡', calories: 238, category: '기타', grams: 100, carbs: 54.6, protein: 4.5, fat: 0.5),
    FoodItem(name: '약식', calories: 232, category: '기타', grams: 100, carbs: 48.9, protein: 3.8, fat: 2.3),
    FoodItem(name: '인절미', calories: 214, category: '기타', grams: 100, carbs: 42.6, protein: 6.4, fat: 1.8),
    FoodItem(name: '절편', calories: 197, category: '기타', grams: 100, carbs: 44.1, protein: 3.1, fat: 0.3),
    FoodItem(name: '증편', calories: 198, category: '기타', grams: 100, carbs: 44.2, protein: 2.5, fat: 0.3),
    FoodItem(name: '찹쌀떡', calories: 264, category: '기타', grams: 100, carbs: 62.1, protein: 3.4, fat: 0.2),
    FoodItem(name: '매작과', calories: 121, category: '기타', grams: 30, carbs: 19.1, protein: 2.6, fat: 3.6),
    FoodItem(name: '다식', calories: 105, category: '기타', grams: 30, carbs: 20.8, protein: 3.5, fat: 1.7),
    FoodItem(name: '약과', calories: 113, category: '기타', grams: 30, carbs: 22.2, protein: 2.6, fat: 1.2),
    FoodItem(name: '유과', calories: 129, category: '기타', grams: 30, carbs: 24.1, protein: 0.4, fat: 3.5),
    FoodItem(name: '산자', calories: 121, category: '기타', grams: 30, carbs: 24.7, protein: 0.9, fat: 1.2),
    FoodItem(name: '깨강정', calories: 150, category: '기타', grams: 30, carbs: 13.6, protein: 4.5, fat: 9.9),
  ];

  // 카테고리 목록 추출
  List<String> get _categories {
    final cats = _foodDatabase.map((f) => f.category).toSet().toList();
    cats.sort();
    return cats;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // arguments에서 mealType 가져오기 (홈 화면에서 선택한 식사 유형)
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('mealType')) {
      final mealType = args['mealType'] as String?;
      if (mealType != null) {
        // DB 형식(BREAKFAST)을 한글(아침)로 변환
        setState(() {
          switch (mealType) {
            case 'BREAKFAST':
              _selectedMealType = '아침';
              break;
            case 'LUNCH':
              _selectedMealType = '점심';
              break;
            case 'DINNER':
              _selectedMealType = '저녁';
              break;
            case 'SNACK':
              _selectedMealType = '간식';
              break;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 검색어가 없고 카테고리도 선택 안됐으면 캐시 사용
    Map<String, List<FoodItem>> groupedFoods;
    
    if (_searchQuery.isEmpty && _selectedCategory == null) {
      // 전체 데이터 캐싱
      _cachedGroupedFoods ??= _groupFoodsByCategory(_foodDatabase);
      groupedFoods = _cachedGroupedFoods!;
    } else {
      // 필터링 적용
      var filteredFoods = _foodDatabase;
      
      // 카테고리 필터
      if (_selectedCategory != null) {
        filteredFoods = filteredFoods.where((f) => f.category == _selectedCategory).toList();
      }
      
      // 검색어 필터
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        filteredFoods = filteredFoods.where((food) => 
          food.name.toLowerCase().contains(query)
        ).toList();
      }
      
      groupedFoods = _groupFoodsByCategory(filteredFoods);
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('$_selectedMealType 추가'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 검색 바
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '음식 검색',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.edit_note, color: Color(0xFF66BB6A)),
                  onPressed: _showCustomFoodDialog,
                  tooltip: '직접 입력',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                // 디바운싱 적용 - 300ms 후에 검색 실행
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  setState(() {
                    _searchQuery = value;
                  });
                });
              },
            ),
          ),

          // 카테고리 선택 바
          Container(
            height: 50,
            color: Colors.white,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildCategoryChip('전체', null),
                ..._categories.map((cat) => _buildCategoryChip(cat, cat)),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 음식 목록
          Expanded(
            child: ListView.builder(
              itemCount: groupedFoods.length,
              // addAutomaticKeepAlives: false, // 메모리 절약
              // addRepaintBoundaries: true, // 리페인트 최적화
              itemBuilder: (context, index) {
                final category = groupedFoods.keys.elementAt(index);
                final foods = groupedFoods[category]!;

                return RepaintBoundary( // 리페인트 경계 추가
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ...foods.map((food) => _buildFoodTile(food)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // 하단바: n개 담겼어요
      bottomNavigationBar: _selectedFoods.isNotEmpty
          ? GestureDetector(
              onTap: _saveMeal,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF66BB6A),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedFoods.length}개 담겼어요',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '총 ${_selectedFoods.fold<int>(0, (sum, item) => sum + item.totalCalories)} kcal',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_isSaving)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          else
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  /// 카테고리 선택 칩 위젯
  Widget _buildCategoryChip(String label, String? value) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedCategory = value;
            // 카테고리 변경 시 캐시 초기화
            if (value == null && _searchQuery.isEmpty) {
              _cachedGroupedFoods = null;
            }
          });
        },
        backgroundColor: Colors.grey[100],
        selectedColor: const Color(0xFF66BB6A),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        showCheckmark: false,
      ),
    );
  }

  /// 음식 리스트를 카테고리별로 그룹화하는 헬퍼 메서드
  Map<String, List<FoodItem>> _groupFoodsByCategory(List<FoodItem> foods) {
    final grouped = <String, List<FoodItem>>{};
    for (var food in foods) {
      grouped.putIfAbsent(food.category, () => []).add(food);
    }
    return grouped;
  }

  /// 음식 항목 타일
  Widget _buildFoodTile(FoodItem food) {
    final selectedItem = _selectedFoods.firstWhere(
      (item) => item.food.name == food.name,
      orElse: () => SelectedFoodItem(food: food, quantity: 0),
    );
    final isSelected = selectedItem.quantity > 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${food.grams.toStringAsFixed(0)}g',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${food.calories} kcal',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF66BB6A),
            ),
          ),
        ],
      ),
      trailing: isSelected
          ? Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF66BB6A),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 20,
              ),
            )
          : const Icon(
              Icons.add_circle_outline,
              color: Color(0xFF66BB6A),
              size: 28,
            ),
      onTap: () => _showFoodDetailPopup(food),
    );
  }

  /// 음식 상세 팝업 표시
  void _showFoodDetailPopup(FoodItem food) {
    final selectedItem = _selectedFoods.firstWhere(
      (item) => item.food.name == food.name,
      orElse: () => SelectedFoodItem(food: food, quantity: 0),
    );
    int quantity = selectedItem.quantity > 0 ? selectedItem.quantity : 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // 핸들
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // 내용
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 음식명
                          Text(
                            food.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // 영양 정보
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildNutrientInfo('탄', '${(food.carbs * quantity).toStringAsFixed(1)}g'),
                                    _buildNutrientInfo('단', '${(food.protein * quantity).toStringAsFixed(1)}g'),
                                    _buildNutrientInfo('지', '${(food.fat * quantity).toStringAsFixed(1)}g'),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      '칼로리',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${(food.calories * quantity).toStringAsFixed(0)} kcal',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF66BB6A),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // g 표시
                          Text(
                            '${(food.grams * quantity).toStringAsFixed(0)}g',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // 수량 조절
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '수량',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: quantity > 1
                                          ? () {
                                              setModalState(() {
                                                quantity--;
                                              });
                                            }
                                          : null,
                                      icon: const Icon(Icons.remove_circle_outline),
                                      color: const Color(0xFF66BB6A),
                                    ),
                                    Container(
                                      width: 50,
                                      alignment: Alignment.center,
                                      child: Text(
                                        '$quantity',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setModalState(() {
                                          quantity++;
                                        });
                                      },
                                      icon: const Icon(Icons.add_circle_outline),
                                      color: const Color(0xFF66BB6A),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // 목록에 담기 버튼
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  // 기존 항목 제거
                                  _selectedFoods.removeWhere((item) => item.food.name == food.name);
                                  // 새 항목 추가
                                  _selectedFoods.add(SelectedFoodItem(
                                    food: food,
                                    quantity: quantity,
                                  ));
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF66BB6A),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                '목록에 담기',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 영양소 정보 위젯
  Widget _buildNutrientInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
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

  /// 직접 입력 다이얼로그 표시
  void _showCustomFoodDialog() {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    final carbsController = TextEditingController();
    final proteinController = TextEditingController();
    final fatController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('음식 직접 입력'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '음식 이름 *',
                  hintText: '예: 치킨샐러드',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: caloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '칼로리 (kcal) *',
                  hintText: '예: 350',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '영양 성분 (선택)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: carbsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '탄수화물 (g)',
                        hintText: '0',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: proteinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '단백질 (g)',
                        hintText: '0',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: fatController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '지방 (g)',
                  hintText: '0',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final cals = int.tryParse(caloriesController.text.trim());
              
              if (name.isEmpty || cals == null || cals <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('음식 이름과 칼로리를 입력해주세요'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final carbs = double.tryParse(carbsController.text.trim()) ?? 0.0;
              final protein = double.tryParse(proteinController.text.trim()) ?? 0.0;
              final fat = double.tryParse(fatController.text.trim()) ?? 0.0;

              setState(() {
                _selectedFoods.add(SelectedFoodItem(
                  food: FoodItem(
                    name: name,
                    calories: cals,
                    category: '직접입력',
                    grams: 100,
                    carbs: carbs,
                    protein: protein,
                    fat: fat,
                  ),
                  quantity: 1,
                ));
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$name이(가) 추가되었습니다'),
                  backgroundColor: const Color(0xFF66BB6A),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF66BB6A),
            ),
            child: const Text('추가', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// 식단 저장
  Future<void> _saveMeal() async {
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

      // MealType enum 변환
      String mealTypeEnum;
      switch (_selectedMealType) {
        case '아침':
          mealTypeEnum = 'BREAKFAST';
          break;
        case '점심':
          mealTypeEnum = 'LUNCH';
          break;
        case '저녁':
          mealTypeEnum = 'DINNER';
          break;
        case '간식':
          mealTypeEnum = 'SNACK';
          break;
        default:
          mealTypeEnum = 'BREAKFAST';
      }

      // MealItem 리스트 생성
      final mealItems = _selectedFoods.map((selectedItem) {
        return MealItem(
          mealLogId: 0, // 임시값, 서버에서 자동 할당됨
          foodName: selectedItem.food.name,
          caloriesKcal: selectedItem.totalCalories.toDouble(),
          carbohydratesG: selectedItem.totalCarbs,
          proteinG: selectedItem.totalProtein,
          fatG: selectedItem.totalFat,
        );
      }).toList();

      // MealLog 생성
      final mealLog = MealLog(
        memberId: currentUser.memberId,
        mealDate: _mealDate, // 전달받은 날짜 사용
        mealType: mealTypeEnum,
        items: mealItems,
      );

      // DB에 저장
      final result = await _mealService.createMeal(mealLog);

      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$_selectedMealType 식단이 추가되었습니다 (${_selectedFoods.fold<int>(0, (sum, item) => sum + item.totalCalories)} kcal)',
              ),
              backgroundColor: const Color(0xFF66BB6A),
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('식단 저장에 실패했습니다. 서버 연결을 확인하세요.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('식단 저장 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('서버 연결에 실패했습니다. 네트워크를 확인하세요.\n오류: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
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

