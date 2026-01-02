import { useState } from 'react';
import { MoonStar, Moon, BedSingle, Bed, ArrowLeft } from 'lucide-react';

interface UserInfoStep4Props {
  onNext: (data: { sleepHours: string }) => void;
  onBack: () => void;
}

const sleepLevels = [
  { 
    id: 'low', 
    label: '5시간 이하',
    description: '수면이 부족해요',
    icon: MoonStar,
    iconClass: 'text-red-500'
  },
  { 
    id: 'normal', 
    label: '6-7시간',
    description: '적당한 수면',
    icon: Moon,
    iconClass: 'text-blue-500'
  },
  { 
    id: 'good', 
    label: '8시간',
    description: '충분한 수면',
    icon: BedSingle,
    iconClass: 'text-green-600'
  },
  { 
    id: 'high', 
    label: '9시간 이상',
    description: '많은 수면',
    icon: Bed,
    iconClass: 'text-purple-500'
  },
];

export function UserInfoStep4({ onNext, onBack }: UserInfoStep4Props) {
  const [selectedLevel, setSelectedLevel] = useState<string>('');

  const handleNext = () => {
    if (!selectedLevel) {
      alert('수면시간을 선택해주세요.');
      return;
    }

    onNext({ sleepHours: selectedLevel });
  };

  return (
    <div className="w-full max-w-md px-8 flex flex-col h-full justify-between py-8">
      {/* 중앙 컨텐츠 */}
      <div className="flex flex-col justify-center flex-1 space-y-8">
        <div className="text-center mb-4">
          <h2 className="text-2xl text-gray-800 mb-2">수면시간을 알려주세요</h2>
          <p className="text-gray-600">건강한 생활 관리를 도와드려요</p>
        </div>

        {/* 수면시간 선택 */}
        <div className="space-y-4">
          {sleepLevels.map((level) => {
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