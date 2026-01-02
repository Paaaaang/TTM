import { ArrowLeft, Users, Plus, Heart, MessageCircle, Share2, TrendingUp, ChevronDown, MoreVertical, Send, Link, Instagram } from 'lucide-react';
import { useState } from 'react';
import { getTranslation, type Language } from '../utils/translations';

interface CommunityHomeScreenProps {
  language: Language;
  onBack: () => void;
  onCreatePost: () => void;
  posts: Array<{
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
  onUpdatePost: (postId: string, content: string) => void;
  onDeletePost: (postId: string) => void;
  onPostClick: (postId: string) => void;
  onViewProfile: (username: string) => void;
}

interface Comment {
  id: string;
  author: string;
  content: string;
  time: string;
}

export function CommunityHomeScreen({ language, onBack, onCreatePost, posts: userPosts = [], onUpdatePost, onDeletePost, onPostClick, onViewProfile }: CommunityHomeScreenProps) {
  const [selectedGroup, setSelectedGroup] = useState('all');
  const [showAddFriend, setShowAddFriend] = useState(false);
  const [friendId, setFriendId] = useState('');
  const [selectedFriendGroup, setSelectedFriendGroup] = useState('friends');
  const [showGroupDropdown, setShowGroupDropdown] = useState(false);
  
  const t = (key: any) => getTranslation(key, language);
  
  // 좋아요 상태 관리
  const [likedPosts, setLikedPosts] = useState<Set<string>>(new Set());
  
  // 댓글 관련 상태
  const [showComments, setShowComments] = useState<string | null>(null);
  const [commentInput, setCommentInput] = useState('');
  const [postComments, setPostComments] = useState<Record<string, Comment[]>>({});
  
  // 공유 메뉴
  const [showShareMenu, setShowShareMenu] = useState<string | null>(null);
  
  // 게시물 옵션 메뉴
  const [showPostOptions, setShowPostOptions] = useState<string | null>(null);
  const [editingPost, setEditingPost] = useState<string | null>(null);
  const [editContent, setEditContent] = useState('');

  const currentUser = JSON.parse(localStorage.getItem('currentUser') || '{}');

  const groups = [
    { id: 'all', name: t('all'), icon: '🌐', members: 245 },
    { id: 'friends', name: t('friendsGroup'), icon: '👥', members: 28 },
    { id: 'family', name: t('family'), icon: '👨‍👩‍👧‍👦', members: 8 },
    { id: 'pt', name: t('ptClients'), icon: '💪', members: 15 },
    { id: 'diet', name: t('dietGroup'), icon: '🥗', members: 52 },
  ];

  const samplePosts = [
    {
      id: '1',
      author: '김건강',
      authorAvatar: '💪',
      group: 'diet',
      content: '오늘 저녁은 샐러드로 가볍게! 다들 화이팅입니다 💪',
      time: '2시간 전',
      likes: 24,
      comments: 5,
      shares: 2,
    },
    {
      id: '2',
      author: '박운동',
      authorAvatar: '🏃',
      group: 'pt',
      content: '아침 5km 러닝 완료! 날씨가 너무 좋네요',
      time: '4시간 전',
      likes: 18,
      comments: 3,
      shares: 1,
    },
  ];

  const allPosts = [...userPosts, ...samplePosts];
  const filteredPosts = selectedGroup === 'all' 
    ? allPosts 
    : allPosts.filter(post => post.group === selectedGroup);

  const addableGroups = groups.filter(g => g.id !== 'all');

  const handleAddFriend = () => {
    if (!friendId.trim()) return;
    alert(`${friendId} ${t('add')} to ${addableGroups.find(g => g.id === selectedFriendGroup)?.name}`);
    setFriendId('');
    setShowAddFriend(false);
  };

  const handleLike = (postId: string) => {
    const newLikedPosts = new Set(likedPosts);
    if (newLikedPosts.has(postId)) {
      newLikedPosts.delete(postId);
    } else {
      newLikedPosts.add(postId);
    }
    setLikedPosts(newLikedPosts);
  };

  const handleComment = (postId: string) => {
    if (!commentInput.trim()) return;
    
    const newComment: Comment = {
      id: Date.now().toString(),
      author: currentUser.nickname || '익명',
      content: commentInput,
      time: t('now'),
    };

    setPostComments({
      ...postComments,
      [postId]: [...(postComments[postId] || []), newComment],
    });
    setCommentInput('');
  };

  const handleShare = (platform: string, postId: string) => {
    if (platform === 'kakao') {
      alert(t('shareToOtherApps'));
    } else if (platform === 'instagram') {
      alert(t('shareToInstagram'));
    } else if (platform === 'link') {
      navigator.clipboard.writeText(`https://tabtome.com/post/${postId}`);
      alert(t('linkCopied'));
    }
    setShowShareMenu(null);
  };

  const handleEditPost = (postId: string, currentContent: string) => {
    setEditingPost(postId);
    setEditContent(currentContent);
    setShowPostOptions(null);
  };

  const handleSaveEdit = (postId: string) => {
    if (!editContent.trim()) return;
    onUpdatePost(postId, editContent);
    setEditingPost(null);
    setEditContent('');
  };

  const handleDeletePost = (postId: string) => {
    if (confirm(t('deletePostConfirm'))) {
      onDeletePost(postId);
      setShowPostOptions(null);
    }
  };

  const isMyPost = (author: string) => {
    return author === currentUser.nickname;
  };

  const getPostLikes = (post: any) => {
    const baseLikes = post.likes || 0;
    return baseLikes + (likedPosts.has(post.id) ? 1 : 0);
  };

  const getPostComments = (post: any) => {
    const baseComments = post.comments || 0;
    const addedComments = postComments[post.id]?.length || 0;
    return baseComments + addedComments;
  };

  return (
    <div className="w-full max-w-md h-screen bg-gray-50 flex flex-col">
      {/* 헤더 */}
      <div className="bg-gradient-to-r from-green-500 to-green-600 text-white p-4">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-3">
            <button onClick={onBack} className="p-1 hover:bg-white/20 rounded-lg transition-colors">
              <ArrowLeft className="w-6 h-6" />
            </button>
            <div>
              <h1 className="text-xl font-bold">{t('community')}</h1>
              <p className="text-sm text-white/90">{t('communityGroups')}</p>
            </div>
          </div>
          <button 
            onClick={() => setShowAddFriend(true)}
            className="p-2 hover:bg-white/20 rounded-lg transition-colors"
          >
            <Plus className="w-6 h-6" />
          </button>
        </div>

        {/* 그룹 필터 */}
        <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-hide">
          {groups.map((group) => (
            <button
              key={group.id}
              onClick={() => setSelectedGroup(group.id)}
              className={`flex items-center gap-2 px-4 py-2 rounded-full whitespace-nowrap transition-all ${
                selectedGroup === group.id
                  ? 'bg-white text-green-600 shadow-md'
                  : 'bg-white/20 text-white hover:bg-white/30'
              }`}
            >
              <span>{group.icon}</span>
              <span className="font-semibold">{group.name}</span>
              <span className="text-xs opacity-75">({group.members})</span>
            </button>
          ))}
        </div>
      </div>

      {/* 게시물 목록 */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {filteredPosts.map((post) => (
          <div key={post.id} className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
            {/* 게시물 헤더 */}
            <div className="p-4 pb-3">
              <div className="flex items-center justify-between mb-3">
                <button
                  onClick={() => onViewProfile(post.author)}
                  className="flex items-center gap-3 hover:bg-gray-50 rounded-lg p-2 -ml-2 transition-colors"
                >
                  <div className="w-10 h-10 bg-gradient-to-br from-green-400 to-green-600 rounded-full flex items-center justify-center text-xl">
                    {post.authorAvatar}
                  </div>
                  <div>
                    <div className="font-semibold text-gray-800">{post.author}</div>
                    <div className="flex items-center gap-2 text-xs text-gray-500">
                      <span className="bg-green-50 text-green-600 px-2 py-0.5 rounded-full">
                        {groups.find(g => g.id === post.group)?.name || post.group}
                      </span>
                      <span>·</span>
                      <span>{post.time}</span>
                    </div>
                  </div>
                </button>
                <div className="relative">
                  <button 
                    onClick={() => setShowPostOptions(showPostOptions === post.id ? null : post.id)}
                    className="text-gray-400 hover:text-gray-600 p-1"
                  >
                    <MoreVertical className="w-5 h-5" />
                  </button>
                  {showPostOptions === post.id && (
                    <div className="absolute right-0 top-8 bg-white border border-gray-200 rounded-lg shadow-lg z-10 min-w-[120px]">
                      {isMyPost(post.author) ? (
                        <>
                          <button
                            onClick={() => handleEditPost(post.id, post.content)}
                            className="w-full px-4 py-2 text-left hover:bg-gray-50 transition-colors text-sm text-gray-700"
                          >
                            {t('edit')}
                          </button>
                          <button
                            onClick={() => handleDeletePost(post.id)}
                            className="w-full px-4 py-2 text-left hover:bg-gray-50 transition-colors text-sm text-red-600"
                          >
                            {t('delete')}
                          </button>
                        </>
                      ) : (
                        <>
                          <button
                            onClick={() => {
                              alert(`${post.author} ${t('hidePost')}`);
                              setShowPostOptions(null);
                            }}
                            className="w-full px-4 py-2 text-left hover:bg-gray-50 transition-colors text-sm text-gray-700"
                          >
                            {t('hidePost')}
                          </button>
                          <button
                            onClick={() => {
                              alert(t('reportPost'));
                              setShowPostOptions(null);
                            }}
                            className="w-full px-4 py-2 text-left hover:bg-gray-50 transition-colors text-sm text-red-600"
                          >
                            {t('reportPost')}
                          </button>
                        </>
                      )}
                    </div>
                  )}
                </div>
              </div>

              {/* 게시물 내용 */}
              {editingPost === post.id ? (
                <div className="space-y-2 mb-3">
                  <textarea
                    value={editContent}
                    onChange={(e) => setEditContent(e.target.value)}
                    placeholder={t('writeContent')}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-green-500 resize-none"
                    rows={3}
                  />
                  <div className="flex gap-2">
                    <button
                      onClick={() => handleSaveEdit(post.id)}
                      className="px-4 py-1 bg-green-600 text-white rounded-lg hover:bg-green-700 text-sm"
                    >
                      {t('save')}
                    </button>
                    <button
                      onClick={() => setEditingPost(null)}
                      className="px-4 py-1 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 text-sm"
                    >
                      {t('cancel')}
                    </button>
                  </div>
                </div>
              ) : (
                <button
                  onClick={() => onPostClick(post.id)}
                  className="w-full text-left mb-3 hover:bg-gray-50 rounded-lg p-2 -ml-2 transition-colors"
                >
                  <p className="text-gray-700">{post.content}</p>
                </button>
              )}

              {/* 게시물 이미지 */}
              {post.image && (
                <button
                  onClick={() => onPostClick(post.id)}
                  className="w-full mb-3"
                >
                  <img 
                    src={post.image} 
                    alt="Post" 
                    className="w-full rounded-lg object-cover max-h-80 hover:opacity-95 transition-opacity"
                  />
                </button>
              )}

              {/* 액션 버튼 */}
              <div className="flex items-center justify-around border-t border-gray-100 pt-3">
                <button 
                  onClick={() => handleLike(post.id)}
                  className={`flex items-center gap-2 transition-colors ${
                    likedPosts.has(post.id) ? 'text-red-500' : 'text-gray-500 hover:text-red-500'
                  }`}
                >
                  <Heart className={`w-5 h-5 ${likedPosts.has(post.id) ? 'fill-current' : ''}`} />
                  <span className="text-sm font-semibold">{getPostLikes(post)}</span>
                </button>
                <button 
                  onClick={() => setShowComments(showComments === post.id ? null : post.id)}
                  className="flex items-center gap-2 text-gray-500 hover:text-blue-500 transition-colors"
                >
                  <MessageCircle className="w-5 h-5" />
                  <span className="text-sm font-semibold">{getPostComments(post)}</span>
                </button>
                <div className="relative">
                  <button 
                    onClick={() => setShowShareMenu(showShareMenu === post.id ? null : post.id)}
                    className="flex items-center gap-2 text-gray-500 hover:text-green-500 transition-colors"
                  >
                    <Share2 className="w-5 h-5" />
                    <span className="text-sm font-semibold">{post.shares}</span>
                  </button>
                  {showShareMenu === post.id && (
                    <div className="absolute right-0 bottom-full mb-2 bg-white border border-gray-200 rounded-lg shadow-lg z-10 p-2 min-w-[160px]">
                      <button
                        onClick={() => handleShare('link', post.id)}
                        className="w-full px-3 py-2 flex items-center gap-2 hover:bg-gray-50 rounded transition-colors text-sm"
                      >
                        <Link className="w-5 h-5 text-gray-600" />
                        <span>{t('copyLink')}</span>
                      </button>
                      <button
                        onClick={() => handleShare('instagram', post.id)}
                        className="w-full px-3 py-2 flex items-center gap-2 hover:bg-gray-50 rounded transition-colors text-sm"
                      >
                        <Instagram className="w-5 h-5 text-pink-600" />
                        <span>{t('shareToInstagram')}</span>
                      </button>
                    </div>
                  )}
                </div>
              </div>

              {/* 댓글 섹션 */}
              {showComments === post.id && (
                <div className="mt-3 pt-3 border-t border-gray-100">
                  {/* 기존 댓글 */}
                  <div className="space-y-2 mb-3 max-h-48 overflow-y-auto">
                    {postComments[post.id]?.map((comment) => (
                      <div key={comment.id} className="flex gap-2">
                        <div className="w-8 h-8 bg-gradient-to-br from-blue-400 to-blue-600 rounded-full flex items-center justify-center text-white text-xs flex-shrink-0">
                          {comment.author[0]}
                        </div>
                        <div className="flex-1 bg-gray-50 rounded-lg p-2">
                          <div className="flex items-center gap-2 mb-1">
                            <span className="font-semibold text-sm text-gray-800">{comment.author}</span>
                            <span className="text-xs text-gray-500">{comment.time}</span>
                          </div>
                          <p className="text-sm text-gray-700">{comment.content}</p>
                        </div>
                      </div>
                    ))}
                  </div>
                  
                  {/* 댓글 입력 */}
                  <div className="flex gap-2">
                    <input
                      type="text"
                      value={commentInput}
                      onChange={(e) => setCommentInput(e.target.value)}
                      placeholder={t('addComment')}
                      className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-green-500 text-sm"
                      onKeyPress={(e) => {
                        if (e.key === 'Enter') {
                          handleComment(post.id);
                        }
                      }}
                    />
                    <button
                      onClick={() => handleComment(post.id)}
                      className="px-3 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
                    >
                      <Send className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        ))}
      </div>

      {/* 새 게시물 작성 버튼 */}
      <button 
        onClick={onCreatePost}
        className="fixed bottom-20 right-6 w-16 h-16 bg-gradient-to-br from-green-500 to-green-600 rounded-full shadow-xl flex items-center justify-center hover:shadow-2xl transition-all hover:scale-110 z-40"
      >
        <Plus className="w-8 h-8 text-white" />
      </button>

      {/* 친구 추가 모달 */}
      {showAddFriend && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl w-full max-w-sm p-6">
            <h3 className="text-xl font-bold text-gray-800 mb-4">{t('addFriend')}</h3>
            
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  {t('friendId')}
                </label>
                <input
                  type="text"
                  value={friendId}
                  onChange={(e) => setFriendId(e.target.value)}
                  placeholder={t('friendId')}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:border-green-500"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  {t('communityGroups')}
                </label>
                <div className="relative">
                  <button
                    onClick={() => setShowGroupDropdown(!showGroupDropdown)}
                    className="w-full px-4 py-3 border border-gray-300 rounded-lg flex items-center justify-between bg-white hover:border-green-500 transition-colors"
                  >
                    <span className="flex items-center gap-2">
                      <span>{addableGroups.find(g => g.id === selectedFriendGroup)?.icon}</span>
                      <span>{addableGroups.find(g => g.id === selectedFriendGroup)?.name}</span>
                    </span>
                    <ChevronDown className={`w-5 h-5 text-gray-400 transition-transform ${showGroupDropdown ? 'rotate-180' : ''}`} />
                  </button>

                  {showGroupDropdown && (
                    <div className="absolute top-full left-0 right-0 mt-2 bg-white border border-gray-200 rounded-lg shadow-lg z-10 max-h-48 overflow-y-auto">
                      {addableGroups.map((group) => (
                        <button
                          key={group.id}
                          onClick={() => {
                            setSelectedFriendGroup(group.id);
                            setShowGroupDropdown(false);
                          }}
                          className={`w-full px-4 py-3 flex items-center gap-2 hover:bg-gray-50 transition-colors ${
                            selectedFriendGroup === group.id ? 'bg-green-50 text-green-600' : 'text-gray-700'
                          }`}
                        >
                          <span>{group.icon}</span>
                          <span>{group.name}</span>
                        </button>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            </div>

            <div className="flex gap-3 mt-6">
              <button
                onClick={() => {
                  setShowAddFriend(false);
                  setFriendId('');
                  setShowGroupDropdown(false);
                }}
                className="flex-1 py-3 bg-gray-100 text-gray-700 rounded-lg font-semibold hover:bg-gray-200 transition-colors"
              >
                {t('cancel')}
              </button>
              <button
                onClick={handleAddFriend}
                disabled={!friendId.trim()}
                className={`flex-1 py-3 rounded-lg font-semibold transition-colors ${
                  friendId.trim()
                    ? 'bg-green-600 text-white hover:bg-green-700'
                    : 'bg-gray-200 text-gray-400 cursor-not-allowed'
                }`}
              >
                {t('add')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}