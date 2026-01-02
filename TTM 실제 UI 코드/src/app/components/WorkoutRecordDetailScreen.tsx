import { ArrowLeft, Dumbbell, Clock, Flame, TrendingUp } from 'lucide-react';

interface WorkoutRecordDetailScreenProps {
  workout: {
    id: number;
    date: string;
    type: string;
    duration: string;
    calories: number;
  };
  onBack: () => void;
}

export function WorkoutRecordDetailScreen({ workout, onBack }: WorkoutRecordDetailScreenProps) {
  return (
    <div className="w-full max-w-md h-screen bg-gray-50 flex flex-col">
      {/* 헤더 */}
      <div className="bg-gradient-to-r from-blue-500 to-blue-600 text-white p-4">
        <div className="flex items-center gap-3 mb-4">
          <button onClick={onBack} className="p-1 hover:bg-white/20 rounded-lg transition-colors">
            <ArrowLeft className="w-6 h-6" />
          </button>
          <h1 className="text-xl font-bold">운동 기록</h1>
        </div>

        {/* 운동 정보 카드 */}
        <div className="bg-white/10 backdrop-blur-sm rounded-xl p-4">
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center">
                <Dumbbell className="w-6 h-6" />
              </div>
              <div>
                <h2 className="text-2xl font-bold">{workout.type}</h2>
                <div className="flex items-center gap-1 text-sm opacity-90">
                  <Clock className="w-4 h-4" />
                  <span>{workout.date}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* 칼로리 소모량 */}
      <div className="p-4">
        <div className="bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl p-6 text-white shadow-lg">
          <div className="flex items-center justify-center gap-2 mb-2">
            <Flame className="w-8 h-8" />
            <div className="text-5xl font-bold">{workout.calories}</div>
          </div>
          <div className="text-center text-lg opacity-90">kcal 소모</div>
        </div>
      </div>

      {/* 운동 상세 정보 */}
      <div className="flex-1 overflow-y-auto px-4 pb-4">
        <div className="bg-white rounded-xl border border-gray-200 p-4 mb-4">
          <h3 className="font-bold text-gray-800 mb-3">운동 정보</h3>
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-gray-600">운동 시간</span>
              <span className="font-semibold text-gray-800">{workout.duration}</span>
            </div>
            <div className="h-px bg-gray-200"></div>
            <div className="flex items-center justify-between">
              <span className="text-gray-600">운동 강도</span>
              <span className="font-semibold text-orange-600">중강도</span>
            </div>
            <div className="h-px bg-gray-200"></div>
            <div className="flex items-center justify-between">
              <span className="text-gray-600">소모 칼로리</span>
              <span className="font-semibold text-blue-600">{workout.calories} kcal</span>
            </div>
          </div>
        </div>

        {/* 운동 효과 */}
        <div className="bg-white rounded-xl border border-gray-200 p-4 mb-4">
          <h3 className="font-bold text-gray-800 mb-3 flex items-center gap-2">
            <TrendingUp className="w-5 h-5 text-green-600" />
            운동 효과
          </h3>
          <div className="space-y-2">
            {workout.type.includes('런닝') && (
              <>
                <div className="flex items-start gap-2 text-sm">
                  <span className="text-green-600">✓</span>
                  <span className="text-gray-700">심폐 지구력 향상</span>
                </div>
                <div className="flex items-start gap-2 text-sm">
                  <span className="text-green-600">✓</span>
                  <span className="text-gray-700">하체 근력 강화</span>
                </div>
                <div className="flex items-start gap-2 text-sm">
                  <span className="text-green-600">✓</span>
                  <span className="text-gray-700">체지방 감소</span>
                </div>
              </>
            )}
            {workout.type.includes('웨이트') && (
              <>
                <div className="flex items-start gap-2 text-sm">
                  <span className="text-green-600">✓</span>
                  <span className="text-gray-700">근육량 증가</span>
                </div>
                <div className="flex items-start gap-2 text-sm">
                  <span className="text-green-600">✓</span>
                  <span className="text-gray-700">기초대사량 향상</span>
                </div>
                <div className="flex items-start gap-2 text-sm">
                  <span className="text-green-600">✓</span>
                  <span className="text-gray-700">근력 및 체력 증진</span>
                </div>
              </>
            )}
            {workout.type.includes('요가') && (
              <>
                <div className="flex items-start gap-2 text-sm">
                  <span className="text-green-600">✓</span>
                  <span className="text-gray-700">유연성 향상</span>
                </div>
                <div className="flex items-start gap-2 text-sm">
                  <span className="text-green-600">✓</span>
                  <span className="text-gray-700">스트레스 해소</span>
                </div>
                <div className="flex items-start gap-2 text-sm">
                  <span className="text-green-600">✓</span>
                  <span className="text-gray-700">근육 이완</span>
                </div>
              </>
            )}
            {workout.type.includes('사이클') && (
              <>
                <div className="flex items-start gap-2 text-sm">
                  <span className="text-green-600">✓</span>
                  <span className="text-gray-700">심폐 기능 향상</span>
                </div>
                <div className="flex items-start gap-2 text-sm">
                  <span className="text-green-600">✓</span>
                  <span className="text-gray-700">하체 근력 강화</span>
                </div>
                <div className="flex items-start gap-2 text-sm">
                  <span className="text-green-600">✓</span>
                  <span className="text-gray-700">관절 부담 최소화</span>
                </div>
              </>
            )}
            {workout.type.includes('수영') && (
              <>
                <div className="flex items-start gap-2 text-sm">
                  <span className="text-green-600">✓</span>
                  <span className="text-gray-700">전신 근력 발달</span>
                </div>
                <div className="flex items-start gap-2 text-sm">
                  <span className="text-green-600">✓</span>
                  <span className="text-gray-700">심폐 기능 향상</span>
                </div>
                <div className="flex items-start gap-2 text-sm">
                  <span className="text-green-600">✓</span>
                  <span className="text-gray-700">체지방 감소</span>
                </div>
              </>
            )}
            {workout.type.includes('필라테스') && (
              <>
                <div className="flex items-start gap-2 text-sm">
                  <span className="text-green-600">✓</span>
                  <span className="text-gray-700">코어 근력 강화</span>
                </div>
                <div className="flex items-start gap-2 text-sm">
                  <span className="text-green-600">✓</span>
                  <span className="text-gray-700">자세 교정</span>
                </div>
                <div className="flex items-start gap-2 text-sm">
                  <span className="text-green-600">✓</span>
                  <span className="text-gray-700">유연성 향상</span>
                </div>
              </>
            )}
          </div>
        </div>

        {/* 코치 팁 */}
        <div className="bg-purple-50 rounded-xl border border-purple-200 p-4">
          <div className="flex items-start gap-2">
            <span className="text-xl">💪</span>
            <div>
              <div className="font-semibold text-purple-800 mb-1">트레이너 TIP</div>
              <p className="text-sm text-purple-700">
                훌륭한 운동이었습니다! 운동 후 충분한 수분 섭취와 스트레칭을 잊지 마세요. 
                꾸준한 운동이 건강한 몸을 만듭니다.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
