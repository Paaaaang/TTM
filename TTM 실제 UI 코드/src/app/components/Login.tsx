import { useState } from 'react';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Eye, EyeOff, ArrowLeft } from 'lucide-react';
import { KakaoIcon, NaverIcon, GoogleIcon } from './SocialIcons';
import { getKakaoAuthUrl, getNaverAuthUrl, getGoogleAuthUrl } from '../../config/oauth';
import { getTranslation, type Language } from '../utils/translations';

interface LoginProps {
  logo: string;
  onBack: () => void;
  onLoginSuccess: (nickname: string) => void;
  language: Language;
}

export function Login({ logo, onBack, onLoginSuccess, language }: LoginProps) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  
  const t = (key: any) => getTranslation(key, language);

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    
    // localStorage에서 사용자 목록 가져오기
    const users = JSON.parse(localStorage.getItem('users') || '[]');
    
    // 아이디와 비밀번호 확인
    const user = users.find((u: any) => u.username === username && u.password === password);
    
    if (user) {
      // 로그인 성공
      localStorage.setItem('currentUser', JSON.stringify(user));
      alert(`${user.nickname}${t('loginSuccessMessage')}`);
      onLoginSuccess(user.nickname);
    } else {
      alert(t('loginError'));
    }
  };

  const handleKakaoLogin = () => {
    const authUrl = getKakaoAuthUrl();
    window.location.href = authUrl;
  };

  const handleNaverLogin = () => {
    const authUrl = getNaverAuthUrl();
    window.location.href = authUrl;
  };

  const handleGoogleLogin = () => {
    const authUrl = getGoogleAuthUrl();
    window.location.href = authUrl;
  };

  return (
    <div className="w-full max-w-md px-8 flex flex-col">
      <button 
        onClick={onBack}
        className="flex items-center gap-2 text-gray-600 hover:text-gray-800 mb-8"
      >
        <ArrowLeft className="w-5 h-5" />
        <span>{t('back')}</span>
      </button>

      <div className="flex flex-col items-center mb-8">
        <img 
          src={logo} 
          alt="TAB TO ME" 
          className="w-40 h-40 mb-4 object-contain" 
          style={{ mixBlendMode: 'multiply' }}
        />
        <h1 className="text-2xl text-center text-gray-800">{t('login')}</h1>
      </div>

      <form onSubmit={handleLogin} className="space-y-6">
        <div className="space-y-2">
          <Label htmlFor="username">{t('username')}</Label>
          <Input
            id="username"
            type="text"
            placeholder={t('username')}
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            required
            className="h-12"
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="password">{t('password')}</Label>
          <div className="relative">
            <Input
              id="password"
              type={showPassword ? 'text' : 'password'}
              placeholder={t('password')}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              className="h-12 pr-12"
            />
            <button
              type="button"
              onClick={() => setShowPassword(!showPassword)}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-700"
            >
              {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
            </button>
          </div>
        </div>

        <Button type="submit" className="w-full h-12 bg-green-600 hover:bg-green-700">
          {t('loginButton')}
        </Button>
      </form>

      <div className="flex items-center gap-4 my-6">
        <div className="flex-1 h-px bg-gray-300"></div>
        <span className="text-gray-500 text-sm">{t('or')}</span>
        <div className="flex-1 h-px bg-gray-300"></div>
      </div>

      <div className="space-y-3">
        <Button 
          type="button"
          onClick={handleKakaoLogin}
          className="w-full h-12 bg-[#FEE500] hover:bg-[#FDD835] text-black border-0"
          variant="outline"
        >
          <KakaoIcon className="mr-2" />
          {language === 'ko' && `${t('kakao')} ${t('loginWith')}`}
          {language === 'en' && `${t('loginWith')} ${t('kakao')}`}
          {language === 'zh' && `${t('loginWith')}${t('kakao')}${language === 'zh' ? '登录' : ''}`}
        </Button>

        <Button 
          type="button"
          onClick={handleNaverLogin}
          className="w-full h-12 bg-[#03C75A] hover:bg-[#02b350] text-white border-0"
          variant="outline"
        >
          <NaverIcon className="mr-2 font-bold" />
          {language === 'ko' && `${t('naver')} ${t('loginWith')}`}
          {language === 'en' && `${t('loginWith')} ${t('naver')}`}
          {language === 'zh' && `${t('loginWith')}${t('naver')}${language === 'zh' ? '登录' : ''}`}
        </Button>

        <Button 
          type="button"
          onClick={handleGoogleLogin}
          className="w-full h-12 bg-white hover:bg-gray-50 text-gray-700 border-2 border-gray-300"
          variant="outline"
        >
          <GoogleIcon className="mr-2" />
          {language === 'ko' && `${t('google')} ${t('loginWith')}`}
          {language === 'en' && `${t('loginWith')} ${t('google')}`}
          {language === 'zh' && `${t('loginWith')}${t('google')}${language === 'zh' ? '登录' : ''}`}
        </Button>
      </div>
    </div>
  );
}