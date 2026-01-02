import { useState } from 'react';
import { ArrowLeft, Search, Plus, X } from 'lucide-react';

interface MealDetailScreenProps {
  mealType: 'breakfast' | 'lunch' | 'dinner' | 'snack';
  mealTitle: string;
  onBack: () => void;
  onSave: (foods: any[]) => void;
}

// 음식 데이터베이스 (샘플)
const foodDatabase = [
  // 밥류
  { 
    name: '현미밥', 
    servings: [
      { size: '1공기', calories: 330, carbs: 72, protein: 7, fat: 2 },
      { size: '1/2공기', calories: 165, carbs: 36, protein: 3.5, fat: 1 },
      { size: '1/3공기', calories: 110, carbs: 24, protein: 2.3, fat: 0.7 },
    ]
  },
  { 
    name: '백미밥', 
    servings: [
      { size: '1공기', calories: 300, carbs: 68, protein: 5, fat: 0.5 },
      { size: '1/2공기', calories: 150, carbs: 34, protein: 2.5, fat: 0.3 },
      { size: '1/3공기', calories: 100, carbs: 23, protein: 1.7, fat: 0.2 },
    ]
  },
  { 
    name: '잡곡밥', 
    servings: [
      { size: '1공기', calories: 320, carbs: 70, protein: 6, fat: 1.5 },
      { size: '1/2공기', calories: 160, carbs: 35, protein: 3, fat: 0.8 },
    ]
  },
  { 
    name: '볶음밥', 
    servings: [
      { size: '1인분', calories: 520, carbs: 75, protein: 12, fat: 18 },
      { size: '1/2인분', calories: 260, carbs: 37.5, protein: 6, fat: 9 },
    ]
  },
  { 
    name: '비빔밥', 
    servings: [
      { size: '1인분', calories: 560, carbs: 85, protein: 18, fat: 15 },
      { size: '1/2인분', calories: 280, carbs: 42.5, protein: 9, fat: 7.5 },
    ]
  },
  // 국/찌개류
  { 
    name: '김치찌개', 
    servings: [
      { size: '1인분', calories: 280, carbs: 15, protein: 18, fat: 15 },
      { size: '1/2인분', calories: 140, carbs: 7.5, protein: 9, fat: 7.5 },
    ]
  },
  { 
    name: '된장찌개', 
    servings: [
      { size: '1인분', calories: 180, carbs: 12, protein: 15, fat: 8 },
      { size: '1/2인분', calories: 90, carbs: 6, protein: 7.5, fat: 4 },
    ]
  },
  { 
    name: '순두부찌개', 
    servings: [
      { size: '1인분', calories: 220, carbs: 10, protein: 14, fat: 12 },
      { size: '1/2인분', calories: 110, carbs: 5, protein: 7, fat: 6 },
    ]
  },
  { 
    name: '미역국', 
    servings: [
      { size: '1그릇', calories: 120, carbs: 8, protein: 6, fat: 7 },
      { size: '1/2그릇', calories: 60, carbs: 4, protein: 3, fat: 3.5 },
    ]
  },
  { 
    name: '육개장', 
    servings: [
      { size: '1인분', calories: 320, carbs: 18, protein: 22, fat: 16 },
      { size: '1/2인분', calories: 160, carbs: 9, protein: 11, fat: 8 },
    ]
  },
  { 
    name: '삼계탕', 
    servings: [
      { size: '1인분', calories: 900, carbs: 35, protein: 52, fat: 60 },
      { size: '1/2인분', calories: 450, carbs: 17.5, protein: 26, fat: 30 },
    ]
  },
  // 고기류
  { 
    name: '제육볶음', 
    servings: [
      { size: '1인분', calories: 450, carbs: 20, protein: 25, fat: 30 },
      { size: '1/2인분', calories: 225, carbs: 10, protein: 12.5, fat: 15 },
    ]
  },
  { 
    name: '닭가슴살', 
    servings: [
      { size: '100g', calories: 165, carbs: 0, protein: 31, fat: 3.6 },
      { size: '150g', calories: 248, carbs: 0, protein: 46.5, fat: 5.4 },
      { size: '200g', calories: 330, carbs: 0, protein: 62, fat: 7.2 },
    ]
  },
  { 
    name: '삼겹살', 
    servings: [
      { size: '100g', calories: 518, carbs: 0, protein: 17, fat: 50 },
      { size: '200g', calories: 1036, carbs: 0, protein: 34, fat: 100 },
    ]
  },
  { 
    name: '소고기', 
    servings: [
      { size: '100g', calories: 250, carbs: 0, protein: 26, fat: 15 },
      { size: '150g', calories: 375, carbs: 0, protein: 39, fat: 22.5 },
    ]
  },
  { 
    name: '돈까스', 
    servings: [
      { size: '1인분', calories: 580, carbs: 45, protein: 28, fat: 32 },
      { size: '1/2인분', calories: 290, carbs: 22.5, protein: 14, fat: 16 },
    ]
  },
  { 
    name: '치킨', 
    servings: [
      { size: '1조각', calories: 280, carbs: 15, protein: 18, fat: 16 },
      { size: '2조각', calories: 560, carbs: 30, protein: 36, fat: 32 },
    ]
  },
  // 생선류
  { 
    name: '고등어구이', 
    servings: [
      { size: '1마리', calories: 340, carbs: 0, protein: 38, fat: 20 },
      { size: '1/2마리', calories: 170, carbs: 0, protein: 19, fat: 10 },
    ]
  },
  { 
    name: '연어', 
    servings: [
      { size: '100g', calories: 208, carbs: 0, protein: 20, fat: 13 },
      { size: '150g', calories: 312, carbs: 0, protein: 30, fat: 19.5 },
    ]
  },
  { 
    name: '참치캔', 
    servings: [
      { size: '1캔(100g)', calories: 132, carbs: 0, protein: 28, fat: 2 },
    ]
  },
  // 계란류
  { 
    name: '계란', 
    servings: [
      { size: '1개', calories: 75, carbs: 0.6, protein: 6, fat: 5 },
      { size: '2개', calories: 150, carbs: 1.2, protein: 12, fat: 10 },
      { size: '3개', calories: 225, carbs: 1.8, protein: 18, fat: 15 },
    ]
  },
  { 
    name: '계란후라이', 
    servings: [
      { size: '1개', calories: 90, carbs: 0.4, protein: 6.3, fat: 7 },
      { size: '2개', calories: 180, carbs: 0.8, protein: 12.6, fat: 14 },
    ]
  },
  { 
    name: '계란찜', 
    servings: [
      { size: '1인분', calories: 120, carbs: 2, protein: 10, fat: 8 },
    ]
  },
  { 
    name: '삶은계란', 
    servings: [
      { size: '1개', calories: 68, carbs: 0.6, protein: 6, fat: 4.5 },
      { size: '2개', calories: 136, carbs: 1.2, protein: 12, fat: 9 },
    ]
  },
  // 면류
  { 
    name: '라면', 
    servings: [
      { size: '1봉지', calories: 500, carbs: 80, protein: 10, fat: 16 },
    ]
  },
  { 
    name: '냉면', 
    servings: [
      { size: '1인분', calories: 480, carbs: 95, protein: 12, fat: 3 },
    ]
  },
  { 
    name: '짜장면', 
    servings: [
      { size: '1인분', calories: 680, carbs: 110, protein: 18, fat: 18 },
    ]
  },
  { 
    name: '짬뽕', 
    servings: [
      { size: '1인분', calories: 620, carbs: 85, protein: 25, fat: 20 },
    ]
  },
  { 
    name: '파스타', 
    servings: [
      { size: '1인분', calories: 550, carbs: 75, protein: 15, fat: 18 },
    ]
  },
  { 
    name: '칼국수', 
    servings: [
      { size: '1인분', calories: 420, carbs: 70, protein: 15, fat: 8 },
    ]
  },
  // 빵/간식류
  { 
    name: '식빵', 
    servings: [
      { size: '1장', calories: 80, carbs: 15, protein: 2.5, fat: 1 },
      { size: '2장', calories: 160, carbs: 30, protein: 5, fat: 2 },
    ]
  },
  { 
    name: '크로와상', 
    servings: [
      { size: '1개', calories: 230, carbs: 26, protein: 5, fat: 12 },
    ]
  },
  { 
    name: '베이글', 
    servings: [
      { size: '1개', calories: 245, carbs: 48, protein: 9, fat: 2 },
    ]
  },
  { 
    name: '도넛', 
    servings: [
      { size: '1개', calories: 250, carbs: 30, protein: 3, fat: 13 },
    ]
  },
  // 과일류
  { 
    name: '사과', 
    servings: [
      { size: '1개', calories: 95, carbs: 25, protein: 0.5, fat: 0.3 },
      { size: '1/2개', calories: 48, carbs: 12.5, protein: 0.3, fat: 0.2 },
    ]
  },
  { 
    name: '바나나', 
    servings: [
      { size: '1개', calories: 105, carbs: 27, protein: 1.3, fat: 0.4 },
      { size: '1/2개', calories: 53, carbs: 13.5, protein: 0.7, fat: 0.2 },
    ]
  },
  { 
    name: '딸기', 
    servings: [
      { size: '10개', calories: 45, carbs: 11, protein: 1, fat: 0.3 },
      { size: '5개', calories: 23, carbs: 5.5, protein: 0.5, fat: 0.2 },
    ]
  },
  { 
    name: '포도', 
    servings: [
      { size: '1송이(200g)', calories: 138, carbs: 36, protein: 1.4, fat: 0.3 },
      { size: '1/2송이', calories: 69, carbs: 18, protein: 0.7, fat: 0.2 },
    ]
  },
  { 
    name: '수박', 
    servings: [
      { size: '1조각(300g)', calories: 90, carbs: 23, protein: 1.8, fat: 0.5 },
    ]
  },
  { 
    name: '오렌지', 
    servings: [
      { size: '1개', calories: 62, carbs: 15, protein: 1.2, fat: 0.2 },
    ]
  },
  // 야채/샐러드
  { 
    name: '샐러드', 
    servings: [
      { size: '1인분', calories: 120, carbs: 15, protein: 5, fat: 4 },
      { size: '소', calories: 80, carbs: 10, protein: 3, fat: 2.5 },
    ]
  },
  { 
    name: '시저샐러드', 
    servings: [
      { size: '1인분', calories: 350, carbs: 18, protein: 12, fat: 26 },
    ]
  },
  { 
    name: '두부', 
    servings: [
      { size: '1/4모', calories: 80, carbs: 2, protein: 8, fat: 4.5 },
      { size: '1/2모', calories: 160, carbs: 4, protein: 16, fat: 9 },
    ]
  },
  { 
    name: '김', 
    servings: [
      { size: '1봉지(10장)', calories: 35, carbs: 3, protein: 4, fat: 1 },
    ]
  },
  // 고구마/감자
  { 
    name: '고구마', 
    servings: [
      { size: '1개(중)', calories: 130, carbs: 30, protein: 2, fat: 0.2 },
      { size: '1/2개', calories: 65, carbs: 15, protein: 1, fat: 0.1 },
      { size: '1개(대)', calories: 180, carbs: 42, protein: 2.5, fat: 0.3 },
    ]
  },
  { 
    name: '감자', 
    servings: [
      { size: '1개(중)', calories: 110, carbs: 26, protein: 3, fat: 0.1 },
      { size: '1/2개', calories: 55, carbs: 13, protein: 1.5, fat: 0.1 },
    ]
  },
  // 우유/유제품
  { 
    name: '우유', 
    servings: [
      { size: '1컵(200ml)', calories: 120, carbs: 11, protein: 6, fat: 5 },
      { size: '1팩(500ml)', calories: 300, carbs: 27.5, protein: 15, fat: 12.5 },
    ]
  },
  { 
    name: '두유', 
    servings: [
      { size: '1컵(200ml)', calories: 95, carbs: 8, protein: 7, fat: 4 },
    ]
  },
  { 
    name: '요거트', 
    servings: [
      { size: '1개(150ml)', calories: 100, carbs: 17, protein: 5, fat: 1 },
    ]
  },
  { 
    name: '그릭요거트', 
    servings: [
      { size: '1개(150g)', calories: 130, carbs: 9, protein: 15, fat: 4 },
    ]
  },
  { 
    name: '치즈', 
    servings: [
      { size: '1장(20g)', calories: 70, carbs: 0.5, protein: 5, fat: 5.5 },
      { size: '2장', calories: 140, carbs: 1, protein: 10, fat: 11 },
    ]
  },
  // 견과류
  { 
    name: '아몬드', 
    servings: [
      { size: '1줌(30g)', calories: 170, carbs: 6, protein: 6, fat: 15 },
      { size: '10알', calories: 70, carbs: 2.5, protein: 2.5, fat: 6 },
    ]
  },
  { 
    name: '호두', 
    servings: [
      { size: '1줌(30g)', calories: 185, carbs: 4, protein: 4.3, fat: 18 },
    ]
  },
  { 
    name: '땅콩', 
    servings: [
      { size: '1줌(30g)', calories: 170, carbs: 5, protein: 7, fat: 14 },
    ]
  },
  // 음료
  { 
    name: '아메리카노', 
    servings: [
      { size: '1잔', calories: 5, carbs: 1, protein: 0.3, fat: 0 },
    ]
  },
  { 
    name: '카페라떼', 
    servings: [
      { size: '1잔', calories: 150, carbs: 14, protein: 8, fat: 6 },
    ]
  },
  { 
    name: '카페모카', 
    servings: [
      { size: '1잔', calories: 290, carbs: 42, protein: 10, fat: 10 },
    ]
  },
  { 
    name: '콜라', 
    servings: [
      { size: '1캔(350ml)', calories: 140, carbs: 39, protein: 0, fat: 0 },
    ]
  },
  { 
    name: '오렌지주스', 
    servings: [
      { size: '1컵(200ml)', calories: 110, carbs: 26, protein: 2, fat: 0.5 },
    ]
  },
];

