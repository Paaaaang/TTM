import { ArrowLeft, Award, Calendar, TrendingUp, Heart, MessageCircle, Share2, X } from 'lucide-react';
import { useState } from 'react';

interface UserProfileScreenProps {
  username: string;
  onBack: () => void;
  onPostClick: (postId: string) => void;
  userPosts: Array<{
    id: string;
    author: string;
    authorAvatar: string;
    group: string;
    content: string;
    image?: string;
    time: string;
    likes: number;
    comments: number;
    shares: number;
  }>;
}

interface Badge {
  id: string;
  name: string;
  description: string;
  icon: string;
  earned: boolean;
  date: string | null;
  howToEarn: string;
}

export function UserProfileScreen({ username, onBack, onPostClick, userPosts }: UserProfileScreenProps) {
  const [activeTab, setActiveTab] = useState<'posts' | 'badges'>('posts');
  const [selectedBadge, setSelectedBadge] = useState<Badge | null>(null);

  // 해당 사용자의 게시물만 필터링
  const posts = userPosts.filter(post => post.author === username);

  // 뱃지 데이터
  const badges: Badge[] = [
    {
      id: '1',
      name: '첫 걸음',
      description: '첫 게시물 작성',
      icon: '🎯',
      earned: true,
      date: '2024.12.01',
      howToEarn: '첫 게시물을 작성하세요.',
    },
    {
      id: '2',
      name: '소통왕',
      description: '댓글 50개 작성',
      icon: '💬',
      earned: posts.length >= 5,
      date: posts.length >= 5 ? '2024.12.10' : null,
      howToEarn: '50개 이상의 댓글을 작성하세요.',
    },
    {
      id: '3',
      name: '인기스타',
      description: '좋아요 100개 받기',
      icon: '⭐',
      earned: false,
      date: null,
      howToEarn: '100개 이상의 좋아요를 받으세요.',
    },
    {
      id: '4',
      name: '꾸준함',
      description: '7일 연속 활동',
      icon: '🔥',
      earned: posts.length >= 3,
      date: posts.length >= 3 ? '2024.12.15' : null,
      howToEarn: '7일 이상 연속으로 게시물을 작성하세요.',
    },
    {
      id: '5',
      name: '건강지킴이',
      description: '30일 연속 식단 기록',
      icon: '🥗',
      earned: false,
      date: null,
      howToEarn: '30일 이상 연속으로 식단을 기록하세요.',
    },
    {
      id: '6',
      name: '운동마니아',
      description: '운동 100회 기록',
      icon: '💪',
      earned: posts.length >= 10,
      date: posts.length >= 10 ? '2024.12.20' : null,
      howToEarn: '100회 이상 운동을 기록하세요.',
    },
  ];

  const earnedBadges = badges.filter(badge => badge.earned);
  
  // 활동 통계
  const stats = {
    posts: posts.length,
    totalLikes: posts.reduce((sum, post) => sum + post.likes, 0),
    totalComments: posts.reduce((sum, post) => sum + post.comments, 0),
    badges: earnedBadges.length,
  };

  return (
    <div className="w-full max-w-md h-screen bg-gray-50 flex flex-col">
      {/* 헤더 */}
      <div className="bg-gradient-to-r from-green-500 to-green-600 text-white">
        <div className="p-4 flex items-center gap-3">
          <button onClick={onBack} className="p-1 hover:bg-white/20 rounded-lg transition-colors">
            <ArrowLeft className="w-6 h-6" />
          </button>
          <h1 className="text-xl font-bold">프로필</h1>
        </div>

        {/* 프로필 정보 */}
        <div className="p-6 pb-8">
          <div className="flex items-center gap-4 mb-6">
            <div className="w-20 h-20 bg-white/20 backdrop-blur-sm rounded-full flex items-center justify-center text-4xl border-4 border-white/30">
              {username[0]}
            </div>
            <div>
              <h2 className="text-2xl font-bold mb-1">{username}</h2>
              <p className="text-sm text-white/80 flex items-center gap-1">
                <Calendar className="w-4 h-4" />
                활동 시작: 2024.12.01
              </p>
            </div>
          </div>

          {/* 통계 */}
          <div className="grid grid-cols-4 gap-3">
            <div className="bg-white/20 backdrop-blur-sm rounded-lg p-3 text-center">
              <div className="text-2xl font-bold mb-1">{stats.posts}</div>
              <div className="text-xs text-white/80">게시물</div>
            </div>
            <div className="bg-white/20 backdrop-blur-sm rounded-lg p-3 text-center">
              <div className="text-2xl font-bold mb-1">{stats.totalLikes}</div>
              <div className="text-xs text-white/80">좋아요</div>
            </div>
            <div className="bg-white/20 backdrop-blur-sm rounded-lg p-3 text-center">
              <div className="text-2xl font-bold mb-1">{stats.totalComments}</div>
              <div className="text-xs text-white/80">댓글</div>
            </div>
            <div className="bg-white/20 backdrop-blur-sm rounded-lg p-3 text-center">
              <div className="text-2xl font-bold mb-1">{stats.badges}</div>
              <div className="text-xs text-white/80">뱃지</div>
            </div>
          </div>
        </div>

        {/* 탭 */}
        <div className="flex border-b border-white/20">
          <button
            onClick={() => setActiveTab('posts')}
            className={`flex-1 py-3 font-semibold transition-all ${
              activeTab === 'posts'
                ? 'border-b-2 border-white text-white'
                : 'text-white/60 hover:text-white/80'
            }`}
          >
            게시물 ({stats.posts})
          </button>
          <button
            onClick={() => setActiveTab('badges')}
            className={`flex-1 py-3 font-semibold transition-all ${
              activeTab === 'badges'
                ? 'border-b-2 border-white text-white'
                : 'text-white/60 hover:text-white/80'
            }`}
          >
            뱃지 ({stats.badges})
          </button>
        </div>
      </div>

      {/* 컨텐츠 */}
      <div className="flex-1 overflow-y-auto">
        {activeTab === 'posts' ? (
          <div className="p-4 space-y-4">
            {posts.length === 0 ? (
              <div className="text-center py-12">
                <div className="text-6xl mb-4">📝</div>
                <p className="text-gray-500">작성한 게시물이 없습니다</p>
              </div>
            ) : (
              posts.map((post) => (
                <button
                  key={post.id}
                  onClick={() => onPostClick(post.id)}
                  className="w-full bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden hover:shadow-md transition-shadow text-left"
                >
                  <div className="p-4">
                    {/* 게시물 헤더 */}
                    <div className="flex items-center gap-2 mb-3">
                      <span className="bg-green-50 text-green-600 px-2 py-1 rounded-full text-xs font-medium">
                        {post.group}
                      </span>
                      <span className="text-xs text-gray-500">{post.time}</span>
                    </div>

                    {/* 게시물 내용 */}
                    <p className="text-gray-700 mb-3 line-clamp-3">{post.content}</p>

                    {/* 게시물 이미지 */}
                    {post.image && (
                      <img 
                        src={post.image} 
                        alt="게시물 이미지" 
                        className="w-full rounded-lg mb-3 object-cover max-h-48"
                      />
                    )}

                    {/* 액션 통계 */}
                    <div className="flex items-center gap-4 text-sm text-gray-500">
                      <div className="flex items-center gap-1">
                        <Heart className="w-4 h-4" />
                        <span>{post.likes}</span>
                      </div>
                      <div className="flex items-center gap-1">
                        <MessageCircle className="w-4 h-4" />
                        <span>{post.comments}</span>
                      </div>
                      <div className="flex items-center gap-1">
                        <Share2 className="w-4 h-4" />
                        <span>{post.shares}</span>
                      </div>
                    </div>
                  </div>
                </button>
              ))
            )}
          </div>
        ) : (
          <div className="p-4 space-y-4">
            {/* 획득한 뱃지 */}
            {earnedBadges.length > 0 && (
              <div>
                <h3 className="font-semibold text-gray-800 mb-3 flex items-center gap-2">
                  <Award className="w-5 h-5 text-yellow-500" />
                  획득한 뱃지
                </h3>
                <div className="grid grid-cols-2 gap-3">
                  {earnedBadges.map((badge) => (
                    <button
                      key={badge.id}
                      onClick={() => setSelectedBadge(badge)}
                      className="bg-gradient-to-br from-yellow-50 to-orange-50 border-2 border-yellow-200 rounded-xl p-4 text-center hover:scale-105 transition-transform"
                    >
                      <div className="text-4xl mb-2">{badge.icon}</div>
                      <div className="font-semibold text-gray-800 mb-1">{badge.name}</div>
                      <div className="text-xs text-gray-600 mb-2">{badge.description}</div>
                      <div className="text-xs text-gray-500">{badge.date}</div>
                    </button>
                  ))}
                </div>
              </div>
            )}

            {/* 미획득 뱃지 */}
            <div>
              <h3 className="font-semibold text-gray-800 mb-3 flex items-center gap-2">
                <TrendingUp className="w-5 h-5 text-gray-500" />
                도전 과제
              </h3>
              <div className="grid grid-cols-2 gap-3">
                {badges.filter(b => !b.earned).map((badge) => (
                  <div
                    key={badge.id}
                    className="bg-white border-2 border-gray-200 rounded-xl p-4 text-center opacity-60"
                  >
                    <div className="text-4xl mb-2 grayscale">{badge.icon}</div>
                    <div className="font-semibold text-gray-800 mb-1">{badge.name}</div>
                    <div className="text-xs text-gray-600">{badge.description}</div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
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
                  <div className="text-xs text-gray-600">획득일: {selectedBadge.date}</div>
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