import { useState } from 'react';
import { Label } from './ui/label';
import { ArrowLeft } from 'lucide-react';

interface UserInfoStep2Props {
  onNext: (data: { conditions: string[] }) => void;
  onBack: () => void;
}

const healthConditions = [
  { id: 'hypertension', label: '고혈압' },
  { id: 'diabetes', label: '당뇨' },
  { id: 'obesity', label: '비만' },
  { id: 'hyperlipidemia', label: '고지혈증' },
  { id: 'heart-disease', label: '심장 질환' },
  { id: 'kidney-disease', label: '신장 질환' },
  { id: 'allergy', label: '알러지' },
  { id: 'none', label: '해당 없음' },
];

export function UserInfoStep2({ onNext, onBack }: UserInfoStep2Props) {
  const [selectedConditions, setSelectedConditions] = useState<string[]>([]);

  const toggleCondition = (conditionId: string) => {
    // "해당 없음" 선택 시 다른 선택 모두 해제
    if (conditionId === 'none') {
      setSelectedConditions(selectedConditions.includes('none') ? [] : ['none']);
      return;
    }

    // 다른 항목 선택 시 "해당 없음" 해제
    const newConditions = selectedConditions.filter(id => id !== 'none');
    
    if (newConditions.includes(conditionId)) {
      setSelectedConditions(newConditions.filter(id => id !== conditionId));
    } else {
      setSelectedConditions([...newConditions, conditionId]);
    }
  };

  const handleNext = () => {
    onNext({ conditions: selectedConditions });
  };

  return (
    <div className="w-full max-w-md px-8 flex flex-col h-full justify-between py-8">
      {/* 중앙 컨텐츠 */}
      <div className="flex flex-col justify-center flex-1 space-y-8">
        <div className="text-center mb-4">
          <h2 className="text-2xl text-gray-800 mb-2">질병 유무를 알려주세요</h2>
          <p className="text-gray-600">맞춤 영양 관리를 위해 필요해요</p>
          <p className="text-sm text-gray-500 mt-2">중복 선택 가능</p>
        </div>

        {/* 질병 선택 */}
        <div className="space-y-3">
          <div className="grid grid-cols-2 gap-3">
            {healthConditions.map((condition) => (
              <button
                key={condition.id}
                type="button"
                onClick={() => toggleCondition(condition.id)}
                className={`h-14 rounded-lg border-2 transition-all ${
                  selectedConditions.includes(condition.id)
                    ? 'border-green-600 bg-green-50 text-green-700 font-semibold'
                    : 'border-gray-300 bg-white text-gray-700 hover:border-gray-400'
                }`}
              >
                {condition.label}
              </button>
            ))}
          </div>
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

      {/* 뒤로 가기 버튼 */}
      <div className="w-full mt-4">
        <button
          onClick={onBack}
          className="w-full h-14 bg-gray-300 hover:bg-gray-400 text-gray-700 rounded-lg transition-colors font-medium"
        >
          <ArrowLeft className="w-5 h-5 mr-2 inline-block" />
          뒤로 가기
        </button>
      </div>
    </div>
  );
}