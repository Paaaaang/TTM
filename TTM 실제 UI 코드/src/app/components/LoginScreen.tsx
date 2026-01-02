import { Button } from './ui/button';
import { getTranslation, type Language } from '../utils/translations';

interface LoginScreenProps {
  logo: string;
  onLogin: () => void;
  onSignup: () => void;
  language?: Language;
}

export function LoginScreen({ logo, onLogin, onSignup, language = 'ko' }: LoginScreenProps) {
  const t = (key: any) => getTranslation(key, language);
  
  return (
    <div className="w-full max-w-md px-8 flex flex-col items-center">
      <div className="flex flex-col items-center mb-12">
        <img 
          src={logo} 
          alt="TAB TO ME" 
          className="w-64 h-64 mb-6 object-contain" 
          style={{ mixBlendMode: 'multiply' }}
        />
        <h1 className="text-2xl text-center text-gray-800 mb-2">{t('loginSubtitle')}</h1>
        <p className="text-center text-gray-600">
          {language === 'ko' && '음식 사진으로 영양정보를 확인하세요'}
          {language === 'en' && 'Check nutrition info with food photos'}
          {language === 'zh' && '通过食物照片查看营养信息'}
        </p>
      </div>

      <div className="w-full space-y-4">
        <Button 
          onClick={onLogin} 
          className="w-full h-14 bg-green-600 hover:bg-green-700 text-lg"
        >
          {t('login')}
        </Button>
        <Button 
          onClick={onSignup} 
          variant="outline"
          className="w-full h-14 border-2 border-green-600 text-green-600 hover:bg-green-50 text-lg"
        >
          {t('signup')}
        </Button>
      </div>
    </div>
  );
}