import { useState } from 'react';
import { ArrowLeft, Search, Plus, X } from 'lucide-react';

interface ExerciseDetailScreenProps {
  onBack: () => void;
  onSave: (exercises: any[]) => void;
}

// 운동 데이터베이스
const exerciseDatabase = [
  // 유산소 운동
  { 
    name: '걷기', 
    category: '유산소',
    durations: [
      { time: '10분', calories: 30 },
      { time: '20분', calories: 60 },
      { time: '30분', calories: 90 },
      { time: '60분', calories: 180 },
    ]
  },
  { 
    name: '빠르게 걷기', 
    category: '유산소',
    durations: [
      { time: '10분', calories: 50 },
      { time: '20분', calories: 100 },
      { time: '30분', calories: 150 },
      { time: '60분', calories: 300 },
    ]
  },
  { 
    name: '런닝', 
    category: '유산소',
    durations: [
      { time: '10분', calories: 80 },
      { time: '20분', calories: 160 },
      { time: '30분', calories: 240 },
      { time: '60분', calories: 480 },
    ]
  },
  { 
    name: '조깅', 
    category: '유산소',
    durations: [
      { time: '10분', calories: 60 },
      { time: '20분', calories: 120 },
      { time: '30분', calories: 180 },
      { time: '60분', calories: 360 },
    ]
  },
  { 
    name: '자전거', 
    category: '유산소',
    durations: [
      { time: '10분', calories: 50 },
      { time: '20분', calories: 100 },
      { time: '30분', calories: 150 },
      { time: '60분', calories: 300 },
    ]
  },
  { 
    name: '실내 자전거', 
    category: '유산소',
    durations: [
      { time: '10분', calories: 70 },
      { time: '20분', calories: 140 },
      { time: '30분', calories: 210 },
      { time: '60분', calories: 420 },
    ]
  },
  { 
    name: '수영', 
    category: '유산소',
    durations: [
      { time: '10분', calories: 90 },
      { time: '20분', calories: 180 },
      { time: '30분', calories: 270 },
      { time: '60분', calories: 540 },
    ]
  },
  { 
    name: '등산', 
    category: '유산소',
    durations: [
      { time: '30분', calories: 200 },
      { time: '60분', calories: 400 },
      { time: '120분', calories: 800 },
    ]
  },
  { 
    name: '줄넘기', 
    category: '유산소',
    durations: [
      { time: '5분', calories: 50 },
      { time: '10분', calories: 100 },
      { time: '15분', calories: 150 },
      { time: '30분', calories: 300 },
    ]
  },
  { 
    name: '계단 오르기', 
    category: '유산소',
    durations: [
      { time: '10분', calories: 70 },
      { time: '20분', calories: 140 },
      { time: '30분', calories: 210 },
    ]
  },
  { 
    name: '댄스', 
    category: '유산소',
    durations: [
      { time: '20분', calories: 120 },
      { time: '30분', calories: 180 },
      { time: '60분', calories: 360 },
    ]
  },
  { 
    name: '에어로빅', 
    category: '유산소',
    durations: [
      { time: '20분', calories: 140 },
      { time: '30분', calories: 210 },
      { time: '60분', calories: 420 },
    ]
  },
  // 근력 운동
  { 
    name: '웨이트 트레이닝', 
    category: '근력',
    durations: [
      { time: '30분', calories: 180 },
      { time: '60분', calories: 360 },
      { time: '90분', calories: 540 },
    ]
  },
  { 
    name: '벤치프레스', 
    category: '근력',
    durations: [
      { time: '20분', calories: 100 },
      { time: '30분', calories: 150 },
      { time: '45분', calories: 225 },
    ]
  },
  { 
    name: '스쿼트', 
    category: '근력',
    durations: [
      { time: '10분', calories: 60 },
      { time: '20분', calories: 120 },
      { time: '30분', calories: 180 },
    ]
  },
  { 
    name: '데드리프트', 
    category: '근력',
    durations: [
      { time: '20분', calories: 110 },
      { time: '30분', calories: 165 },
      { time: '45분', calories: 248 },
    ]
  },
  { 
    name: '팔굽혀펴기', 
    category: '근력',
    durations: [
      { time: '5분', calories: 30 },
      { time: '10분', calories: 60 },
      { time: '15분', calories: 90 },
    ]
  },
  { 
    name: '윗몸일으키기', 
    category: '근력',
    durations: [
      { time: '5분', calories: 25 },
      { time: '10분', calories: 50 },
      { time: '15분', calories: 75 },
    ]
  },
  { 
    name: '플랭크', 
    category: '근력',
    durations: [
      { time: '5분', calories: 30 },
      { time: '10분', calories: 60 },
      { time: '15분', calories: 90 },
    ]
  },
  { 
    name: '턱걸이', 
    category: '근력',
    durations: [
      { time: '5분', calories: 40 },
      { time: '10분', calories: 80 },
      { time: '15분', calories: 120 },
    ]
  },
  // 스트레칭/요가
  { 
    name: '요가', 
    category: '스트레칭',
    durations: [
      { time: '20분', calories: 60 },
      { time: '30분', calories: 90 },
      { time: '60분', calories: 180 },
    ]
  },
  { 
    name: '필라테스', 
    category: '스트레칭',
    durations: [
      { time: '30분', calories: 120 },
      { time: '60분', calories: 240 },
    ]
  },
  { 
    name: '스트레칭', 
    category: '스트레칭',
    durations: [
      { time: '10분', calories: 20 },
      { time: '15분', calories: 30 },
      { time: '30분', calories: 60 },
    ]
  },
  { 
    name: '체조', 
    category: '스트레칭',
    durations: [
      { time: '20분', calories: 80 },
      { time: '30분', calories: 120 },
      { time: '60분', calories: 240 },
    ]
  },
  // 스포츠
  { 
    name: '축구', 
    category: '스포츠',
    durations: [
      { time: '30분', calories: 240 },
      { time: '60분', calories: 480 },
      { time: '90분', calories: 720 },
    ]
  },
  { 
    name: '농구', 
    category: '스포츠',
    durations: [
      { time: '30분', calories: 220 },
      { time: '60분', calories: 440 },
    ]
  },
  { 
    name: '배드민턴', 
    category: '스포츠',
    durations: [
      { time: '30분', calories: 150 },
      { time: '60분', calories: 300 },
    ]
  },
  { 
    name: '테니스', 
    category: '스포츠',
    durations: [
      { time: '30분', calories: 180 },
      { time: '60분', calories: 360 },
    ]
  },
  { 
    name: '탁구', 
    category: '스포츠',
    durations: [
      { time: '30분', calories: 120 },
      { time: '60분', calories: 240 },
    ]
  },
  { 
    name: '야구', 
    category: '스포츠',
    durations: [
      { time: '60분', calories: 300 },
      { time: '90분', calories: 450 },
    ]
  },
  { 
    name: '골프', 
    category: '스포츠',
    durations: [
      { time: '60분', calories: 200 },
      { time: '120분', calories: 400 },
    ]
  },
  { 
    name: '배구', 
    category: '스포츠',
    durations: [
      { time: '30분', calories: 180 },
      { time: '60분', calories: 360 },
    ]
  },
];