export function MealDetailScreen({ mealType, mealTitle, onBack, onSave }: MealDetailScreenProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedFoods, setSelectedFoods] = useState<any[]>([]);
  const [showServingModal, setShowServingModal] = useState(false);
  const [currentFood, setCurrentFood] = useState<any>(null);

  const filteredFoods = searchQuery
    ? foodDatabase.filter(food => food.name.includes(searchQuery))
    : foodDatabase;

  const handleFoodClick = (food: any) => {
    setCurrentFood(food);
    setShowServingModal(true);
  };

  const handleServingSelect = (serving: any) => {
    const newFood = {
      id: Date.now(),
      name: currentFood.name,
      serving: serving.size,
      calories: serving.calories,
      carbs: serving.carbs,
      protein: serving.protein,
      fat: serving.fat,
    };
    setSelectedFoods([...selectedFoods, newFood]);
    setShowServingModal(false);
    setCurrentFood(null);
  };

  const handleRemoveFood = (id: number) => {
    setSelectedFoods(selectedFoods.filter(f => f.id !== id));
  };

  const totalCalories = selectedFoods.reduce((sum, food) => sum + food.calories, 0);
  const totalCarbs = selectedFoods.reduce((sum, food) => sum + food.carbs, 0);
  const totalProtein = selectedFoods.reduce((sum, food) => sum + food.protein, 0);
  const totalFat = selectedFoods.reduce((sum, food) => sum + food.fat, 0);

  return (
    <div className="w-full max-w-md h-screen bg-white flex flex-col">
      {/* 헤더 */}
      <div className="bg-gradient-to-r from-green-500 to-green-600 text-white p-4">
        <div className="flex items-center gap-3 mb-4">
          <button onClick={onBack} className="p-1 hover:bg-white/20 rounded-lg transition-colors">
            <ArrowLeft className="w-6 h-6" />
          </button>
          <h1 className="text-xl font-bold">{mealTitle} 식단 입력</h1>
        </div>

        {/* 검색 바 */}
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            placeholder="음식을 검색하세요 (예: 현미밥)"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-3 rounded-lg text-gray-800 placeholder-gray-400"
          />
        </div>
      </div>

      {/* 선택된 음식 목록 */}
      {selectedFoods.length > 0 && (
        <div className="bg-green-50 p-4 border-b border-green-100">
          <h3 className="font-semibold text-gray-800 mb-2">선택한 음식</h3>
          <div className="space-y-2">
            {selectedFoods.map((food) => (
              <div key={food.id} className="bg-white rounded-lg p-3 flex items-center justify-between">
                <div className="flex-1">
                  <div className="font-semibold text-gray-800">{food.name}</div>
                  <div className="text-sm text-gray-500">{food.serving} · {food.calories} kcal</div>
                </div>
                <button
                  onClick={() => handleRemoveFood(food.id)}
                  className="p-1 hover:bg-gray-100 rounded-full transition-colors"
                >
                  <X className="w-5 h-5 text-gray-500" />
                </button>
              </div>
            ))}
          </div>

          {/* 총 영양성분 */}
          <div className="mt-3 bg-white rounded-lg p-3">
            <div className="grid grid-cols-4 gap-2 text-center">
              <div>
                <div className="text-xs text-gray-500">칼로리</div>
                <div className="font-bold text-green-600">{totalCalories}</div>
              </div>
              <div>
                <div className="text-xs text-gray-500">탄수화물</div>
                <div className="font-bold text-blue-600">{totalCarbs.toFixed(1)}g</div>
              </div>
              <div>
                <div className="text-xs text-gray-500">단백질</div>
                <div className="font-bold text-orange-600">{totalProtein.toFixed(1)}g</div>
              </div>
              <div>
                <div className="text-xs text-gray-500">지방</div>
                <div className="font-bold text-purple-600">{totalFat.toFixed(1)}g</div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* 음식 검색 결과 */}
      <div className="flex-1 overflow-y-auto p-4">
        <h3 className="font-semibold text-gray-800 mb-3">음식 선택</h3>
        <div className="space-y-2">
          {filteredFoods.map((food, index) => (
            <button
              key={index}
              onClick={() => handleFoodClick(food)}
              className="w-full bg-white border border-gray-200 rounded-lg p-4 text-left hover:border-green-400 hover:shadow-sm transition-all"
            >
              <div className="font-semibold text-gray-800">{food.name}</div>
              <div className="text-sm text-gray-500 mt-1">
                {food.servings[0].calories} kcal ({food.servings[0].size})
              </div>
            </button>
          ))}
        </div>
      </div>

      {/* 저장 버튼 */}
      <div className="p-4 border-t border-gray-200">
        <button
          onClick={() => onSave(selectedFoods)}
          disabled={selectedFoods.length === 0}
          className={`w-full py-4 rounded-lg font-semibold transition-colors ${
            selectedFoods.length > 0
              ? 'bg-green-600 text-white hover:bg-green-700'
              : 'bg-gray-200 text-gray-400 cursor-not-allowed'
          }`}
        >
          저장하기 ({totalCalories} kcal)
        </button>
      </div>

      {/* 양 선택 모달 */}
      {showServingModal && currentFood && (
        <div className="absolute inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl w-full max-w-sm overflow-hidden">
            <div className="bg-gradient-to-r from-green-500 to-green-600 text-white p-4">
              <div className="flex items-center justify-between mb-2">
                <h3 className="text-lg font-bold">{currentFood.name}</h3>
                <button
                  onClick={() => setShowServingModal(false)}
                  className="p-1 hover:bg-white/20 rounded-full transition-colors"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>
              <p className="text-sm text-white/90">양을 선택하세요</p>
            </div>

            <div className="p-4 space-y-2 max-h-96 overflow-y-auto">
              {currentFood.servings.map((serving: any, index: number) => (
                <button
                  key={index}
                  onClick={() => handleServingSelect(serving)}
                  className="w-full bg-gray-50 border border-gray-200 rounded-lg p-4 hover:border-green-400 hover:bg-green-50 transition-all text-left"
                >
                  <div className="flex items-center justify-between mb-2">
                    <span className="font-semibold text-gray-800">{serving.size}</span>
                    <span className="text-green-600 font-bold">{serving.calories} kcal</span>
                  </div>
                  <div className="flex gap-3 text-xs text-gray-600">
                    <span>탄 {serving.carbs}g</span>
                    <span>단 {serving.protein}g</span>
                    <span>지 {serving.fat}g</span>
                  </div>
                </button>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}