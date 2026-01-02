import { useState, useRef, useEffect } from 'react';
import { Camera, Utensils, Dumbbell, Users, Plus, CalendarDays, Activity, Home, BarChart3, User, MessageCircle, Heart, ThumbsUp } from 'lucide-react';
import { getTranslation, type Language } from '../utils/translations';

interface MainScreenProps {
  language: Language;
  onMealClick: (type: 'breakfast' | 'lunch' | 'dinner' | 'snack', title: string) => void;
  onExerciseClick: () => void;
  onCommunityClick: () => void;
  onStatsClick: () => void;
  onAICoachClick: () => void;
  onProfileClick: () => void;
  onCameraClick: () => void;
  mealData: {
    breakfast: any[];
    lunch: any[];
    dinner: any[];
    snack: any[];
  };
  exerciseData: any[];
}

export function MainScreen({ language, onMealClick, onExerciseClick, onCommunityClick, onStatsClick, onAICoachClick, onProfileClick, onCameraClick, mealData, exerciseData }: MainScreenProps) {
  const [activeTab, setActiveTab] = useState<'diet' | 'exercise' | 'community'>('diet');
  const [activeBottomTab, setActiveBottomTab] = useState('home');
  const containerRef = useRef<HTMLDivElement>(null);
  const dietSectionRef = useRef<HTMLDivElement>(null);
  const exerciseSectionRef = useRef<HTMLDivElement>(null);
  const communitySectionRef = useRef<HTMLDivElement>(null);

  // 현재 사용자 닉네임 가져오기
  const currentUser = JSON.parse(localStorage.getItem('currentUser') || '{}');
  const userNickname = currentUser.nickname || '사용자';
  
  // 현재 언어 사용
  const lang = language;
  const t = (key: any) => getTranslation(key, lang);

  // 커뮤니티 더미 데이터
  const communityPosts = [
    {
      id: 1,
      author: '건강러버',
      avatar: '👤',
      time: '2시간 전',
      content: '오늘 처음으로 5km 달리기 성공했어요! 너무 뿌듯해요 💪',
      image: null,
      likes: 24,
      comments: 8,
    },
    {
      id: 2,
      author: '다이어터',
      avatar: '👤',
      time: '5시간 전',
      content: '한 달간의 식단 관리 결과 -3kg 성공! 여러분도 할 수 있어요!',
      image: null,
      likes: 42,
      comments: 15,
    },
    {
      id: 3,
      author: '요가마스터',
      avatar: '👤',
      time: '1일 전',
      content: '아침 요가 30분 루틴 공유합니다. 하루를 상쾌하게 시작하세요 🧘‍♀️',
      image: null,
      likes: 38,
      comments: 12,
    },
    {
      id: 4,
      author: '헬스왕',
      avatar: '👤',
      time: '1일 전',
      content: '드디어 벤치프레스 100kg 성공! 1년간의 노력이 결실을 맺었습니다 🏋️',
      image: null,
      likes: 56,
      comments: 21,
    },
    {
      id: 5,
      author: '채식주의자',
      avatar: '👤',
      time: '2일 전',
      content: '간단하고 맛있는 비건 샐러드 레시피 공유해요. 영양도 만점! 🥗',
      image: null,
      likes: 33,
      comments: 9,
    },
  ];

  // 스크롤 이벤트로 탭 자동 변경
  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    const handleScroll = () => {
      const dietSection = dietSectionRef.current;
      const exerciseSection = exerciseSectionRef.current;
      const communitySection = communitySectionRef.current;
      if (!dietSection || !exerciseSection || !communitySection) return;

      const scrollTop = container.scrollTop;
      const dietTop = dietSection.offsetTop - 150;
      const exerciseTop = exerciseSection.offsetTop - 150;
      const communityTop = communitySection.offsetTop - 150;

      if (scrollTop < exerciseTop) {
        setActiveTab('diet');
      } else if (scrollTop < communityTop) {
        setActiveTab('exercise');
      } else {
        setActiveTab('community');
      }
    };

    container.addEventListener('scroll', handleScroll);
    return () => container.removeEventListener('scroll', handleScroll);
  }, []);

  const calculateMealCalories = (meals: any[]) => {
    return meals.reduce((sum, meal) => sum + meal.calories, 0);
  };

  const totalMealCalories = 
    calculateMealCalories(mealData.breakfast) +
    calculateMealCalories(mealData.lunch) +
    calculateMealCalories(mealData.dinner) +
    calculateMealCalories(mealData.snack);
  
  const totalExerciseCalories = exerciseData.reduce((sum, ex) => sum + ex.calories, 0);
  const netCalories = totalMealCalories - totalExerciseCalories;
  const targetCalories = 2000;

  const scrollToSection = (section: 'diet' | 'exercise' | 'community') => {
    setActiveTab(section);
    if (section === 'diet' && dietSectionRef.current) {
      dietSectionRef.current.scrollIntoView({ behavior: 'smooth' });
    } else if (section === 'exercise' && exerciseSectionRef.current) {
      exerciseSectionRef.current.scrollIntoView({ behavior: 'smooth' });
    } else if (section === 'community' && communitySectionRef.current) {
      communitySectionRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  };

  const renderMealSection = (type: 'breakfast' | 'lunch' | 'dinner' | 'snack', title: string, emoji: string) => {
    const meals = mealData[type];
    const totalCalories = calculateMealCalories(meals);
    const hasImage = meals.length > 0 && meals.some(m => m.image);
    const firstImageMeal = meals.find(m => m.image);

    return (
      <button
        onClick={() => onMealClick(type, title)}
        className="bg-white rounded-xl border border-gray-200 overflow-hidden shadow-sm flex flex-col hover:shadow-md transition-shadow"
      >
        {/* 헤더 */}
        <div className="bg-gradient-to-r from-green-50 to-green-100 px-3 py-1.5 flex items-center justify-between">
          <div className="flex items-center gap-1">
            <span className="text-sm">{emoji}</span>
            <h3 className="font-semibold text-gray-800 text-xs">{title}</h3>
          </div>
        </div>

        {/* 내용 */}
        <div className="p-2 flex flex-col gap-1.5">
          {/* 이미지 영역 */}
          {hasImage && firstImageMeal ? (
            <div>
              <img 
                src={firstImageMeal.image} 
                alt={firstImageMeal.name}
                className="w-full h-16 rounded-lg object-cover"
              />
            </div>
          ) : (
            <div className="w-full h-16 border-2 border-dashed border-gray-300 rounded-lg flex items-center justify-center">
              <div className="text-center">
                <Plus className="w-4 h-4 mx-auto text-gray-400" />
                <p className="text-xs text-gray-400 mt-0.5">
                  {lang === 'ko' && '사진 추가'}
                  {lang === 'en' && 'Add Photo'}
                  {lang === 'zh' && '添加照片'}
                </p>
              </div>
            </div>
          )}

          {/* 총 열량 */}
          <div className="text-center">
            <div className="text-xs text-gray-500">
              {lang === 'ko' && '총 열량'}
              {lang === 'en' && 'Total'}
              {lang === 'zh' && '总热量'}
            </div>
            <div className="text-sm font-bold text-green-600">{totalCalories} <span className="text-xs">{t('kcal')}</span></div>
          </div>
        </div>
      </button>
    );
  };

  return (
    <div className="w-full max-w-md h-screen bg-gray-50 flex flex-col relative">
      {/* 상단 헤더 */}
      <div className="bg-gradient-to-r from-green-500 to-green-600 text-white p-6 pb-4">
        <div className="flex items-center justify-between mb-4">
          <h1 className="text-2xl font-bold">{t('appName')}</h1>
          <div className="text-sm bg-white/20 backdrop-blur-sm px-3 py-1 rounded-full">
            {userNickname}{lang === 'ko' ? '님' : ''}
          </div>
        </div>
        <div className="bg-white/20 backdrop-blur-sm rounded-xl p-4">
          <div className="flex items-center justify-between mb-2">
            <span>{t('todayCalories')}</span>
            <span className="text-sm">{netCalories} / {targetCalories} {t('kcal')}</span>
          </div>
          <div className="w-full bg-white/30 rounded-full h-2.5 overflow-hidden">
            <div 
              className="bg-white h-full rounded-full transition-all"
              style={{ width: `${Math.min((netCalories / targetCalories) * 100, 100)}%` }}
            />
          </div>
        </div>
      </div>

      {/* 식단/운동 탭 바 */}
      <div className="bg-white border-b border-gray-200 px-4">
        <div className="flex gap-2">
          <button
            onClick={() => scrollToSection('diet')}
            className={`relative flex-1 py-3 font-semibold transition-colors ${
              activeTab === 'diet' ? 'text-green-600' : 'text-gray-500'
            }`}
          >
            {t('diet')}
            {activeTab === 'diet' && (
              <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-green-600" />
            )}
          </button>
          <button
            onClick={() => scrollToSection('exercise')}
            className={`relative flex-1 py-3 font-semibold transition-colors ${
              activeTab === 'exercise' ? 'text-green-600' : 'text-gray-500'
            }`}
          >
            {t('exercise')}
            {activeTab === 'exercise' && (
              <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-green-600" />
            )}
          </button>
          <button
            onClick={() => scrollToSection('community')}
            className={`relative flex-1 py-3 font-semibold transition-colors ${
              activeTab === 'community' ? 'text-green-600' : 'text-gray-500'
            }`}
          >
            {t('community')}
            {activeTab === 'community' && (
              <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-green-600" />
            )}
          </button>
        </div>
      </div>

      {/* 탭 컨텐츠 */}
      <div className="flex-1 pb-24 overflow-y-auto" ref={containerRef}>
        {/* 식단 섹션 */}
        <div className="p-4" ref={dietSectionRef}>
          <h2 className="text-lg font-semibold text-gray-800 mb-3">
            {lang === 'ko' && '오늘의 식단'}
            {lang === 'en' && 'Today\'s Meals'}
            {lang === 'zh' && '今日饮食'}
          </h2>
          {/* 2x2 그리드 */}
          <div className="grid grid-cols-2 gap-3" style={{ height: 'auto' }}>
            {renderMealSection('breakfast', t('breakfast'), '🌅')}
            {renderMealSection('lunch', t('lunch'), '🌞')}
            {renderMealSection('dinner', t('dinner'), '🌙')}
            {renderMealSection('snack', t('snack'), '🍎')}
          </div>
        </div>

        {/* 운동 섹션 */}
        <div className="p-4 pt-6" ref={exerciseSectionRef}>
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-lg font-semibold text-gray-800">
              {lang === 'ko' && '오늘의 운동'}
              {lang === 'en' && 'Today\'s Exercise'}
              {lang === 'zh' && '今日运动'}
            </h2>
            <Activity className="w-5 h-5 text-gray-500" />
          </div>
          
          {exerciseData.length === 0 ? (
            <button 
              onClick={onExerciseClick}
              className="text-center py-12 text-gray-400 bg-white rounded-xl border border-gray-200 hover:border-blue-400 hover:bg-blue-50 transition-all w-full"
            >
              <Dumbbell className="w-12 h-12 mx-auto mb-3 opacity-50" />
              <p>
                {lang === 'ko' && '아직 기록된 운동이 없습니다'}
                {lang === 'en' && 'No exercises recorded yet'}
                {lang === 'zh' && '尚未记录运动'}
              </p>
              <p className="text-sm mt-1">
                {lang === 'ko' && '운동 기록을 추가해보세요!'}
                {lang === 'en' && 'Add your first exercise!'}
                {lang === 'zh' && '添加您的第一个运动记录！'}
              </p>
            </button>
          ) : (
            <>
              <div className="space-y-3 mb-3">
                {exerciseData.map((exercise) => (
                  <div key={exercise.id} className="bg-white rounded-xl p-4 border border-gray-200">
                    <div className="flex items-start justify-between mb-2">
                      <div>
                        <h3 className="font-semibold text-gray-800">{exercise.name}</h3>
                        <p className="text-sm text-gray-600">{exercise.duration}</p>
                      </div>
                      <span className="text-sm text-gray-500">{exercise.time}</span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-blue-600 font-semibold">-{exercise.calories} {t('kcal')}</span>
                    </div>
                  </div>
                ))}
              </div>
              <button 
                onClick={onExerciseClick}
                className="w-full py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-semibold flex items-center justify-center gap-2"
              >
                <Plus className="w-5 h-5" />
                {t('addExercise')}
              </button>
            </>
          )}
        </div>

        {/* 커뮤니티 섹션 */}
        <div className="p-4 pt-6" ref={communitySectionRef}>
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-lg font-semibold text-gray-800">{t('community')}</h2>
            <MessageCircle className="w-5 h-5 text-gray-500" />
          </div>
          
          {communityPosts.length === 0 ? (
            <div className="text-center py-12 text-gray-400 bg-white rounded-xl border border-gray-200 hover:border-blue-400 hover:bg-blue-50 transition-all w-full">
              <Heart className="w-12 h-12 mx-auto mb-3 opacity-50" />
              <p>
                {lang === 'ko' && '아직 작성된 게시글이 없습니다'}
                {lang === 'en' && 'No posts yet'}
                {lang === 'zh' && '尚无帖子'}
              </p>
              <p className="text-sm mt-1">
                {lang === 'ko' && '커뮤니티에 참여해보세요!'}
                {lang === 'en' && 'Join the community!'}
                {lang === 'zh' && '加入社区！'}
              </p>
            </div>
          ) : (
            <>
              <div className="space-y-3 mb-3">
                {communityPosts.map((post) => (
                  <div key={post.id} className="bg-white rounded-xl p-4 border border-gray-200">
                    <div className="flex items-start justify-between mb-2">
                      <div>
                        <h3 className="font-semibold text-gray-800">{post.author}</h3>
                        <p className="text-sm text-gray-600">{post.time}</p>
                      </div>
                      <span className="text-sm text-gray-500">{post.avatar}</span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-blue-600 font-semibold">{post.content}</span>
                    </div>
                    <div className="flex items-center justify-between mt-2">
                      <div className="flex items-center gap-1">
                        <ThumbsUp className="w-4 h-4 text-gray-500" />
                        <span className="text-sm text-gray-500">{post.likes}</span>
                      </div>
                      <div className="flex items-center gap-1">
                        <MessageCircle className="w-4 h-4 text-gray-500" />
                        <span className="text-sm text-gray-500">{post.comments}</span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
              <button 
                onClick={onCommunityClick}
                className="w-full py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors font-semibold flex items-center justify-center gap-2"
              >
                <Plus className="w-5 h-5" />
                {lang === 'ko' && '커뮤니티 홈 가기'}
                {lang === 'en' && 'Go to Community'}
                {lang === 'zh' && '进入社区'}
              </button>
            </>
          )}
        </div>
      </div>

      {/* 하단 네비게이션 바 */}
      <div className="absolute bottom-0 left-0 right-0 bg-white border-t border-gray-200 px-2 pb-6 pt-3">
        <div className="flex items-center justify-between relative">
          {/* 홈화면 버튼 */}
          <button
            onClick={() => setActiveBottomTab('home')}
            className={`flex flex-col items-center gap-1 transition-colors flex-1 ${
              activeBottomTab === 'home' ? 'text-green-600' : 'text-gray-400'
            }`}
          >
            <Home className="w-6 h-6" />
            <span className="text-xs">{t('home')}</span>
          </button>

          {/* 통계 버튼 */}
          <button
            onClick={() => {
              setActiveBottomTab('stats');
              onStatsClick();
            }}
            className={`flex flex-col items-center gap-1 transition-colors flex-1 ${
              activeBottomTab === 'stats' ? 'text-green-600' : 'text-gray-400'
            }`}
          >
            <BarChart3 className="w-6 h-6" />
            <span className="text-xs">{t('stats')}</span>
          </button>

          {/* 카메라 버튼 (중앙) */}
          <button className="flex-1 flex justify-center">
            <div className="w-14 h-14 -mt-10 bg-gradient-to-br from-green-500 to-green-600 rounded-full shadow-lg flex items-center justify-center hover:shadow-xl transition-shadow" onClick={onCameraClick}>
              <Camera className="w-7 h-7 text-white" />
            </div>
          </button>

          {/* AI코치 버튼 */}
          <button
            onClick={() => {
              setActiveBottomTab('ai');
              onAICoachClick();
            }}
            className={`flex flex-col items-center gap-1 transition-colors flex-1 ${
              activeBottomTab === 'ai' ? 'text-green-600' : 'text-gray-400'
            }`}
          >
            <MessageCircle className="w-6 h-6" />
            <span className="text-xs">{t('aiCoach')}</span>
          </button>

          {/* 내정보 버튼 */}
          <button
            onClick={() => {
              setActiveBottomTab('profile');
              onProfileClick();
            }}
            className={`flex flex-col items-center gap-1 transition-colors flex-1 ${
              activeBottomTab === 'profile' ? 'text-green-600' : 'text-gray-400'
            }`}
          >
            <User className="w-6 h-6" />
            <span className="text-xs">{t('profile')}</span>
          </button>
        </div>
      </div>
    </div>
  );
}