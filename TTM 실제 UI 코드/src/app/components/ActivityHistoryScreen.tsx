import { ArrowLeft, Utensils, Dumbbell, Edit3, Heart } from 'lucide-react';
import { useState } from 'react';

interface ActivityHistoryScreenProps {
  onBack: () => void;
  onMealClick?: (meal: any) => void;
  onWorkoutClick?: (workout: any) => void;
  onPostClick?: (postId: string) => void;
  onUserClick?: (username: string) => void;
  initialTab?: 'meals' | 'workouts' | 'posts' | 'likes';
}

export function ActivityHistoryScreen({ onBack, onMealClick, onWorkoutClick, onPostClick, onUserClick, initialTab = 'meals' }: ActivityHistoryScreenProps) {
  const [activeTab, setActiveTab] = useState<'meals' | 'workouts' | 'posts' | 'likes'>(initialTab);

  // 활동 내역 데이터
  const activityHistory = {
    meals: [
      { id: 1, date: '2024.12.22', meal: '아침', items: '계란후라이, 토스트, 우유', calories: 450 },
      { id: 2, date: '2024.12.22', meal: '점심', items: '비빔밥, 된장찌개', calories: 680 },
      { id: 3, date: '2024.12.21', meal: '저녁', items: '삼겹살, 쌈채소, 밥', calories: 820 },
      { id: 4, date: '2024.12.21', meal: '아침', items: '샌드위치, 커피', calories: 380 },
      { id: 5, date: '2024.12.20', meal: '점심', items: '김치찌개, 공기밥', calories: 550 },
      { id: 6, date: '2024.12.20', meal: '저녁', items: '치킨샐러드', calories: 420 },
    ],
    workouts: [
      { id: 1, date: '2024.12.22', type: '런닝', duration: '30분', calories: 250 },
      { id: 2, date: '2024.12.21', type: '웨이트 트레이닝', duration: '45분', calories: 320 },
      { id: 3, date: '2024.12.20', type: '요가', duration: '60분', calories: 180 },
      { id: 4, date: '2024.12.20', type: '사이클', duration: '40분', calories: 280 },
      { id: 5, date: '2024.12.19', type: '수영', duration: '50분', calories: 350 },
      { id: 6, date: '2024.12.19', type: '필라테스', duration: '55분', calories: 200 },
    ],
    posts: [
      { id: 1, date: '2024.12.22', content: '오늘 아침 식단 인증! 건강하게 시작해요 💪', likes: 12 },
      { id: 2, date: '2024.12.21', content: '드디어 목표 체중 달성했어요! 감사합니다 🎉', likes: 45 },
      { id: 3, date: '2024.12.20', content: '운동 후 느낌이 너무 좋아요. 다들 화이팅!', likes: 23 },
      { id: 4, date: '2024.12.19', content: '저칼로리 간식 레시피 공유합니다', likes: 34 },
      { id: 5, date: '2024.12.18', content: '아침 런닝 완료! 날씨 좋네요', likes: 18 },
    ],
    likes: [
      { id: 1, date: '2024.12.22', post: '건강한 아침 식단 루틴', author: '김건강' },
      { id: 2, date: '2024.12.22', post: '다이어트 성공 비법 공유', author: '이운동' },
      { id: 3, date: '2024.12.21', post: '홈트레이닝 추천 영상', author: '박헬스' },
      { id: 4, date: '2024.12.21', post: '저칼로리 간식 레시피', author: '최식단' },
      { id: 5, date: '2024.12.20', post: '목표 달성 인증샷!', author: '정다이어트' },
      { id: 6, date: '2024.12.20', post: '운동 루틴 추천드립니다', author: '강트레이너' },
    ],
  };

  const stats = {
    meals: 342,
    workouts: 128,
    posts: 24,
    likes: 156,
  };

  const tabs = [
    { key: 'meals' as const, label: '식단', icon: '🍽️', count: stats.meals },
    { key: 'workouts' as const, label: '운동', icon: '💪', count: stats.workouts },
    { key: 'posts' as const, label: '커뮤니티 글', icon: '✍️', count: stats.posts },
    { key: 'likes' as const, label: '좋아요', icon: '❤️', count: stats.likes },
  ];

  return (
    <div className="w-full max-w-md h-screen bg-gray-50 flex flex-col">
      {/* 헤더 */}
      <div className="bg-gradient-to-r from-green-500 to-green-600 text-white">
        <div className="p-4 flex items-center gap-3">
          <button onClick={onBack} className="p-1 hover:bg-white/20 rounded-lg transition-colors">
            <ArrowLeft className="w-6 h-6" />
          </button>
          <h1 className="text-xl font-bold">내 활동</h1>
        </div>

        {/* 탭 버튼 */}
        <div className="grid grid-cols-4 gap-2 p-4 pt-2">
          {tabs.map((tab) => (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key)}
              className={`rounded-xl p-3 text-center transition-all ${
                activeTab === tab.key
                  ? 'bg-white text-green-600 shadow-lg scale-105'
                  : 'bg-white/20 text-white hover:bg-white/30'
              }`}
            >
              <div className="text-2xl mb-1">{tab.icon}</div>
              <div className="text-lg font-bold">{tab.count}</div>
              <div className="text-xs">{tab.label}</div>
            </button>
          ))}
        </div>
      </div>

      {/* 활동 내역 */}
      <div className="flex-1 overflow-y-auto p-4">
        {activeTab === 'meals' && (
          <div className="space-y-3">
            <div className="flex items-center gap-2 mb-4">
              <Utensils className="w-5 h-5 text-green-600" />
              <h2 className="font-bold text-gray-800">식단 기록</h2>
              <span className="text-sm text-gray-500">총 {stats.meals}회</span>
            </div>
            {activityHistory.meals.map((meal) => (
              <button 
                key={meal.id} 
                onClick={() => onMealClick?.(meal)}
                className="w-full bg-white rounded-xl border border-gray-200 p-4 hover:shadow-md transition-shadow text-left"
              >
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
                      <Utensils className="w-5 h-5 text-green-600" />
                    </div>
                    <div>
                      <div className="font-semibold text-gray-800">{meal.meal}</div>
                      <div className="text-xs text-gray-500">{meal.date}</div>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-lg font-bold text-orange-600">{meal.calories}</div>
                    <div className="text-xs text-gray-500">kcal</div>
                  </div>
                </div>
                <p className="text-sm text-gray-600 bg-gray-50 rounded-lg p-2">{meal.items}</p>
              </button>
            ))}
          </div>
        )}

        {activeTab === 'workouts' && (
          <div className="space-y-3">
            <div className="flex items-center gap-2 mb-4">
              <Dumbbell className="w-5 h-5 text-blue-600" />
              <h2 className="font-bold text-gray-800">운동 기록</h2>
              <span className="text-sm text-gray-500">총 {stats.workouts}회</span>
            </div>
            {activityHistory.workouts.map((workout) => (
              <button 
                key={workout.id}
                onClick={() => onWorkoutClick?.(workout)}
                className="w-full bg-white rounded-xl border border-gray-200 p-4 hover:shadow-md transition-shadow text-left"
              >
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
                      <Dumbbell className="w-5 h-5 text-blue-600" />
                    </div>
                    <div>
                      <div className="font-semibold text-gray-800">{workout.type}</div>
                      <div className="text-xs text-gray-500">{workout.date}</div>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-lg font-bold text-blue-600">{workout.calories}</div>
                    <div className="text-xs text-gray-500">kcal 소모</div>
                  </div>
                </div>
                <div className="flex items-center gap-2 text-sm text-gray-600 bg-gray-50 rounded-lg p-2">
                  <span>⏱️ {workout.duration}</span>
                </div>
              </button>
            ))}
          </div>
        )}

        {activeTab === 'posts' && (
          <div className="space-y-3">
            <div className="flex items-center gap-2 mb-4">
              <Edit3 className="w-5 h-5 text-purple-600" />
              <h2 className="font-bold text-gray-800">작성한 글</h2>
              <span className="text-sm text-gray-500">총 {stats.posts}개</span>
            </div>
            {activityHistory.posts.map((post) => (
              <button 
                key={post.id}
                onClick={() => onPostClick?.(post.id.toString())}
                className="w-full bg-white rounded-xl border border-gray-200 p-4 hover:shadow-md transition-shadow text-left"
              >
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center gap-2">
                    <div className="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center">
                      <Edit3 className="w-5 h-5 text-purple-600" />
                    </div>
                    <div className="text-xs text-gray-500">{post.date}</div>
                  </div>
                  <div className="flex items-center gap-1 text-sm text-red-500">
                    <Heart className="w-4 h-4 fill-current" />
                    <span className="font-semibold">{post.likes}</span>
                  </div>
                </div>
                <p className="text-sm text-gray-700 bg-gray-50 rounded-lg p-3">{post.content}</p>
              </button>
            ))}
          </div>
        )}

        {activeTab === 'likes' && (
          <div className="space-y-3">
            <div className="flex items-center gap-2 mb-4">
              <Heart className="w-5 h-5 text-red-500 fill-current" />
              <h2 className="font-bold text-gray-800">좋아요 누른 글</h2>
              <span className="text-sm text-gray-500">총 {stats.likes}개</span>
            </div>
            {activityHistory.likes.map((like) => (
              <div key={like.id} className="bg-white rounded-xl border border-gray-200 p-4 hover:shadow-md transition-shadow">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <div className="w-10 h-10 bg-gradient-to-br from-red-100 to-pink-100 rounded-lg flex items-center justify-center">
                      <Heart className="w-5 h-5 text-red-500 fill-current" />
                    </div>
                    <div className="text-xs text-gray-500">{like.date}</div>
                  </div>
                </div>
                <p className="text-sm text-gray-700 font-medium mb-1 bg-gray-50 rounded-lg p-2">{like.post}</p>
                <div className="flex items-center gap-1 text-xs">
                  <span className="text-gray-500">작성자:</span>
                  <button
                    onClick={() => onUserClick?.(like.author)}
                    className="font-semibold text-green-600 hover:text-green-700 hover:underline"
                  >
                    {like.author}
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}