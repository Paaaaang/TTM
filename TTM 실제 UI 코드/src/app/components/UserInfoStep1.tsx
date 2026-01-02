import { useState } from 'react';
import { Input } from './ui/input';
import { Label } from './ui/label';

interface UserInfoStep1Props {
  onNext: (data: { gender: 'male' | 'female'; height: string; weight: string }) => void;
}

export function UserInfoStep1({ onNext }: UserInfoStep1Props) {
  const [gender, setGender] = useState<'male' | 'female' | ''>('');
  const [height, setHeight] = useState('');
  const [weight, setWeight] = useState('');

  const handleNext = () => {
    if (!gender || !height || !weight) {
      alert('모든 항목을 입력해주세요.');
      return;
    }

    onNext({ gender, height, weight });
  };

  return (
    <div className="w-full max-w-md px-8 flex flex-col h-full justify-between py-8">
      {/* 중앙 컨텐츠 */}
      <div className="flex flex-col justify-center flex-1 space-y-8">
        <div className="text-center mb-8">
          <h2 className="text-2xl text-gray-800 mb-2">기본 정보를 알려주세요</h2>
          <p className="text-gray-600">더 정확한 영양 분석을 위해 필요해요</p>
        </div>

        {/* 성별 선택 */}
        <div className="space-y-3">
          <Label>성별</Label>
          <div className="grid grid-cols-2 gap-4">
            <button
              type="button"
              onClick={() => setGender('male')}
              className={`h-14 rounded-lg border-2 transition-all ${
                gender === 'male'
                  ? 'border-green-600 bg-green-50 text-green-700 font-semibold'
                  : 'border-gray-300 bg-white text-gray-700 hover:border-gray-400'
              }`}
            >
              남성
            </button>
            <button
              type="button"
              onClick={() => setGender('female')}
              className={`h-14 rounded-lg border-2 transition-all ${
                gender === 'female'
                  ? 'border-green-600 bg-green-50 text-green-700 font-semibold'
                  : 'border-gray-300 bg-white text-gray-700 hover:border-gray-400'
              }`}
            >
              여성
            </button>
          </div>
        </div>

        {/* 키 입력 */}
        <div className="space-y-2">
          <Label htmlFor="height">키 (cm)</Label>
          <Input
            id="height"
            type="number"
            placeholder="예: 170"
            value={height}
            onChange={(e) => setHeight(e.target.value)}
            className="h-12"
          />
        </div>

        {/* 몸무게 입력 */}
        <div className="space-y-2">
          <Label htmlFor="weight">몸무게 (kg)</Label>
          <Input
            id="weight"
            type="number"
            placeholder="예: 65"
            value={weight}
            onChange={(e) => setWeight(e.target.value)}
            className="h-12"
          />
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
    </div>
  );
}
