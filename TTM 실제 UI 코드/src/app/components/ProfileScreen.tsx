import { ArrowLeft, User, Activity, Award, HelpCircle, Settings, LogOut, Trash2, ChevronRight, Utensils, Dumbbell, Edit3, Heart, X } from 'lucide-react';
import { useState } from 'react';
import { getTranslation, type Language } from '../utils/translations';

interface ProfileScreenProps {
  language: Language;
  onBack: () => void;
  onLogout?: () => void;
  onViewActivity?: () => void;
  onViewActivityTab?: (tab: 'meals' | 'workouts' | 'posts' | 'likes') => void;
  onViewAllBadges?: () => void;
  onViewSettings?: () => void;
  onViewHelp?: () => void;
}

interface Badge {
  id: number;
  name: string;
  icon: string;
  description: string;
  earned: boolean;
  howToEarn: string;
  earnedDate?: string;
}

export function ProfileScreen({ language, onBack, onLogout, onViewActivity, onViewActivityTab, onViewAllBadges, onViewSettings, onViewHelp }: ProfileScreenProps) {
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [activeActivityTab, setActiveActivityTab] = useState<'meals' | 'workouts' | 'posts' | 'likes'>('meals');
  const [selectedBadge, setSelectedBadge] = useState<Badge | null>(null);

  const lang = language;
  const t = (key: any) => getTranslation(key, lang);

  const currentUser = JSON.parse(localStorage.getItem('currentUser') || '{}');

  const userProfile = {
    name: currentUser.nickname || '건강러버',
    email: currentUser.email || 'health@tabtome.com',
    avatar: currentUser.nickname ? currentUser.nickname[0] : '👤',
    joinDate: currentUser.joinDate || '2024.01.01',
    stats: {
      totalDays: 45,
      totalWorkouts: 128,
      totalMeals: 342,
    },
  };

  const badges: Badge[] = [
    { 
      id: 1, 
      name: '첫 걸음', 
      icon: '🎯', 
      description: '첫 식단 기록', 
      earned: true,
      howToEarn: '첫 번째 식단을 기록하면 획득할 수 있습니다.',
      earnedDate: '2024.12.01'
    },
    { 
      id: 2, 
      name: '운동 초보', 
      icon: '💪', 
      description: '운동 10회 달성', 
      earned: true,
      howToEarn: '운동을 총 10회 기록하면 획득할 수 있습니다.',
      earnedDate: '2024.12.05'
    },
    { 
      id: 3, 
      name: '꾸준함', 
      icon: '🔥', 
      description: '7일 연속 기록', 
      earned: true,
      howToEarn: '7일 동안 연속으로 식단이나 운동을 기록하면 획득할 수 있습니다.',
      earnedDate: '2024.12.08'
    },
    { 
      id: 4, 
      name: '건강 마스터', 
      icon: '👑', 
      description: '30일 연속 기록', 
      earned: true,
      howToEarn: '30일 동안 연속으로 식단이나 운동을 기록하면 획득할 수 있습니다.',
      earnedDate: '2024.12.20'
    },
    { 
      id: 5, 
      name: '완벽한 하루', 
      icon: '⭐', 
      description: '하루 목표 달성', 
      earned: true,
      howToEarn: '하루 동안 설정한 칼로리 목표와 운동 목표를 모두 달성하면 획득할 수 있습니다.',
      earnedDate: '2024.12.03'
    },
    { 
      id: 6, 
      name: '운동왕', 
      icon: '🏆', 
      description: '운동 100회 달성', 
      earned: true,
      howToEarn: '운동을 총 100회 기록하면 획득할 수 있습니다.',
      earnedDate: '2024.12.18'
    },
    { 
      id: 7, 
      name: '아침형 인간', 
      icon: '🌅', 
      description: '아침 식단 30회 기록', 
      earned: true,
      howToEarn: '아침 식단을 총 30회 기록하면 획득할 수 있습니다.',
      earnedDate: '2024.12.15'
    },
    { 
      id: 8, 
      name: '야식 킬러', 
      icon: '🚫', 
      description: '야식 없이 14일 달성', 
      earned: true,
      howToEarn: '14일 동안 저녁 9시 이후 음식을 기록하지 않으면 획득할 수 있습니다.',
      earnedDate: '2024.12.12'
    },
    { 
      id: 9, 
      name: '칼로리 킹', 
      icon: '🔥', 
      description: '목표 칼로리 50일 달성', 
      earned: false,
      howToEarn: '50일 동안 칼로리 목표를 지키면 획득할 수 있습니다.'
    },
    { 
      id: 10, 
      name: '웨이트 마스터', 
      icon: '🏋️', 
      description: '웨이트 트레이닝 50회', 
      earned: false,
      howToEarn: '웨이트 트레이닝을 총 50회 기록하면 획득할 수 있습니다.'
    },
    { 
      id: 11, 
      name: '러닝 마니아', 
      icon: '🏃', 
      description: '런닝 100km 달성', 
      earned: false,
      howToEarn: '총 100km를 달리면 획득할 수 있습니다.'
    },
    { 
      id: 12, 
      name: '요가 마스터', 
      icon: '🧘', 
      description: '요가 30회 달성', 
      earned: false,
      howToEarn: '요가를 총 30회 기록하면 획득할 수 있습니다.'
    },
    { 
      id: 13, 
      name: '소셜 스타', 
      icon: '🌟', 
      description: '커뮤니티 글 50개 작성', 
      earned: false,
      howToEarn: '커뮤니티에 글을 50개 작성하면 획득할 수 있습니다.'
    },
    { 
      id: 14, 
      name: '인기인', 
      icon: '❤️', 
      description: '좋아요 500개 받기', 
      earned: false,
      howToEarn: '작성한 글에 좋아요를 총 500개 받으면 획득할 수 있습니다.'
    },
    { 
      id: 15, 
      name: '다이어트 성공', 
      icon: '🎊', 
      description: '목표 체중 달성', 
      earned: false,
      howToEarn: '설정한 목표 체중에 도달하면 획득할 수 있습니다.'
    },
    { 
      id: 16, 
      name: '물 마시기 챔피언', 
      icon: '💧', 
      description: '하루 2L 물 30일', 
      earned: false,
      howToEarn: '30일 동안 매일 2L의 물을 마시면 획득할 수 있습니다.'
    },
    { 
      id: 17, 
      name: '수면왕', 
      icon: '😴', 
      description: '7시간 이상 수면 30일', 
      earned: false,
      howToEarn: '30일 동안 매일 7시간 이상 수면을 기록하면 획득할 수 있습니다.'
    },
    { 
      id: 18, 
      name: '채소 러버', 
      icon: '🥗', 
      description: '채소 위주 식단 30회', 
      earned: false,
      howToEarn: '채소 위주의 식단을 30회 기록하면 획득할 수 있습니다.'
    },
    { 
      id: 19, 
      name: '프로틴 마스터', 
      icon: '🥚', 
      description: '단백질 목표 50일 달성', 
      earned: false,
      howToEarn: '50일 동안 매일 단백질 목표를 달성하면 획득할 수 있습니다.'
    },
    { 
      id: 20, 
      name: '전설', 
      icon: '💎', 
      description: '100일 연속 기록', 
      earned: false,
      howToEarn: '100일 동안 연속으로 식단이나 운동을 기록하면 획득할 수 있습니다.'
    },
  ];

  const myActivities = [
    { id: 1, type: 'meals', label: '식단', count: 342, icon: '🍽️' },
    { id: 2, type: 'workouts', label: '운동', count: 128, icon: '💪' },
    { id: 3, type: 'posts', label: '커뮤니티 글', count: 24, icon: '✍️' },
    { id: 4, type: 'likes', label: '좋아요', count: 156, icon: '❤️' },
  ];

  // 활동 내역 데이터
  const activityHistory = {
    meals: [
      { id: 1, date: '2024.12.22', meal: '아침', items: '계란후라이, 토스트, 우유', calories: 450 },
      { id: 2, date: '2024.12.22', meal: '점심', items: '비빔밥, 된장찌개', calories: 680 },
      { id: 3, date: '2024.12.21', meal: '저녁', items: '삼겹살, 채소, 밥', calories: 820 },
      { id: 4, date: '2024.12.21', meal: '아침', items: '샌드위치, 커피', calories: 380 },
    ],
    workouts: [
      { id: 1, date: '2024.12.22', type: '런닝', duration: '30분', calories: 250 },
      { id: 2, date: '2024.12.21', type: '웨이트 트레이닝', duration: '45분', calories: 320 },
      { id: 3, date: '2024.12.20', type: '요가', duration: '60분', calories: 180 },
      { id: 4, date: '2024.12.20', type: '사이클', duration: '40분', calories: 280 },
    ],
    posts: [
      { id: 1, date: '2024.12.22', content: '오늘 아침 식단 인증!', likes: 12 },
      { id: 2, date: '2024.12.21', content: '드디어 목표 체중 달성했어요!', likes: 45 },
      { id: 3, date: '2024.12.20', content: '운동 후 느낌이 너무 좋아요', likes: 23 },
    ],
    likes: [
      { id: 1, date: '2024.12.22', post: '건강한 아침 식단 루틴', author: '김건강' },
      { id: 2, date: '2024.12.22', post: '다이어트 성공 비법 공유', author: '이운동' },
      { id: 3, date: '2024.12.21', post: '홈트레이닝 추천 영상', author: '박헬스' },
      { id: 4, date: '2024.12.21', post: '저칼로리 간식 레시피', author: '최식단' },
    ],
  };

  const handleLogout = () => {
    if (confirm('정말 로그아웃 하시겠습니까?')) {
      localStorage.removeItem('currentUser');
      onLogout?.();
    }
  };

  const handleDeleteAccount = () => {
    if (confirm('정말 계정을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.')) {
      const users = JSON.parse(localStorage.getItem('users') || '[]');
      const updatedUsers = users.filter((u: any) => u.email !== userProfile.email);
      localStorage.setItem('users', JSON.stringify(updatedUsers));
      localStorage.removeItem('currentUser');
      alert('계정이 삭제되었습니다.');
      onLogout?.();
    }
  };

  return (
    <div className="w-full max-w-md h-screen bg-gray-50 flex flex-col overflow-y-auto">
      {/* 헤더 */}
      <div className="bg-gradient-to-r from-green-500 to-green-600 text-white p-4 pb-20">
        <div className="flex items-center gap-3 mb-6">
          <button onClick={onBack} className="p-1 hover:bg-white/20 rounded-lg transition-colors">
            <ArrowLeft className="w-6 h-6" />
          </button>
          <h1 className="text-xl font-bold">{t('myProfile')}</h1>
        </div>
      </div>

      {/* 프로필 카드 */}
      <div className="px-4 -mt-16 mb-4">
        <div className="bg-white rounded-xl shadow-lg border border-gray-200 p-6">
          <div className="flex items-center gap-4 mb-4">
            <div className="w-20 h-20 bg-gradient-to-br from-green-400 to-green-600 rounded-full flex items-center justify-center text-4xl">
              {userProfile.avatar}
            </div>
            <div className="flex-1">
              <h2 className="text-xl font-bold text-gray-800">{userProfile.name}</h2>
              <p className="text-sm text-gray-500">{userProfile.email}</p>
              <p className="text-xs text-gray-400 mt-1">{t('joinDate')}: {userProfile.joinDate}</p>
            </div>
          </div>

          <div className="grid grid-cols-3 gap-3 pt-4 border-t border-gray-100">
            <div className="text-center">
              <div className="text-2xl font-bold text-green-600">{userProfile.stats.totalDays}</div>
              <div className="text-xs text-gray-500">{t('days')}</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-blue-600">{userProfile.stats.totalWorkouts}</div>
              <div className="text-xs text-gray-500">{t('workouts')}</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-orange-600">{userProfile.stats.totalMeals}</div>
              <div className="text-xs text-gray-500">{t('meals')}</div>
            </div>
          </div>
        </div>
      </div>

      {/* 메뉴 섹션 */}
      <div className="px-4 space-y-4 pb-6">
        {/* 내 활동 */}
        <button 
          onClick={onViewActivity}
          className="w-full bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden hover:shadow-md transition-shadow"
        >
          <div className="p-4 flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
                <Activity className="w-5 h-5 text-green-600" />
              </div>
              <h3 className="font-semibold text-gray-800">{t('myActivity')}</h3>
            </div>
            <ChevronRight className="w-5 h-5 text-gray-400" />
          </div>
        </button>

        {/* 내 활동 바로가��� */}
        <div className="grid grid-cols-4 gap-2">
          {myActivities.map((activity) => (
            <button
              key={activity.id}
              onClick={() => onViewActivityTab?.(activity.type as any)}
              className="bg-white rounded-xl shadow-sm border border-gray-200 p-3 text-center hover:shadow-md transition-all hover:scale-105"
            >
              <div className="text-2xl mb-1">{activity.icon}</div>
              <div className="text-sm font-bold text-gray-800">{activity.count}</div>
              <div className="text-xs text-gray-500">{activity.label}</div>
            </button>
          ))}
        </div>

        {/* 내 뱃지 */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          <div className="p-4 border-b border-gray-100">
            <h3 className="font-semibold text-gray-800 flex items-center gap-2">
              <Award className="w-5 h-5 text-yellow-500" />
              내 뱃지 ({badges.filter(b => b.earned).length}/{badges.length})
            </h3>
          </div>
          <div className="p-4">
            <div className="grid grid-cols-4 gap-3">
              {badges.map((badge) => (
                <button
                  key={badge.id}
                  onClick={() => setSelectedBadge(badge)}
                  className={`rounded-lg p-3 text-center transition-all ${
                    badge.earned
                      ? 'bg-gradient-to-br from-yellow-50 to-orange-50 border-2 border-yellow-300 hover:scale-105'
                      : 'bg-gray-100 border-2 border-gray-200 opacity-60'
                  }`}
                >
                  <div className={`text-3xl ${!badge.earned && 'grayscale'}`}>{badge.icon}</div>
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* 설정 메뉴 */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          <button 
            onClick={onViewSettings}
            className="w-full p-4 flex items-center justify-between hover:bg-gray-50 transition-colors border-b border-gray-100"
          >
            <div className="flex items-center gap-3">
              <Settings className="w-5 h-5 text-gray-600" />
              <span className="text-gray-800">{t('settings')}</span>
            </div>
            <ChevronRight className="w-5 h-5 text-gray-400" />
          </button>

          <button 
            onClick={onViewHelp}
            className="w-full p-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
          >
            <div className="flex items-center gap-3">
              <HelpCircle className="w-5 h-5 text-gray-600" />
              <span className="text-gray-800">{t('help')}</span>
            </div>
            <ChevronRight className="w-5 h-5 text-gray-400" />
          </button>
        </div>
      </div>

      {/* 뱃지 상세 모달 */}
      {selectedBadge && (
        <div 
          className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4"
          onClick={() => setSelectedBadge(null)}
        >
          <div 
            className="bg-white rounded-2xl p-8 max-w-sm w-full relative animate-scale-up"
            onClick={(e) => e.stopPropagation()}
          >
            <button
              onClick={() => setSelectedBadge(null)}
              className="absolute top-4 right-4 text-gray-400 hover:text-gray-600"
            >
              <X className="w-6 h-6" />
            </button>

            <div className="text-center">
              <div 
                className={`text-8xl mb-4 animate-bounce-slow ${
                  !selectedBadge.earned && 'grayscale'
                }`}
              >
                {selectedBadge.icon}
              </div>
              <h3 className="text-2xl font-bold text-gray-800 mb-2">{selectedBadge.name}</h3>
              <p className="text-sm text-gray-600 mb-4">{selectedBadge.description}</p>
              
              {selectedBadge.earned ? (
                <div className="bg-gradient-to-r from-yellow-50 to-orange-50 border-2 border-yellow-300 rounded-lg p-4 mb-4">
                  <div className="text-sm font-semibold text-yellow-700 mb-1">🎉 획득 완료!</div>
                  <div className="text-xs text-gray-600">획득일: {selectedBadge.earnedDate}</div>
                </div>
              ) : (
                <div className="bg-gray-50 border-2 border-gray-200 rounded-lg p-4 mb-4">
                  <div className="text-sm font-semibold text-gray-700 mb-1">🔒 미획득</div>
                </div>
              )}

              <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 text-left">
                <div className="text-xs font-semibold text-blue-700 mb-2">획득 방법</div>
                <p className="text-xs text-gray-700">{selectedBadge.howToEarn}</p>
              </div>
            </div>
          </div>
        </div>
      )}

      <style>{`
        @keyframes scale-up {
          from {
            transform: scale(0.8);
            opacity: 0;
          }
          to {
            transform: scale(1);
            opacity: 1;
          }
        }

        @keyframes bounce-slow {
          0%, 100% {
            transform: translateY(0);
          }
          50% {
            transform: translateY(-10px);
          }
        }

        .animate-scale-up {
          animation: scale-up 0.3s ease-out;
        }

        .animate-bounce-slow {
          animation: bounce-slow 2s ease-in-out infinite;
        }
      `}</style>
    </div>
  );
}