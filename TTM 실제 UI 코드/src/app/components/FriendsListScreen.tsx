import { ArrowLeft, UserPlus, Search, Users, X } from 'lucide-react';
import { useState, useEffect } from 'react';

interface FriendsListScreenProps {
  onBack: () => void;
}

interface Friend {
  id: string;
  name: string;
  relation: string;
  avatar: string;
  addedDate: string;
}

export function FriendsListScreen({ onBack }: FriendsListScreenProps) {
  const [friends, setFriends] = useState<Friend[]>([]);
  const [showAddModal, setShowAddModal] = useState(false);
  const [newFriendName, setNewFriendName] = useState('');
  const [newFriendRelation, setNewFriendRelation] = useState('친구');
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    // localStorage에서 친구 목록 불러오기
    const savedFriends = localStorage.getItem('friends');
    if (savedFriends) {
      setFriends(JSON.parse(savedFriends));
    }
  }, []);

  const saveFriends = (updatedFriends: Friend[]) => {
    setFriends(updatedFriends);
    localStorage.setItem('friends', JSON.stringify(updatedFriends));
  };

  const handleAddFriend = () => {
    if (!newFriendName.trim()) {
      alert('이름을 입력해주세요.');
      return;
    }

    const newFriend: Friend = {
      id: Date.now().toString(),
      name: newFriendName.trim(),
      relation: newFriendRelation,
      avatar: newFriendName.trim()[0],
      addedDate: new Date().toLocaleDateString('ko-KR'),
    };

    saveFriends([...friends, newFriend]);
    setNewFriendName('');
    setNewFriendRelation('친구');
    setShowAddModal(false);
  };

  const handleDeleteFriend = (id: string) => {
    if (window.confirm('정말 삭제하시겠습니까?')) {
      saveFriends(friends.filter(f => f.id !== id));
    }
  };

  const filteredFriends = friends.filter(friend =>
    friend.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    friend.relation.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const friendsByRelation = filteredFriends.reduce((acc, friend) => {
    if (!acc[friend.relation]) {
      acc[friend.relation] = [];
    }
    acc[friend.relation].push(friend);
    return acc;
  }, {} as Record<string, Friend[]>);

  return (
    <div className="w-full max-w-md h-screen bg-gray-50 flex flex-col">
      {/* 헤더 */}
      <div className="bg-gradient-to-r from-purple-500 to-purple-600 text-white p-4">
        <div className="flex items-center gap-3 mb-4">
          <button onClick={onBack} className="p-1 hover:bg-white/20 rounded-lg transition-colors">
            <ArrowLeft className="w-6 h-6" />
          </button>
          <h1 className="text-xl font-bold">친구 목록</h1>
        </div>

        {/* 검색바 */}
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-white/70" />
          <input
            type="text"
            placeholder="이름 또는 관계로 검색"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-2 rounded-lg bg-white/20 backdrop-blur-sm text-white placeholder-white/70 border border-white/30 focus:outline-none focus:ring-2 focus:ring-white/50"
          />
        </div>
      </div>

      {/* 친구 추가 버튼 */}
      <div className="p-4">
        <button
          onClick={() => setShowAddModal(true)}
          className="w-full bg-purple-600 text-white py-3 rounded-xl font-semibold hover:bg-purple-700 transition-colors flex items-center justify-center gap-2"
        >
          <UserPlus className="w-5 h-5" />
          친구 추가
        </button>
      </div>

      {/* 친구 목록 */}
      <div className="flex-1 overflow-y-auto px-4 pb-4">
        {friends.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-12">
            <Users className="w-16 h-16 text-gray-300 mb-4" />
            <p className="text-gray-500 text-center">
              아직 추가된 친구가 없습니다.<br />
              친구를 추가해보세요!
            </p>
          </div>
        ) : filteredFriends.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-12">
            <Search className="w-16 h-16 text-gray-300 mb-4" />
            <p className="text-gray-500">검색 결과가 없습니다.</p>
          </div>
        ) : (
          <div className="space-y-4">
            {Object.entries(friendsByRelation).map(([relation, relationFriends]) => (
              <div key={relation}>
                <h3 className="text-sm font-semibold text-gray-500 mb-2 px-2">
                  {relation} ({relationFriends.length})
                </h3>
                <div className="space-y-2">
                  {relationFriends.map((friend) => (
                    <div
                      key={friend.id}
                      className="bg-white rounded-xl border border-gray-200 p-4 hover:shadow-md transition-shadow"
                    >
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-3">
                          <div className="w-12 h-12 bg-purple-100 rounded-full flex items-center justify-center text-purple-600 text-xl font-bold">
                            {friend.avatar}
                          </div>
                          <div>
                            <h4 className="font-semibold text-gray-800">{friend.name}</h4>
                            <p className="text-sm text-gray-500">{friend.addedDate} 추가</p>
                          </div>
                        </div>
                        <button
                          onClick={() => handleDeleteFriend(friend.id)}
                          className="p-2 text-red-500 hover:bg-red-50 rounded-lg transition-colors"
                        >
                          <X className="w-5 h-5" />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* 친구 추가 모달 */}
      {showAddModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl p-6 max-w-sm w-full">
            <h3 className="text-xl font-bold text-gray-800 mb-4">친구 추가</h3>
            
            <div className="space-y-4 mb-6">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  이름
                </label>
                <input
                  type="text"
                  value={newFriendName}
                  onChange={(e) => setNewFriendName(e.target.value)}
                  placeholder="친구 이름 입력"
                  className="w-full px-4 py-2 rounded-lg border border-gray-300 focus:outline-none focus:ring-2 focus:ring-purple-500"
                />
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  관계
                </label>
                <select
                  value={newFriendRelation}
                  onChange={(e) => setNewFriendRelation(e.target.value)}
                  className="w-full px-4 py-2 rounded-lg border border-gray-300 focus:outline-none focus:ring-2 focus:ring-purple-500"
                >
                  <option value="친구">친구</option>
                  <option value="가족">가족</option>
                  <option value="동료">동료</option>
                  <option value="모임">모임</option>
                  <option value="운동 파트너">운동 파트너</option>
                  <option value="기타">기타</option>
                </select>
              </div>
            </div>

            <div className="flex gap-3">
              <button
                onClick={() => {
                  setShowAddModal(false);
                  setNewFriendName('');
                  setNewFriendRelation('친구');
                }}
                className="flex-1 py-3 px-4 rounded-lg border border-gray-300 font-semibold text-gray-700 hover:bg-gray-50 transition-colors"
              >
                취소
              </button>
              <button
                onClick={handleAddFriend}
                className="flex-1 py-3 px-4 rounded-lg bg-purple-600 font-semibold text-white hover:bg-purple-700 transition-colors"
              >
                추가
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
