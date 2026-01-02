import { getTranslation, type Language } from '../utils/translations';

interface WelcomeProps {
  logo: string;
  nickname: string;
  onNext: () => void;
  onSkip: () => void;
  language?: Language;
}

export function Welcome({ logo, nickname, onNext, onSkip, language = 'ko' }: WelcomeProps) {
  const t = (key: any) => getTranslation(key, language);
  
  return (
    <div className="w-full max-w-md px-8 flex flex-col h-full justify-between py-8">
      {/* 오른쪽 상단 - 다음에 할게요 버튼 */}
      <div className="flex justify-end">
        <button
          onClick={onSkip}
          className="text-gray-500 hover:text-gray-700 underline underline-offset-4 transition-colors"
        >
          {t('skipOnboarding')}
        </button>
      </div>

      {/* 중앙 컨텐츠 */}
      <div className="flex flex-col items-center justify-center flex-1">
        <div className="text-center space-y-6">
          <h1 className="text-3xl text-gray-800">
            {language === 'ko' && <><span className="font-semibold">{nickname}</span>님 환영합니다!</>}
            {language === 'en' && <>Welcome, <span className="font-semibold">{nickname}</span>!</>}
            {language === 'zh' && <><span className="font-semibold">{nickname}</span>，欢迎！</>}
          </h1>
          
          <div className="flex flex-col items-center gap-4">
            <p className="text-gray-700 leading-relaxed">
              <span className="font-bold text-2xl text-green-600">{t('appName')}</span>
              {language === 'ko' && '를 시작하기 전에'}
              {language === 'en' && ' - Before we start'}
              {language === 'zh' && ' - 开始之前'}
            </p>
            <p className="text-gray-700 leading-relaxed">
              {t('welcomeDescription')}
            </p>
          </div>
        </div>
      </div>

      {/* 하단 - 다음 버튼 */}
      <div className="w-full">
        <button
          onClick={onNext}
          className="w-full h-14 bg-green-600 hover:bg-green-700 text-white rounded-lg transition-colors font-medium"
        >
          {t('next')}
        </button>
      </div>
    </div>
  );
}