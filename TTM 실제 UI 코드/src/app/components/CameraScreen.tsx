import { useState, useRef } from 'react';
import { ArrowLeft, Camera, Image as ImageIcon, X, Sparkles } from 'lucide-react';
import { getTranslation, type Language } from '../utils/translations';
import { Button } from './ui/button';

interface CameraScreenProps {
  language: Language;
  onBack: () => void;
  onAnalysisComplete?: (result: FoodAnalysis) => void;
}

interface FoodAnalysis {
  foodName: string;
  calories: number;
  carbs: number;
  protein: number;
  fat: number;
  confidence: number;
}

export function CameraScreen({ language, onBack, onAnalysisComplete }: CameraScreenProps) {
  const t = (key: any) => getTranslation(key, language);
  const [selectedImage, setSelectedImage] = useState<string | null>(null);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [analysisResult, setAnalysisResult] = useState<FoodAnalysis | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleTakePhoto = () => {
    fileInputRef.current?.click();
  };

  const handleSelectFromAlbum = () => {
    fileInputRef.current?.click();
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = (event) => {
        setSelectedImage(event.target?.result as string);
        analyzeImage();
      };
      reader.readAsDataURL(file);
    }
  };

  const analyzeImage = () => {
    setIsAnalyzing(true);
    
    // AI 분석 시뮬레이션 (실제로는 API 호출)
    setTimeout(() => {
      const mockResults = [
        {
          foodName: language === 'ko' ? '김치찌개' : language === 'en' ? 'Kimchi Stew' : '泡菜汤',
          calories: 320,
          carbs: 25,
          protein: 18,
          fat: 15,
          confidence: 95,
        },
        {
          foodName: language === 'ko' ? '비빔밥' : language === 'en' ? 'Bibimbap' : '拌饭',
          calories: 560,
          carbs: 78,
          protein: 22,
          fat: 12,
          confidence: 92,
        },
        {
          foodName: language === 'ko' ? '치킨 샐러드' : language === 'en' ? 'Chicken Salad' : '鸡肉沙拉',
          calories: 280,
          carbs: 12,
          protein: 35,
          fat: 8,
          confidence: 88,
        },
        {
          foodName: language === 'ko' ? '연어 스테이크' : language === 'en' ? 'Salmon Steak' : '三文鱼排',
          calories: 420,
          carbs: 8,
          protein: 45,
          fat: 22,
          confidence: 90,
        },
      ];
      
      const randomResult = mockResults[Math.floor(Math.random() * mockResults.length)];
      setAnalysisResult(randomResult);
      setIsAnalyzing(false);
    }, 2000);
  };

  const handleRetry = () => {
    setSelectedImage(null);
    setAnalysisResult(null);
    setIsAnalyzing(false);
  };

  const handleSaveResult = () => {
    if (analysisResult && onAnalysisComplete) {
      onAnalysisComplete(analysisResult);
    }
    onBack();
  };

  return (
    <div className="w-full max-w-md h-screen bg-gradient-to-br from-green-50 to-blue-50 flex flex-col">
      {/* 헤더 */}
      <div className="bg-gradient-to-r from-green-500 to-green-600 text-white p-4">
        <div className="flex items-center justify-between">
          <button onClick={onBack} className="p-1 hover:bg-white/20 rounded-lg transition-colors">
            <ArrowLeft className="w-6 h-6" />
          </button>
          <h1 className="text-xl font-bold">{t('camera')}</h1>
          <div className="w-8"></div>
        </div>
      </div>

      {/* 메인 컨텐츠 */}
      <div className="flex-1 flex flex-col items-center justify-center p-6">
        {!selectedImage && !isAnalyzing && !analysisResult && (
          <div className="w-full space-y-6">
            {/* 카메라 아이콘 */}
            <div className="flex flex-col items-center mb-8">
              <div className="w-40 h-40 bg-gradient-to-br from-green-400 to-blue-500 rounded-full flex items-center justify-center shadow-2xl mb-6 animate-pulse">
                <Camera className="w-20 h-20 text-white" />
              </div>
              <h2 className="text-2xl font-bold text-gray-800 mb-2">
                {language === 'ko' && '음식 사진을 촬영하세요'}
                {language === 'en' && 'Take a Food Photo'}
                {language === 'zh' && '拍摄食物照片'}
              </h2>
              <p className="text-gray-600 text-center">
                {language === 'ko' && 'AI가 자동으로 칼로리와 영양 성분을 분석해드립니다'}
                {language === 'en' && 'AI will analyze calories and nutrients automatically'}
                {language === 'zh' && 'AI将自动分析卡路里和营养成分'}
              </p>
            </div>

            {/* 버튼들 */}
            <div className="space-y-4">
              <Button
                onClick={handleTakePhoto}
                className="w-full h-16 bg-gradient-to-r from-green-500 to-green-600 hover:from-green-600 hover:to-green-700 text-white shadow-lg"
              >
                <Camera className="w-6 h-6 mr-3" />
                <span className="text-lg">{t('takePhoto')}</span>
              </Button>

              <Button
                onClick={handleSelectFromAlbum}
                variant="outline"
                className="w-full h-16 border-2 border-green-500 text-green-700 hover:bg-green-50 shadow-md"
              >
                <ImageIcon className="w-6 h-6 mr-3" />
                <span className="text-lg">{t('selectFromAlbum')}</span>
              </Button>
            </div>

            {/* 히든 파일 인풋 */}
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              capture="environment"
              onChange={handleFileChange}
              className="hidden"
            />
          </div>
        )}

        {/* 이미지 분석 중 */}
        {isAnalyzing && (
          <div className="flex flex-col items-center">
            <div className="relative">
              {selectedImage && (
                <img
                  src={selectedImage}
                  alt="Selected food"
                  className="w-80 h-80 object-cover rounded-2xl shadow-2xl"
                />
              )}
              <div className="absolute inset-0 bg-black/40 rounded-2xl flex items-center justify-center">
                <div className="text-center text-white">
                  <Sparkles className="w-16 h-16 mx-auto mb-4 animate-spin" />
                  <p className="text-xl font-bold mb-2">
                    {language === 'ko' && 'AI 분석 중...'}
                    {language === 'en' && 'Analyzing...'}
                    {language === 'zh' && '分析中...'}
                  </p>
                  <p className="text-sm opacity-90">
                    {language === 'ko' && '잠시만 기다려주세요'}
                    {language === 'en' && 'Please wait a moment'}
                    {language === 'zh' && '请稍候'}
                  </p>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* 분석 결과 */}
        {analysisResult && !isAnalyzing && (
          <div className="w-full space-y-4">
            {/* 이미지 미리보기 */}
            <div className="relative">
              {selectedImage && (
                <img
                  src={selectedImage}
                  alt="Analyzed food"
                  className="w-full h-64 object-cover rounded-2xl shadow-lg"
                />
              )}
              <button
                onClick={handleRetry}
                className="absolute top-4 right-4 w-10 h-10 bg-white rounded-full flex items-center justify-center shadow-lg hover:bg-gray-100 transition-colors"
              >
                <X className="w-6 h-6 text-gray-700" />
              </button>
            </div>

            {/* 분석 결과 카드 */}
            <div className="bg-white rounded-2xl shadow-xl p-6 space-y-4">
              {/* 음식 이름과 신뢰도 */}
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-2xl font-bold text-gray-800">{analysisResult.foodName}</h3>
                <div className="flex items-center gap-1 bg-green-100 px-3 py-1 rounded-full">
                  <Sparkles className="w-4 h-4 text-green-600" />
                  <span className="text-sm font-semibold text-green-700">{analysisResult.confidence}%</span>
                </div>
              </div>

              {/* 칼로리 */}
              <div className="bg-gradient-to-r from-orange-100 to-red-100 rounded-xl p-4">
                <div className="flex items-center justify-between">
                  <span className="text-gray-700 font-medium">{t('calories')}</span>
                  <span className="text-3xl font-bold text-orange-600">{analysisResult.calories}</span>
                </div>
                <span className="text-sm text-gray-600">{t('kcal')}</span>
              </div>

              {/* 영양 성분 */}
              <div className="grid grid-cols-3 gap-3">
                <div className="bg-blue-50 rounded-xl p-3 text-center">
                  <p className="text-xs text-gray-600 mb-1">{t('carbs')}</p>
                  <p className="text-xl font-bold text-blue-600">{analysisResult.carbs}{t('gram')}</p>
                </div>
                <div className="bg-green-50 rounded-xl p-3 text-center">
                  <p className="text-xs text-gray-600 mb-1">{t('protein')}</p>
                  <p className="text-xl font-bold text-green-600">{analysisResult.protein}{t('gram')}</p>
                </div>
                <div className="bg-yellow-50 rounded-xl p-3 text-center">
                  <p className="text-xs text-gray-600 mb-1">{t('fat')}</p>
                  <p className="text-xl font-bold text-yellow-600">{analysisResult.fat}{t('gram')}</p>
                </div>
              </div>

              {/* 버튼들 */}
              <div className="flex gap-3 mt-6">
                <Button
                  onClick={handleRetry}
                  variant="outline"
                  className="flex-1 h-12 border-2 border-gray-300 text-gray-700 hover:bg-gray-50"
                >
                  {language === 'ko' && '다시 촬영'}
                  {language === 'en' && 'Retake'}
                  {language === 'zh' && '重新拍摄'}
                </Button>
                <Button
                  onClick={handleSaveResult}
                  className="flex-1 h-12 bg-gradient-to-r from-green-500 to-green-600 hover:from-green-600 hover:to-green-700"
                >
                  {t('save')}
                </Button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
