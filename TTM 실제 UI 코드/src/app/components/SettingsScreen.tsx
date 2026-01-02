import { ArrowLeft, Bell, Users, HelpCircle, Trash2, ChevronRight, LogOut, Globe } from 'lucide-react';
import { useState } from 'react';
import { getCurrentLanguage, setCurrentLanguage, getTranslation, type Language } from '../utils/translations';

interface SettingsScreenProps {
  onBack: () => void;
  onViewFriends: () => void;
  onViewHelp: () => void;
  onLanguageChange: (lang: Language) => void;
  onLogout: () => void;
  onDeleteAccount: () => void;
}

export function SettingsScreen({ onBack, onViewFriends, onViewHelp, onLanguageChange, onLogout, onDeleteAccount }: SettingsScreenProps) {
  const [notificationEnabled, setNotificationEnabled] = useState(
    localStorage.getItem('notificationEnabled') === 'true'
  );
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [showLanguageModal, setShowLanguageModal] = useState(false);
  const [selectedLanguage, setSelectedLanguage] = useState<Language>(getCurrentLanguage());

  const t = (key: any) => getTranslation(key, selectedLanguage);

  const handleNotificationToggle = () => {
    const newValue = !notificationEnabled;
    setNotificationEnabled(newValue);
    localStorage.setItem('notificationEnabled', String(newValue));
  };

  const handleLanguageChange = (lang: Language) => {
    setSelectedLanguage(lang);
    setCurrentLanguage(lang);
    setShowLanguageModal(false);
    // App의 언어 상태를 업데이트 (페이지 새로고침 없이)
    onLanguageChange(lang);
  };

  const handleLogout = () => {
    setShowLogoutConfirm(false);
    onLogout();
  };

  const handleDeleteAccount = () => {
    setShowDeleteConfirm(false);
    onDeleteAccount();
  };

  const getLanguageDisplayName = (lang: Language) => {
    switch (lang) {
      case 'ko': return '한국어';
      case 'en': return 'English';
      case 'zh': return '中文';
      default: return '한국어';
    }
  };

  return (
    <div className="w-full max-w-md h-screen bg-gray-50 flex flex-col">
      {/* 헤더 */}
      <div className="bg-gradient-to-r from-green-500 to-green-600 text-white p-4">
        <div className="flex items-center gap-3">
          <button onClick={onBack} className="p-1 hover:bg-white/20 rounded-lg transition-colors">
            <ArrowLeft className="w-6 h-6" />
          </button>
          <h1 className="text-xl font-bold">{t('settings')}</h1>
        </div>
      </div>

      {/* 설정 목록 */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {/* 알림 수신 설정 */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
                <Bell className="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <h3 className="font-semibold text-gray-800">{t('notifications')}</h3>
                <p className="text-sm text-gray-500">
                  {selectedLanguage === 'ko' && '푸시 알림 설정'}
                  {selectedLanguage === 'en' && 'Push notification settings'}
                  {selectedLanguage === 'zh' && '推送通知设置'}
                </p>
              </div>
            </div>
            <button
              onClick={handleNotificationToggle}
              className={`relative w-14 h-8 rounded-full transition-colors ${
                notificationEnabled ? 'bg-green-500' : 'bg-gray-300'
              }`}
            >
              <div
                className={`absolute top-1 left-1 w-6 h-6 bg-white rounded-full transition-transform ${
                  notificationEnabled ? 'translate-x-6' : 'translate-x-0'
                }`}
              ></div>
            </button>
          </div>
        </div>

        {/* 친구 목록 */}
        <button
          onClick={onViewFriends}
          className="w-full bg-white rounded-xl shadow-sm border border-gray-200 p-4 text-left hover:shadow-md transition-shadow"
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center">
                <Users className="w-5 h-5 text-purple-600" />
              </div>
              <div>
                <h3 className="font-semibold text-gray-800">{t('friends')}</h3>
                <p className="text-sm text-gray-500">
                  {selectedLanguage === 'ko' && '친구 및 모임 관리'}
                  {selectedLanguage === 'en' && 'Friends and groups'}
                  {selectedLanguage === 'zh' && '好友和群组管理'}
                </p>
              </div>
            </div>
            <ChevronRight className="w-5 h-5 text-gray-400" />
          </div>
        </button>

        {/* 도움말 */}
        <button
          onClick={onViewHelp}
          className="w-full bg-white rounded-xl shadow-sm border border-gray-200 p-4 text-left hover:shadow-md transition-shadow"
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
                <HelpCircle className="w-5 h-5 text-green-600" />
              </div>
              <div>
                <h3 className="font-semibold text-gray-800">{t('help')}</h3>
                <p className="text-sm text-gray-500">
                  {selectedLanguage === 'ko' && '자주 묻는 질문'}
                  {selectedLanguage === 'en' && 'FAQs'}
                  {selectedLanguage === 'zh' && '常见问题'}
                </p>
              </div>
            </div>
            <ChevronRight className="w-5 h-5 text-gray-400" />
          </div>
        </button>

        {/* 언어 설정 */}
        <button
          onClick={() => setShowLanguageModal(true)}
          className="w-full bg-white rounded-xl shadow-sm border border-gray-200 p-4 text-left hover:shadow-md transition-shadow"
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-indigo-100 rounded-lg flex items-center justify-center">
                <Globe className="w-5 h-5 text-indigo-600" />
              </div>
              <div>
                <h3 className="font-semibold text-gray-800">{t('language')}</h3>
                <p className="text-sm text-gray-500">
                  {selectedLanguage === 'ko' && `현재 언어: ${getLanguageDisplayName(selectedLanguage)}`}
                  {selectedLanguage === 'en' && `Current: ${getLanguageDisplayName(selectedLanguage)}`}
                  {selectedLanguage === 'zh' && `当前语言: ${getLanguageDisplayName(selectedLanguage)}`}
                </p>
              </div>
            </div>
            <ChevronRight className="w-5 h-5 text-gray-400" />
          </div>
        </button>

        {/* 로그아웃 */}
        <button
          onClick={() => setShowLogoutConfirm(true)}
          className="w-full bg-white rounded-xl shadow-sm border border-gray-200 p-4 text-left hover:shadow-md transition-shadow"
        >
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-orange-100 rounded-lg flex items-center justify-center">
              <LogOut className="w-5 h-5 text-orange-600" />
            </div>
            <div>
              <h3 className="font-semibold text-gray-800">{t('logout')}</h3>
              <p className="text-sm text-gray-500">
                {selectedLanguage === 'ko' && '현재 계정에서 로그아웃'}
                {selectedLanguage === 'en' && 'Sign out of your account'}
                {selectedLanguage === 'zh' && '退出当前账户'}
              </p>
            </div>
          </div>
        </button>

        {/* 회원탈퇴 */}
        <button
          onClick={() => setShowDeleteConfirm(true)}
          className="w-full bg-white rounded-xl shadow-sm border border-red-200 p-4 text-left hover:shadow-md transition-shadow"
        >
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-red-100 rounded-lg flex items-center justify-center">
              <Trash2 className="w-5 h-5 text-red-600" />
            </div>
            <div>
              <h3 className="font-semibold text-red-600">{t('deleteAccount')}</h3>
              <p className="text-sm text-gray-500">
                {selectedLanguage === 'ko' && '계정 영구 삭제'}
                {selectedLanguage === 'en' && 'Permanently delete account'}
                {selectedLanguage === 'zh' && '永久删除账户'}
              </p>
            </div>
          </div>
        </button>
      </div>

      {/* 로그아웃 확인 모달 */}
      {showLogoutConfirm && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl p-6 max-w-sm w-full">
            <h3 className="text-xl font-bold text-gray-800 mb-2">
              {selectedLanguage === 'ko' && '로그아웃'}
              {selectedLanguage === 'en' && 'Logout'}
              {selectedLanguage === 'zh' && '退出登录'}
            </h3>
            <p className="text-gray-600 mb-6">
              {selectedLanguage === 'ko' && '정말 로그아웃 하시겠습니까?'}
              {selectedLanguage === 'en' && 'Are you sure you want to logout?'}
              {selectedLanguage === 'zh' && '您确定要退出登录吗？'}
            </p>
            <div className="flex gap-3">
              <button
                onClick={() => setShowLogoutConfirm(false)}
                className="flex-1 py-3 px-4 rounded-lg border border-gray-300 font-semibold text-gray-700 hover:bg-gray-50 transition-colors"
              >
                {selectedLanguage === 'ko' && '취소'}
                {selectedLanguage === 'en' && 'Cancel'}
                {selectedLanguage === 'zh' && '取消'}
              </button>
              <button
                onClick={handleLogout}
                className="flex-1 py-3 px-4 rounded-lg bg-green-600 font-semibold text-white hover:bg-green-700 transition-colors"
              >
                {selectedLanguage === 'ko' && '로그아웃'}
                {selectedLanguage === 'en' && 'Logout'}
                {selectedLanguage === 'zh' && '退出'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 회원탈퇴 확인 모달 */}
      {showDeleteConfirm && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl p-6 max-w-sm w-full">
            <h3 className="text-xl font-bold text-red-600 mb-2">
              {selectedLanguage === 'ko' && '회원탈퇴'}
              {selectedLanguage === 'en' && 'Delete Account'}
              {selectedLanguage === 'zh' && '删除账户'}
            </h3>
            <p className="text-gray-600 mb-6">
              {selectedLanguage === 'ko' && (
                <>
                  정말 탈퇴하시겠습니까?<br />
                  모든 데이터가 삭제되며 복구할 수 없습니다.
                </>
              )}
              {selectedLanguage === 'en' && (
                <>
                  Are you sure you want to delete your account?<br />
                  All data will be deleted and cannot be recovered.
                </>
              )}
              {selectedLanguage === 'zh' && (
                <>
                  您确定要删除账户吗？<br />
                  所有数据将被删除且无法恢复。
                </>
              )}
            </p>
            <div className="flex gap-3">
              <button
                onClick={() => setShowDeleteConfirm(false)}
                className="flex-1 py-3 px-4 rounded-lg border border-gray-300 font-semibold text-gray-700 hover:bg-gray-50 transition-colors"
              >
                {selectedLanguage === 'ko' && '취소'}
                {selectedLanguage === 'en' && 'Cancel'}
                {selectedLanguage === 'zh' && '取消'}
              </button>
              <button
                onClick={handleDeleteAccount}
                className="flex-1 py-3 px-4 rounded-lg bg-red-600 font-semibold text-white hover:bg-red-700 transition-colors"
              >
                {selectedLanguage === 'ko' && '탈퇴하기'}
                {selectedLanguage === 'en' && 'Delete'}
                {selectedLanguage === 'zh' && '删除'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 언어 설정 모달 */}
      {showLanguageModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl p-6 max-w-sm w-full">
            <h3 className="text-xl font-bold text-gray-800 mb-2">
              {selectedLanguage === 'ko' && '언어 설정'}
              {selectedLanguage === 'en' && 'Language Settings'}
              {selectedLanguage === 'zh' && '语言设置'}
            </h3>
            <p className="text-gray-600 mb-6">
              {selectedLanguage === 'ko' && '사용할 언어를 선택하세요.'}
              {selectedLanguage === 'en' && 'Select your language.'}
              {selectedLanguage === 'zh' && '选择您的语言。'}
            </p>
            <div className="flex flex-col gap-3">
              <button
                onClick={() => handleLanguageChange('ko')}
                className={`py-3 px-4 rounded-lg border font-semibold hover:bg-gray-50 transition-colors ${
                  selectedLanguage === 'ko' 
                    ? 'border-green-600 text-green-600 bg-green-50' 
                    : 'border-gray-300 text-gray-700'
                }`}
              >
                한국어
              </button>
              <button
                onClick={() => handleLanguageChange('en')}
                className={`py-3 px-4 rounded-lg border font-semibold hover:bg-gray-50 transition-colors ${
                  selectedLanguage === 'en' 
                    ? 'border-green-600 text-green-600 bg-green-50' 
                    : 'border-gray-300 text-gray-700'
                }`}
              >
                English
              </button>
              <button
                onClick={() => handleLanguageChange('zh')}
                className={`py-3 px-4 rounded-lg border font-semibold hover:bg-gray-50 transition-colors ${
                  selectedLanguage === 'zh' 
                    ? 'border-green-600 text-green-600 bg-green-50' 
                    : 'border-gray-300 text-gray-700'
                }`}
              >
                中文
              </button>
              <button
                onClick={() => setShowLanguageModal(false)}
                className="mt-2 py-3 px-4 rounded-lg border border-gray-300 font-semibold text-gray-700 hover:bg-gray-50 transition-colors"
              >
                {selectedLanguage === 'ko' && '닫기'}
                {selectedLanguage === 'en' && 'Close'}
                {selectedLanguage === 'zh' && '关闭'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}