import { useState } from 'react';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Checkbox } from './ui/checkbox';
import { Eye, EyeOff, ArrowLeft, ChevronRight } from 'lucide-react';

interface SignupProps {
  logo: string;
  onBack: () => void;
  onSignupComplete: (nickname: string) => void;
}

export function Signup({ logo, onBack, onSignupComplete }: SignupProps) {
  const [nickname, setNickname] = useState('');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [passwordConfirm, setPasswordConfirm] = useState('');
  
  // 핸드폰 번호 분리
  const [phonePrefix, setPhonePrefix] = useState('010');
  const [phoneMiddle, setPhoneMiddle] = useState('');
  const [phoneLast, setPhoneLast] = useState('');
  
  // 생년월일 분리
  const [birthYear, setBirthYear] = useState('');
  const [birthMonth, setBirthMonth] = useState('');
  const [birthDay, setBirthDay] = useState('');
  
  // 이메일 분리
  const [emailId, setEmailId] = useState('');
  const [emailDomain, setEmailDomain] = useState('');
  const [emailDomainType, setEmailDomainType] = useState('직접입력');
  
  const [showPassword, setShowPassword] = useState(false);
  const [showPasswordConfirm, setShowPasswordConfirm] = useState(false);

  // 동의 항목
  const [agreeAll, setAgreeAll] = useState(false);
  const [agreeTerms, setAgreeTerms] = useState(false);
  const [agreePrivacy, setAgreePrivacy] = useState(false);
  const [agreeSensitive, setAgreeSensitive] = useState(false);
  const [agreeMarketing, setAgreeMarketing] = useState(false);

  // 이벤트 수신동의 세부 항목
  const [agreeKakao, setAgreeKakao] = useState(false);
  const [agreePush, setAgreePush] = useState(false);
  const [agreeSms, setAgreeSms] = useState(false);
  const [agreeEmail, setAgreeEmail] = useState(false);

  const handleSignup = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!agreeTerms || !agreePrivacy || !agreeSensitive) {
      alert('필수 약관에 동의해주세요.');
      return;
    }

    if (password !== passwordConfirm) {
      alert('비밀번호가 일치하지 않습니다.');
      return;
    }

    // localStorage에 회원 정보 저장
    const today = new Date();
    const joinDate = `${today.getFullYear()}.${String(today.getMonth() + 1).padStart(2, '0')}.${String(today.getDate()).padStart(2, '0')}`;
    
    const userData = {
      nickname,
      username,
      password,
      phone: `${phonePrefix}-${phoneMiddle}-${phoneLast}`,
      birthdate: `${birthYear}-${birthMonth}-${birthDay}`,
      email: `${emailId}@${emailDomain}`,
      joinDate,
      agreeTerms,
      agreePrivacy,
      agreeSensitive,
      agreeMarketing,
      agreeKakao,
      agreePush,
      agreeSms,
      agreeEmail
    };

    // 기존 사용자 목록 가져오기
    const existingUsers = JSON.parse(localStorage.getItem('users') || '[]');
    
    // 중복 아이디 확인
    if (existingUsers.some((user: any) => user.username === username)) {
      alert('이미 존재하는 아이디입니다.');
      return;
    }

    // 새 사용자 추가
    existingUsers.push(userData);
    localStorage.setItem('users', JSON.stringify(existingUsers));

    console.log('회원가입 완료:', userData);

    // 회원가입 완료 후 환영 화면으로 이동
    onSignupComplete(nickname);
  };

  const handleCancel = () => {
    onBack();
  };

  // 모두 동의 처리
  const handleAgreeAll = (checked: boolean) => {
    setAgreeAll(checked);
    setAgreeTerms(checked);
    setAgreePrivacy(checked);
    setAgreeSensitive(checked);
    setAgreeMarketing(checked);
    if (checked) {
      setAgreeKakao(true);
      setAgreePush(true);
      setAgreeSms(true);
      setAgreeEmail(true);
    } else {
      setAgreeKakao(false);
      setAgreePush(false);
      setAgreeSms(false);
      setAgreeEmail(false);
    }
  };

  // 이벤트 수신동의 전체 선택/해제
  const handleMarketingChange = (checked: boolean) => {
    setAgreeMarketing(checked);
    if (checked) {
      setAgreeKakao(true);
      setAgreePush(true);
      setAgreeSms(true);
      setAgreeEmail(true);
    } else {
      setAgreeKakao(false);
      setAgreePush(false);
      setAgreeSms(false);
      setAgreeEmail(false);
    }
  };

  // 이메일 도메인 타입 변경 시
  const handleEmailDomainTypeChange = (value: string) => {
    setEmailDomainType(value);
    if (value !== '직접입력') {
      setEmailDomain(value);
    } else {
      setEmailDomain('');
    }
  };

  // 년도, 월, 일 옵션 생성
  const currentYear = new Date().getFullYear();
  const years = Array.from({ length: 100 }, (_, i) => currentYear - i);
  const months = Array.from({ length: 12 }, (_, i) => i + 1);
  const days = Array.from({ length: 31 }, (_, i) => i + 1);

  // 약관 상세보기
  const handleViewTerms = (type: string) => {
    alert(`${type} 내용을 보여줍니다.`);
  };

  return (
    <div className="w-full max-w-md px-8 flex flex-col py-8">
      <button 
        onClick={onBack}
        className="flex items-center gap-2 text-gray-600 hover:text-gray-800 mb-6"
      >
        <ArrowLeft className="w-5 h-5" />
        <span>뒤로가기</span>
      </button>

      <div className="flex flex-col items-center mb-6">
        <img 
          src={logo} 
          alt="TAB TO ME" 
          className="w-32 h-32 mb-3 object-contain" 
          style={{ mixBlendMode: 'multiply' }}
        />
        <h1 className="text-2xl text-center text-gray-800">회원가입</h1>
      </div>

      <form onSubmit={handleSignup} className="space-y-5">
        {/* 닉네임 */}
        <div className="space-y-2">
          <Label htmlFor="nickname">닉네임</Label>
          <Input
            id="nickname"
            type="text"
            placeholder="닉네임을 입력하세요"
            value={nickname}
            onChange={(e) => setNickname(e.target.value)}
            required
            className="h-11"
          />
        </div>

        {/* 아이디 */}
        <div className="space-y-2">
          <Label htmlFor="username">아이디</Label>
          <Input
            id="username"
            type="text"
            placeholder="아이디를 입력하세요"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            required
            className="h-11"
          />
        </div>

        {/* 비밀번호 */}
        <div className="space-y-2">
          <Label htmlFor="password">비밀번호</Label>
          <div className="relative">
            <Input
              id="password"
              type={showPassword ? 'text' : 'password'}
              placeholder="비밀번호를 입력하세요"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              className="h-11 pr-12"
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

        {/* 비밀번호 확인 */}
        <div className="space-y-2">
          <Label htmlFor="password-confirm">비밀번호 확인</Label>
          <div className="relative">
            <Input
              id="password-confirm"
              type={showPasswordConfirm ? 'text' : 'password'}
              placeholder="비밀번호를 다시 입력하세요"
              value={passwordConfirm}
              onChange={(e) => setPasswordConfirm(e.target.value)}
              required
              className="h-11 pr-12"
            />
            <button
              type="button"
              onClick={() => setShowPasswordConfirm(!showPasswordConfirm)}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-700"
            >
              {showPasswordConfirm ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
            </button>
          </div>
        </div>

        {/* 핸드폰번호 */}
        <div className="space-y-2">
          <Label htmlFor="phone">핸드폰번호</Label>
          <div className="flex items-center gap-2">
            <select
              id="phone-prefix"
              value={phonePrefix}
              onChange={(e) => setPhonePrefix(e.target.value)}
              required
              className="h-11 px-3 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
            >
              <option value="010">010</option>
              <option value="011">011</option>
              <option value="016">016</option>
              <option value="017">017</option>
              <option value="018">018</option>
              <option value="019">019</option>
            </select>
            <span className="text-gray-400">-</span>
            <Input
              id="phone-middle"
              type="tel"
              placeholder="0000"
              value={phoneMiddle}
              onChange={(e) => setPhoneMiddle(e.target.value.replace(/\D/g, '').slice(0, 4))}
              maxLength={4}
              required
              className="h-11 flex-1"
            />
            <span className="text-gray-400">-</span>
            <Input
              id="phone-last"
              type="tel"
              placeholder="0000"
              value={phoneLast}
              onChange={(e) => setPhoneLast(e.target.value.replace(/\D/g, '').slice(0, 4))}
              maxLength={4}
              required
              className="h-11 flex-1"
            />
          </div>
        </div>

        {/* 생년월일 */}
        <div className="space-y-2">
          <Label htmlFor="birthdate">생년월일</Label>
          <div className="flex items-center gap-2">
            <select
              id="birth-year"
              value={birthYear}
              onChange={(e) => setBirthYear(e.target.value)}
              required
              className="h-11 px-3 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500 flex-1"
            >
              <option value="">년</option>
              {years.map(year => (
                <option key={year} value={year}>{year}</option>
              ))}
            </select>
            <span className="text-gray-400">-</span>
            <select
              id="birth-month"
              value={birthMonth}
              onChange={(e) => setBirthMonth(e.target.value)}
              required
              className="h-11 px-3 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500 flex-1"
            >
              <option value="">월</option>
              {months.map(month => (
                <option key={month} value={String(month).padStart(2, '0')}>{month}월</option>
              ))}
            </select>
            <span className="text-gray-400">-</span>
            <select
              id="birth-day"
              value={birthDay}
              onChange={(e) => setBirthDay(e.target.value)}
              required
              className="h-11 px-3 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500 flex-1"
            >
              <option value="">일</option>
              {days.map(day => (
                <option key={day} value={String(day).padStart(2, '0')}>{day}일</option>
              ))}
            </select>
          </div>
        </div>

        {/* 이메일 */}
        <div className="space-y-2">
          <Label htmlFor="email">이메일</Label>
          <div className="flex items-center gap-2">
            <Input
              id="email-id"
              type="text"
              placeholder="example"
              value={emailId}
              onChange={(e) => setEmailId(e.target.value)}
              required
              className="h-11 flex-1"
            />
            <span className="text-gray-400">@</span>
            <Input
              id="email-domain"
              type="text"
              placeholder="domain.com"
              value={emailDomain}
              onChange={(e) => setEmailDomain(e.target.value)}
              required
              className="h-11 flex-1"
              disabled={emailDomainType !== '직접입력'}
            />
            <select
              id="email-domain-type"
              value={emailDomainType}
              onChange={(e) => handleEmailDomainTypeChange(e.target.value)}
              className="h-11 px-3 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
            >
              <option value="직접입력">직접입력</option>
              <option value="naver.com">naver.com</option>
              <option value="gmail.com">gmail.com</option>
              <option value="daum.net">daum.net</option>
              <option value="kakao.com">kakao.com</option>
              <option value="hanmail.net">hanmail.net</option>
            </select>
          </div>
        </div>

        {/* 개인정보수집동의란 */}
        <div className="space-y-3 pt-4 border-t border-gray-200">
          <h3 className="font-medium text-gray-800">개인정보수집동의</h3>
          
          {/* 전체 동의 */}
          <div className="flex items-center justify-between p-3 bg-green-50 rounded-lg">
            <div className="flex items-center space-x-2">
              <Checkbox 
                id="agree-all" 
                checked={agreeAll}
                onCheckedChange={(checked) => handleAgreeAll(checked as boolean)}
              />
              <label
                htmlFor="agree-all"
                className="font-semibold leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70 text-green-700"
              >
                전체 동의
              </label>
            </div>
          </div>
          
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <Checkbox 
                id="terms" 
                checked={agreeTerms}
                onCheckedChange={(checked) => setAgreeTerms(checked as boolean)}
              />
              <label
                htmlFor="terms"
                className="text-sm leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
              >
                이용약관동의 <span className="text-red-500">(필수)</span>
              </label>
            </div>
            <button
              type="button"
              onClick={() => handleViewTerms('이용약관')}
              className="text-gray-500 hover:text-gray-700"
            >
              <ChevronRight className="w-5 h-5" />
            </button>
          </div>

          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <Checkbox 
                id="privacy" 
                checked={agreePrivacy}
                onCheckedChange={(checked) => setAgreePrivacy(checked as boolean)}
              />
              <label
                htmlFor="privacy"
                className="text-sm leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
              >
                개인정보수집 및 동의 <span className="text-red-500">(필수)</span>
              </label>
            </div>
            <button
              type="button"
              onClick={() => handleViewTerms('개인정보수집 및 이용')}
              className="text-gray-500 hover:text-gray-700"
            >
              <ChevronRight className="w-5 h-5" />
            </button>
          </div>

          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <Checkbox 
                id="sensitive" 
                checked={agreeSensitive}
                onCheckedChange={(checked) => setAgreeSensitive(checked as boolean)}
              />
              <label
                htmlFor="sensitive"
                className="text-sm leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
              >
                민감정보 수집동의 <span className="text-red-500">(필수)</span>
              </label>
            </div>
            <button
              type="button"
              onClick={() => handleViewTerms('민감정보 수집')}
              className="text-gray-500 hover:text-gray-700"
            >
              <ChevronRight className="w-5 h-5" />
            </button>
          </div>

          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <Checkbox 
                id="marketing" 
                checked={agreeMarketing}
                onCheckedChange={(checked) => handleMarketingChange(checked as boolean)}
              />
              <label
                htmlFor="marketing"
                className="text-sm leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
              >
                이벤트 수신동의 <span className="text-gray-500">(선택)</span>
              </label>
            </div>
            <button
              type="button"
              onClick={() => handleViewTerms('이벤트 수신동의')}
              className="text-gray-500 hover:text-gray-700"
            >
              <ChevronRight className="w-5 h-5" />
            </button>
          </div>

          {/* 이벤트 수신동의 세부 항목 */}
          <div className="ml-8 space-y-2 border-l-2 border-gray-200 pl-4">
            <div className="flex items-center space-x-2">
              <Checkbox 
                id="kakao" 
                checked={agreeKakao}
                onCheckedChange={(checked) => setAgreeKakao(checked as boolean)}
              />
              <label
                htmlFor="kakao"
                className="text-sm text-gray-600 leading-none"
              >
                카카오톡
              </label>
            </div>

            <div className="flex items-center space-x-2">
              <Checkbox 
                id="push" 
                checked={agreePush}
                onCheckedChange={(checked) => setAgreePush(checked as boolean)}
              />
              <label
                htmlFor="push"
                className="text-sm text-gray-600 leading-none"
              >
                Push 알림
              </label>
            </div>

            <div className="flex items-center space-x-2">
              <Checkbox 
                id="sms" 
                checked={agreeSms}
                onCheckedChange={(checked) => setAgreeSms(checked as boolean)}
              />
              <label
                htmlFor="sms"
                className="text-sm text-gray-600 leading-none"
              >
                문자(SMS)
              </label>
            </div>

            <div className="flex items-center space-x-2">
              <Checkbox 
                id="email-marketing" 
                checked={agreeEmail}
                onCheckedChange={(checked) => setAgreeEmail(checked as boolean)}
              />
              <label
                htmlFor="email-marketing"
                className="text-sm text-gray-600 leading-none"
              >
                이메일
              </label>
            </div>
          </div>
        </div>

        {/* 버튼 */}
        <div className="flex gap-3 pt-4">
          <Button 
            type="button"
            onClick={handleCancel}
            variant="outline"
            className="flex-1 h-12 border-2 border-gray-300 text-gray-700 hover:bg-gray-50"
          >
            취소
          </Button>
          <Button 
            type="submit"
            className="flex-1 h-12 bg-green-600 hover:bg-green-700"
          >
            회원가입
          </Button>
        </div>
      </form>
    </div>
  );
}