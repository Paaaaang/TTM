import { useState } from 'react';
import { Dumbbell, Activity, HeartPulse, Bike, ArrowLeft } from 'lucide-react';

interface UserInfoStep3Props {
  onNext: (data: { exerciseLevel: string }) => void;
  onBack: () => void;
}

const exerciseLevels = [
  { 
    id: 'none', 
    label: '아예 안함',
    description: '운동을 하지 않아요',
    icon: Dumbbell,
    iconClass: 'opacity-30'
  },
  { 
    id: 'light', 
    label: '주 1-2회',
    description: '거의 안함',
    icon: Activity,
    iconClass: 'text-blue-500'
  },
  { 
    id: 'moderate', 
    label: '주 3-4회',
    description: '자주함',
    icon: HeartPulse,
    iconClass: 'text-orange-500'
  },
  { 
    id: 'active', 
    label: '매일',
    description: '꾸준히 운동해요',
    icon: Bike,
    iconClass: 'text-green-600'
  },
];

export function UserInfoStep3({ onNext, onBack }: UserInfoStep3Props) {
  const [selectedLevel, setSelectedLevel] = useState<string>('');

  const handleNext = () => {
    if (!selectedLevel) {
      alert('운동량을 선택해주세요.');
      return;
    }

    onNext({ exerciseLevel: selectedLevel });
  };

  return (
    <div className="w-full max-w-md px-8 flex flex-col h-full justify-between py-8">
      {/* 중앙 컨텐츠 */}
      <div className="flex flex-col justify-center flex-1 space-y-8">
        <div className="text-center mb-4">
          <h2 className="text-2xl text-gray-800 mb-2">운동량을 알려주세요</h2>
          <p className="text-gray-600">맞춤 칼로리 계산을 도와드려요</p>
        </div>

        {/* 운동량 선택 */}
        <div className="space-y-4">
          {exerciseLevels.map((level) => {
            const IconComponent = level.icon;
            return (
              <button
                key={level.id}
                type="button"
                onClick={() => setSelectedLevel(level.id)}
                className={`w-full p-5 rounded-xl border-2 transition-all flex items-center gap-4 ${
                  selectedLevel === level.id
                    ? 'border-green-600 bg-green-50 shadow-md'
                    : 'border-gray-300 bg-white hover:border-gray-400 hover:shadow-sm'
                }`}
              >
                <div className={`p-3 rounded-full bg-gray-50 ${selectedLevel === level.id ? 'bg-white' : ''}`}>
                  <IconComponent 
                    className={`w-8 h-8 ${selectedLevel === level.id ? 'text-green-600' : level.iconClass}`} 
                  />
                </div>
                <div className="flex-1 text-left">
                  <div className={`font-semibold ${selectedLevel === level.id ? 'text-green-700' : 'text-gray-800'}`}>
                    {level.label}
                  </div>
                  <div className="text-sm text-gray-600">
                    {level.description}
                  </div>
                </div>
              </button>
            );
          })}
        </div>
      </div>

      {/* 하단 - 다음 버튼 */}
      <div className="w-full">
        <button
          onClick={handleNext}
          className="w-full h-14 bg-green-600 hover:bg-green-700 text-white rounded-lg transition-colors font-medium"
        >
          다음
        </button>
      </div>

      {/* 뒤로가기 버튼 */}
      <div className="w-full mt-4">
        <button
          onClick={onBack}
          className="w-full h-14 bg-gray-300 hover:bg-gray-400 text-gray-800 rounded-lg transition-colors font-medium"
        >
          <ArrowLeft className="w-5 h-5 mr-2 inline-block" />
          뒤로가기
        </button>
      </div>
    </div>
  );
}