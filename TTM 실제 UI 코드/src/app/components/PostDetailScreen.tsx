import { ArrowLeft, Heart, MessageCircle, Share2, Send, Link, Instagram, MoreVertical } from 'lucide-react';
import { useState } from 'react';

interface Comment {
  id: string;
  author: string;
  authorAvatar: string;
  content: string;
  time: string;
  likes: number;
}

interface PostDetailScreenProps {
  post: {
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
  };
  onBack: () => void;
  onEdit: () => void;
  onDelete: () => void;
  onViewProfile: (author: string) => void;
  isMyPost: boolean;
}

export function PostDetailScreen({ post, onBack, onEdit, onDelete, isMyPost, onViewProfile }: PostDetailScreenProps) {
  const [isLiked, setIsLiked] = useState(false);
  const [commentInput, setCommentInput] = useState('');
  const [comments, setComments] = useState<Comment[]>([
    {
      id: '1',
      author: '김건강',
      authorAvatar: '💪',
      content: '정말 멋지네요! 저도 따라해봐야겠어요',
      time: '1시간 전',
      likes: 5,
    },
    {
      id: '2',
      author: '이운동',
      authorAvatar: '🏃',
      content: '대단하세요! 꾸준히 하시는 모습이 보기 좋습니다',
      time: '30분 전',
      likes: 3,
    },
  ]);
  const [likedComments, setLikedComments] = useState<Set<string>>(new Set());
  const [showShareMenu, setShowShareMenu] = useState(false);
  const [showPostOptions, setShowPostOptions] = useState(false);

  const currentUser = JSON.parse(localStorage.getItem('currentUser') || '{}');

  const handleComment = () => {
    if (!commentInput.trim()) return;
    
    const newComment: Comment = {
      id: Date.now().toString(),
      author: currentUser.nickname || '익명',
      authorAvatar: currentUser.nickname ? currentUser.nickname[0] : '😊',
      content: commentInput,
      time: '방금 전',
      likes: 0,
    };

    setComments([...comments, newComment]);
    setCommentInput('');
  };

  const handleLikeComment = (commentId: string) => {
    const newLikedComments = new Set(likedComments);
    if (newLikedComments.has(commentId)) {
      newLikedComments.delete(commentId);
    } else {
      newLikedComments.add(commentId);
    }
    setLikedComments(newLikedComments);
  };

  const handleShare = (platform: string) => {
    if (platform === 'kakao') {
      alert('카카오톡으로 공유합니다!');
    } else if (platform === 'instagram') {
      alert('인스타그램으로 공유합니다!');
    } else if (platform === 'link') {
      navigator.clipboard.writeText(`https://tabtome.com/post/${post.id}`);
      alert('링크가 복사되었습니다!');
    }
    setShowShareMenu(false);
  };

  const getCommentLikes = (comment: Comment) => {
    return comment.likes + (likedComments.has(comment.id) ? 1 : 0);
  };

  return (
    <div className="w-full max-w-md h-screen bg-gray-50 flex flex-col">
      {/* 헤더 */}
      <div className="bg-gradient-to-r from-green-500 to-green-600 text-white p-4 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button onClick={onBack} className="p-1 hover:bg-white/20 rounded-lg transition-colors">
            <ArrowLeft className="w-6 h-6" />
          </button>
          <h1 className="text-xl font-bold">게시물</h1>
        </div>
      </div>

      {/* 게시물 상세 */}
      <div className="flex-1 overflow-y-auto">
        <div className="bg-white border-b border-gray-200">
          {/* 게시물 헤더 */}
          <div className="p-4">
            <div className="flex items-center justify-between mb-3">
              <button 
                onClick={() => onViewProfile(post.author)}
                className="flex items-center gap-3 hover:bg-gray-50 rounded-lg p-2 -ml-2 transition-colors"
              >
                <div className="w-12 h-12 bg-gradient-to-br from-green-400 to-green-600 rounded-full flex items-center justify-center text-2xl">
                  {post.authorAvatar}
                </div>
                <div>
                  <div className="font-semibold text-gray-800">{post.author}</div>
                  <div className="flex items-center gap-2 text-xs text-gray-500">
                    <span className="bg-green-50 text-green-600 px-2 py-0.5 rounded-full">
                      {post.group}
                    </span>
                    <span>·</span>
                    <span>{post.time}</span>
                  </div>
                </div>
              </button>
              <div className="relative">
                <button 
                  onClick={() => setShowPostOptions(!showPostOptions)}
                  className="text-gray-400 hover:text-gray-600 p-2"
                >
                  <MoreVertical className="w-5 h-5" />
                </button>
                {showPostOptions && (
                  <div className="absolute right-0 top-10 bg-white border border-gray-200 rounded-lg shadow-lg z-10 min-w-[120px]">
                    {isMyPost ? (
                      <>
                        <button
                          onClick={() => {
                            setShowPostOptions(false);
                            onEdit();
                          }}
                          className="w-full px-4 py-2 text-left hover:bg-gray-50 transition-colors text-sm text-gray-700"
                        >
                          수정
                        </button>
                        <button
                          onClick={() => {
                            setShowPostOptions(false);
                            if (confirm('정말 이 게시물을 삭제하시겠습니까?')) {
                              onDelete();
                            }
                          }}
                          className="w-full px-4 py-2 text-left hover:bg-gray-50 transition-colors text-sm text-red-600"
                        >
                          삭제
                        </button>
                      </>
                    ) : (
                      <>
                        <button
                          onClick={() => {
                            alert(`${post.author}님을 차단했습니다.`);
                            setShowPostOptions(false);
                          }}
                          className="w-full px-4 py-2 text-left hover:bg-gray-50 transition-colors text-sm text-gray-700"
                        >
                          차단
                        </button>
                        <button
                          onClick={() => {
                            alert(`이 게시물을 신고했습니다. 검토 후 조치하겠습니다.`);
                            setShowPostOptions(false);
                          }}
                          className="w-full px-4 py-2 text-left hover:bg-gray-50 transition-colors text-sm text-red-600"
                        >
                          신고
                        </button>
                      </>
                    )}
                  </div>
                )}
              </div>
            </div>

            {/* 게시물 내용 */}
            <p className="text-gray-700 mb-4 text-base leading-relaxed">{post.content}</p>

            {/* 게시물 이미지 */}
            {post.image && (
              <img 
                src={post.image} 
                alt="게시물 이미지" 
                className="w-full rounded-lg mb-4 object-cover max-h-96"
              />
            )}

            {/* 좋아요/댓글/공유 카운트 */}
            <div className="flex items-center justify-between text-sm text-gray-500 mb-3 pb-3 border-b border-gray-100">
              <div className="flex items-center gap-4">
                <span>좋아요 {post.likes + (isLiked ? 1 : 0)}개</span>
                <span>댓글 {comments.length}개</span>
              </div>
              <span>공유 {post.shares}회</span>
            </div>

            {/* 액션 버튼 */}
            <div className="flex items-center justify-around">
              <button 
                onClick={() => setIsLiked(!isLiked)}
                className={`flex items-center gap-2 transition-colors ${
                  isLiked ? 'text-red-500' : 'text-gray-500 hover:text-red-500'
                }`}
              >
                <Heart className={`w-6 h-6 ${isLiked ? 'fill-current' : ''}`} />
                <span className="text-sm font-semibold">좋아요</span>
              </button>
              <button className="flex items-center gap-2 text-gray-500 hover:text-blue-500 transition-colors">
                <MessageCircle className="w-6 h-6" />
                <span className="text-sm font-semibold">댓글</span>
              </button>
              <div className="relative">
                <button 
                  onClick={() => setShowShareMenu(!showShareMenu)}
                  className="flex items-center gap-2 text-gray-500 hover:text-green-500 transition-colors"
                >
                  <Share2 className="w-6 h-6" />
                  <span className="text-sm font-semibold">공유</span>
                </button>
                {showShareMenu && (
                  <div className="absolute right-0 bottom-full mb-2 bg-white border border-gray-200 rounded-lg shadow-lg z-10 p-2 min-w-[160px]">
                    <button
                      onClick={() => handleShare('kakao')}
                      className="w-full px-3 py-2 flex items-center gap-2 hover:bg-gray-50 rounded transition-colors text-sm"
                    >
                      <div className="w-5 h-5 bg-yellow-400 rounded flex items-center justify-center text-xs">💬</div>
                      <span>카카오톡</span>
                    </button>
                    <button
                      onClick={() => handleShare('instagram')}
                      className="w-full px-3 py-2 flex items-center gap-2 hover:bg-gray-50 rounded transition-colors text-sm"
                    >
                      <Instagram className="w-5 h-5 text-pink-600" />
                      <span>인스타그램</span>
                    </button>
                    <button
                      onClick={() => handleShare('link')}
                      className="w-full px-3 py-2 flex items-center gap-2 hover:bg-gray-50 rounded transition-colors text-sm"
                    >
                      <Link className="w-5 h-5 text-gray-600" />
                      <span>링크 복사</span>
                    </button>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>

        {/* 댓글 목록 */}
        <div className="bg-white mt-2">
          <div className="p-4 border-b border-gray-200">
            <h3 className="font-semibold text-gray-800">댓글 {comments.length}개</h3>
          </div>
          <div className="divide-y divide-gray-100">
            {comments.map((comment) => (
              <div key={comment.id} className="p-4">
                <button
                  onClick={() => onViewProfile(comment.author)}
                  className="flex gap-3 mb-2 hover:bg-gray-50 rounded-lg p-2 -ml-2 transition-colors w-full text-left"
                >
                  <div className="w-10 h-10 bg-gradient-to-br from-blue-400 to-blue-600 rounded-full flex items-center justify-center text-white flex-shrink-0">
                    {comment.authorAvatar}
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <span className="font-semibold text-sm text-gray-800">{comment.author}</span>
                      <span className="text-xs text-gray-500">{comment.time}</span>
                    </div>
                    <p className="text-sm text-gray-700">{comment.content}</p>
                  </div>
                </button>
                <div className="ml-14 flex items-center gap-4">
                  <button
                    onClick={() => handleLikeComment(comment.id)}
                    className={`flex items-center gap-1 text-xs transition-colors ${
                      likedComments.has(comment.id) ? 'text-red-500' : 'text-gray-500 hover:text-red-500'
                    }`}
                  >
                    <Heart className={`w-4 h-4 ${likedComments.has(comment.id) ? 'fill-current' : ''}`} />
                    <span>{getCommentLikes(comment)}</span>
                  </button>
                  <button className="text-xs text-gray-500 hover:text-blue-500 transition-colors">
                    답글
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* 댓글 입력 */}
      <div className="bg-white border-t border-gray-200 p-4">
        <div className="flex gap-2">
          <div className="w-10 h-10 bg-gradient-to-br from-green-400 to-green-600 rounded-full flex items-center justify-center text-white flex-shrink-0">
            {currentUser.nickname ? currentUser.nickname[0] : '😊'}
          </div>
          <input
            type="text"
            value={commentInput}
            onChange={(e) => setCommentInput(e.target.value)}
            placeholder="댓글을 입력하세요..."
            className="flex-1 px-4 py-2 border border-gray-300 rounded-full focus:outline-none focus:border-green-500"
            onKeyPress={(e) => {
              if (e.key === 'Enter') {
                handleComment();
              }
            }}
          />
          <button
            onClick={handleComment}
            disabled={!commentInput.trim()}
            className={`px-4 py-2 rounded-full transition-colors ${
              commentInput.trim()
                ? 'bg-green-600 text-white hover:bg-green-700'
                : 'bg-gray-200 text-gray-400 cursor-not-allowed'
            }`}
          >
            <Send className="w-5 h-5" />
          </button>
        </div>
      </div>
    </div>
  );
}