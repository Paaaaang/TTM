/// 식단 추가 화면
/// 사용자가 식사 정보를 추가할 수 있는 화면
import 'package:flutter/material.dart';

/// 식품 항목 모델
class FoodItem {
  final String name;
  final int calories;
  final String category;

  FoodItem({
    required this.name,
    required this.calories,
    required this.category,
  });
}

/// 식단 추가 화면 위젯
class MealAddScreen extends StatefulWidget {
  const MealAddScreen({Key? key}) : super(key: key);

  @override
  State<MealAddScreen> createState() => _MealAddScreenState();
}

class _MealAddScreenState extends State<MealAddScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedMealType = '아침'; // 아침, 점심, 저녁, 간식
  String _searchQuery = '';
  final List<FoodItem> _selectedFoods = [];

  // 더미 음식 데이터베이스
  final List<FoodItem> _foodDatabase = [
    // 밥류
    FoodItem(name: '백미밥 (1공기)', calories: 300, category: '밥류'),
    FoodItem(name: '현미밥 (1공기)', calories: 280, category: '밥류'),
    FoodItem(name: '잡곡밥 (1공기)', calories: 290, category: '밥류'),
    FoodItem(name: '김밥 (1줄)', calories: 550, category: '밥류'),
    FoodItem(name: '볶음밥', calories: 600, category: '밥류'),
    
    // 국/찌개
    FoodItem(name: '된장찌개', calories: 150, category: '국/찌개'),
    FoodItem(name: '김치찌개', calories: 200, category: '국/찌개'),
    FoodItem(name: '미역국', calories: 50, category: '국/찌개'),
    FoodItem(name: '순두부찌개', calories: 180, category: '국/찌개'),
    
    // 고기/생선
    FoodItem(name: '삼겹살 (100g)', calories: 330, category: '고기/생선'),
    FoodItem(name: '닭가슴살 (100g)', calories: 165, category: '고기/생선'),
    FoodItem(name: '계란 (1개)', calories: 78, category: '고기/생선'),
    FoodItem(name: '고등어구이', calories: 200, category: '고기/생선'),
    FoodItem(name: '연어회 (100g)', calories: 180, category: '고기/생선'),
    
    // 채소/샐러드
    FoodItem(name: '샐러드', calories: 100, category: '채소/샐러드'),
    FoodItem(name: '나물 반찬', calories: 50, category: '채소/샐러드'),
    FoodItem(name: '김치', calories: 30, category: '채소/샐러드'),
    FoodItem(name: '시금치', calories: 23, category: '채소/샐러드'),
    
    // 빵/디저트
    FoodItem(name: '식빵 (1장)', calories: 120, category: '빵/디저트'),
    FoodItem(name: '크루아상', calories: 280, category: '빵/디저트'),
    FoodItem(name: '케이크 (1조각)', calories: 350, category: '빵/디저트'),
    FoodItem(name: '초콜릿 (100g)', calories: 550, category: '빵/디저트'),
    
    // 음료
    FoodItem(name: '아메리카노', calories: 5, category: '음료'),
    FoodItem(name: '카페라떼', calories: 150, category: '음료'),
    FoodItem(name: '오렌지주스 (1컵)', calories: 120, category: '음료'),
    FoodItem(name: '콜라 (1캔)', calories: 140, category: '음료'),
    
    // 간식
    FoodItem(name: '바나나 (1개)', calories: 105, category: '간식'),
    FoodItem(name: '사과 (1개)', calories: 95, category: '간식'),
    FoodItem(name: '요거트', calories: 100, category: '간식'),
    FoodItem(name: '견과류 (30g)', calories: 180, category: '간식'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 검색어로 필터링
    final filteredFoods = _searchQuery.isEmpty
        ? _foodDatabase
        : _foodDatabase.where((food) => 
            food.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            food.category.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();

    // 카테고리별로 그룹화
    final groupedFoods = <String, List<FoodItem>>{};
    for (var food in filteredFoods) {
      groupedFoods.putIfAbsent(food.category, () => []).add(food);
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('식단 추가'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _selectedFoods.isEmpty ? null : _saveMeal,
            child: Text(
              '완료',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _selectedFoods.isEmpty
                    ? Colors.grey[400]
                    : const Color(0xFF66BB6A),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 식사 유형 선택
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '식사 유형',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildMealTypeChip('아침'),
                    const SizedBox(width: 8),
                    _buildMealTypeChip('점심'),
                    const SizedBox(width: 8),
                    _buildMealTypeChip('저녁'),
                    const SizedBox(width: 8),
                    _buildMealTypeChip('간식'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 검색 바
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '음식을 검색하세요',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          const SizedBox(height: 8),

          // 선택된 음식 표시
          if (_selectedFoods.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '선택된 음식',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '총 ${_selectedFoods.fold<int>(0, (sum, food) => sum + food.calories)} kcal',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF66BB6A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedFoods.map((food) {
                      return Chip(
                        label: Text('${food.name} (${food.calories}kcal)'),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            _selectedFoods.remove(food);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          if (_selectedFoods.isNotEmpty) const SizedBox(height: 8),

          // 음식 목록
          Expanded(
            child: ListView.builder(
              itemCount: groupedFoods.length,
              itemBuilder: (context, index) {
                final category = groupedFoods.keys.elementAt(index);
                final foods = groupedFoods[category]!;

                return Container(
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
                      ...foods.map((food) => _buildFoodTile(food)).toList(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 식사 유형 칩
  Widget _buildMealTypeChip(String type) {
    final isSelected = _selectedMealType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMealType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF66BB6A) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          type,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  /// 음식 항목 타일
  Widget _buildFoodTile(FoodItem food) {
    final isSelected = _selectedFoods.contains(food);

    return ListTile(
      title: Text(food.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${food.calories} kcal',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            isSelected ? Icons.check_circle : Icons.add_circle_outline,
            color: isSelected ? const Color(0xFF66BB6A) : Colors.grey[400],
          ),
        ],
      ),
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedFoods.remove(food);
          } else {
            _selectedFoods.add(food);
          }
        });
      },
    );
  }

  /// 식단 저장
  void _saveMeal() {
    // TODO: 실제 API 호출로 식단 저장

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$_selectedMealType 식단이 추가되었습니다 (${_selectedFoods.fold<int>(0, (sum, food) => sum + food.calories)} kcal)',
        ),
      ),
    );

    Navigator.pop(context);
  }
}