export function ExerciseDetailScreen({ onBack, onSave }: ExerciseDetailScreenProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedExercises, setSelectedExercises] = useState<any[]>([]);
  const [showDurationModal, setShowDurationModal] = useState(false);
  const [currentExercise, setCurrentExercise] = useState<any>(null);

  const filteredExercises = searchQuery
    ? exerciseDatabase.filter(exercise => 
        exercise.name.includes(searchQuery) || exercise.category.includes(searchQuery)
      )
    : exerciseDatabase;

  const handleExerciseClick = (exercise: any) => {
    setCurrentExercise(exercise);
    setShowDurationModal(true);
  };

  const handleDurationSelect = (duration: any) => {
    const now = new Date();
    const timeString = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;
    
    const newExercise = {
      id: Date.now(),
      name: currentExercise.name,
      category: currentExercise.category,
      duration: duration.time,
      calories: duration.calories,
      time: timeString,
    };
    setSelectedExercises([...selectedExercises, newExercise]);
    setShowDurationModal(false);
    setCurrentExercise(null);
  };

  const handleRemoveExercise = (id: number) => {
    setSelectedExercises(selectedExercises.filter(e => e.id !== id));
  };

  const totalCalories = selectedExercises.reduce((sum, exercise) => sum + exercise.calories, 0);

  const categoryColors: any = {
    '유산소': 'bg-blue-50 text-blue-600',
    '근력': 'bg-orange-50 text-orange-600',
    '스트레칭': 'bg-purple-50 text-purple-600',
    '스포츠': 'bg-green-50 text-green-600',
  };

  return (
    <div className="w-full max-w-md h-screen bg-white flex flex-col">
      {/* 헤더 */}
      <div className="bg-gradient-to-r from-blue-500 to-blue-600 text-white p-4">
        <div className="flex items-center gap-3 mb-4">
          <button onClick={onBack} className="p-1 hover:bg-white/20 rounded-lg transition-colors">
            <ArrowLeft className="w-6 h-6" />
          </button>
          <h1 className="text-xl font-bold">운동 기록 추가</h1>
        </div>

        {/* 검색 바 */}
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            placeholder="운동을 검색하세요 (예: 런닝, 요가)"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-3 rounded-lg text-gray-800 placeholder-gray-400"
          />
        </div>
      </div>

      {/* 선택된 운동 목록 */}
      {selectedExercises.length > 0 && (
        <div className="bg-blue-50 p-4 border-b border-blue-100">
          <h3 className="font-semibold text-gray-800 mb-2">선택한 운동</h3>
          <div className="space-y-2">
            {selectedExercises.map((exercise) => (
              <div key={exercise.id} className="bg-white rounded-lg p-3 flex items-center justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <div className="font-semibold text-gray-800">{exercise.name}</div>
                    <span className={`text-xs px-2 py-0.5 rounded-full ${categoryColors[exercise.category]}`}>
                      {exercise.category}
                    </span>
                  </div>
                  <div className="text-sm text-gray-500">{exercise.duration} · -{exercise.calories} kcal</div>
                </div>
                <button
                  onClick={() => handleRemoveExercise(exercise.id)}
                  className="p-1 hover:bg-gray-100 rounded-full transition-colors"
                >
                  <X className="w-5 h-5 text-gray-500" />
                </button>
              </div>
            ))}
          </div>

          {/* 총 소모 칼로리 */}
          <div className="mt-3 bg-white rounded-lg p-3">
            <div className="flex items-center justify-between">
              <span className="text-gray-600">총 소모 칼로리</span>
              <span className="text-xl font-bold text-blue-600">-{totalCalories} kcal</span>
            </div>
          </div>
        </div>
      )}

      {/* 운동 검색 결과 */}
      <div className="flex-1 overflow-y-auto p-4">
        <h3 className="font-semibold text-gray-800 mb-3">운동 선택</h3>
        <div className="space-y-2">
          {filteredExercises.map((exercise, index) => (
            <button
              key={index}
              onClick={() => handleExerciseClick(exercise)}
              className="w-full bg-white border border-gray-200 rounded-lg p-4 text-left hover:border-blue-400 hover:shadow-sm transition-all"
            >
              <div className="flex items-center justify-between">
                <div>
                  <div className="font-semibold text-gray-800">{exercise.name}</div>
                  <div className="text-sm text-gray-500 mt-1">
                    {exercise.durations[0].time} · -{exercise.durations[0].calories} kcal
                  </div>
                </div>
                <span className={`text-xs px-2 py-1 rounded-full ${categoryColors[exercise.category]}`}>
                  {exercise.category}
                </span>
              </div>
            </button>
          ))}
        </div>
      </div>

      {/* 저장 버튼 */}
      <div className="p-4 border-t border-gray-200">
        <button
          onClick={() => onSave(selectedExercises)}
          disabled={selectedExercises.length === 0}
          className={`w-full py-4 rounded-lg font-semibold transition-colors ${
            selectedExercises.length > 0
              ? 'bg-blue-600 text-white hover:bg-blue-700'
              : 'bg-gray-200 text-gray-400 cursor-not-allowed'
          }`}
        >
          저장하기 (-{totalCalories} kcal)
        </button>
      </div>

      {/* 시간 선택 모달 */}
      {showDurationModal && currentExercise && (
        <div className="absolute inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl w-full max-w-sm overflow-hidden">
            <div className="bg-gradient-to-r from-blue-500 to-blue-600 text-white p-4">
              <div className="flex items-center justify-between mb-2">
                <h3 className="text-lg font-bold">{currentExercise.name}</h3>
                <button
                  onClick={() => setShowDurationModal(false)}
                  className="p-1 hover:bg-white/20 rounded-full transition-colors"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>
              <p className="text-sm text-white/90">운동 시간을 선택하세요</p>
            </div>

            <div className="p-4 space-y-2 max-h-96 overflow-y-auto">
              {currentExercise.durations.map((duration: any, index: number) => (
                <button
                  key={index}
                  onClick={() => handleDurationSelect(duration)}
                  className="w-full bg-gray-50 border border-gray-200 rounded-lg p-4 hover:border-blue-400 hover:bg-blue-50 transition-all text-left"
                >
                  <div className="flex items-center justify-between mb-2">
                    <span className="font-semibold text-gray-800">{duration.time}</span>
                    <span className="text-blue-600 font-bold">-{duration.calories} kcal</span>
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
