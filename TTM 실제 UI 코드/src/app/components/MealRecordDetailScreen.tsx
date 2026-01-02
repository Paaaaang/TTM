import { ArrowLeft, Utensils, Clock, Flame } from 'lucide-react';

interface MealRecordDetailScreenProps {
  meal: {
    id: number;
    date: string;
    meal: string;
    items: string;
    calories: number;
  };
  onBack: () => void;
}

export function MealRecordDetailScreen({ meal, onBack }: MealRecordDetailScreenProps) {
  // 음식 항목들을 분리
  const foodItems = meal.items.split(', ');

  return (
    <div className="w-full max-w-md h-screen bg-gray-50 flex flex-col">
      {/* 헤더 */}
      <div className="bg-gradient-to-r from-green-500 to-green-600 text-white p-4">
        <div className="flex items-center gap-3 mb-4">
          <button onClick={onBack} className="p-1 hover:bg-white/20 rounded-lg transition-colors">
            <ArrowLeft className="w-6 h-6" />
          </button>
          <h1 className="text-xl font-bold">식단 기록</h1>
        </div>

        {/* 식사 정보 카드 */}
        <div className="bg-white/10 backdrop-blur-sm rounded-xl p-4">
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center">
                <Utensils className="w-6 h-6" />
              </div>
              <div>
                <h2 className="text-2xl font-bold">{meal.meal}</h2>
                <div className="flex items-center gap-1 text-sm opacity-90">
                  <Clock className="w-4 h-4" />
                  <span>{meal.date}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* 칼로리 정보 */}
      <div className="p-4">
        <div className="bg-gradient-to-br from-orange-500 to-orange-600 rounded-xl p-6 text-white shadow-lg">
          <div className="flex items-center justify-center gap-2 mb-2">
            <Flame className="w-8 h-8" />
            <div className="text-5xl font-bold">{meal.calories}</div>
          </div>
          <div className="text-center text-lg opacity-90">kcal</div>
        </div>
      </div>

      {/* 음식 목록 */}
      <div className="flex-1 overflow-y-auto px-4 pb-4">
        <div className="mb-4">
          <h3 className="font-bold text-gray-800 mb-3 flex items-center gap-2">
            <span className="text-lg">🍽️</span>
            섭취한 음식
          </h3>
          <div className="space-y-2">
            {foodItems.map((item, index) => (
              <div
                key={index}
                className="bg-white rounded-xl border border-gray-200 p-4 hover:shadow-md transition-shadow"
              >
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center text-xl">
                    🥘
                  </div>
                  <div className="flex-1">
                    <div className="font-semibold text-gray-800">{item}</div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* 영양 정보 추가 */}
        <div className="bg-white rounded-xl border border-gray-200 p-4 mb-4">
          <h3 className="font-bold text-gray-800 mb-3">예상 영양 정보</h3>
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-gray-600">탄수화물</span>
              <span className="font-semibold text-gray-800">{Math.round(meal.calories * 0.5 / 4)}g</span>
            </div>
            <div className="h-px bg-gray-200"></div>
            <div className="flex items-center justify-between">
              <span className="text-gray-600">단백질</span>
              <span className="font-semibold text-gray-800">{Math.round(meal.calories * 0.3 / 4)}g</span>
            </div>
            <div className="h-px bg-gray-200"></div>
            <div className="flex items-center justify-between">
              <span className="text-gray-600">지방</span>
              <span className="font-semibold text-gray-800">{Math.round(meal.calories * 0.2 / 9)}g</span>
            </div>
          </div>
        </div>

        {/* 메모 */}
        <div className="bg-blue-50 rounded-xl border border-blue-200 p-4">
          <div className="flex items-start gap-2">
            <span className="text-xl">💡</span>
            <div>
              <div className="font-semibold text-blue-800 mb-1">영양사 TIP</div>
              <p className="text-sm text-blue-700">
                균형잡힌 식단을 유지하고 계시네요! 이런 식으로 꾸준히 기록하면 건강한 식습관을 만들 수 있습니다.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
