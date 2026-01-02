import { ArrowLeft, ChevronDown, Image as ImageIcon, X } from 'lucide-react';
import { useState } from 'react';

interface CreatePostScreenProps {
  onBack: () => void;
  onCreatePost: (postData: { group: string; content: string; images: string[] }) => void;
}

export function CreatePostScreen({ onBack, onCreatePost }: CreatePostScreenProps) {
  const [selectedGroup, setSelectedGroup] = useState('friends');
  const [showGroupDropdown, setShowGroupDropdown] = useState(false);
  const [postContent, setPostContent] = useState('');
  const [uploadedImages, setUploadedImages] = useState<string[]>([]);

  const groups = [
    { id: 'friends', name: '친구', icon: '👥' },
    { id: 'family', name: '가족', icon: '👨‍👩‍👧‍👦' },
    { id: 'pt', name: 'PT 고객', icon: '💪' },
    { id: 'diet', name: '다이어트', icon: '🥗' },
  ];

  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files) return;

    // 실제로는 파일을 읽어서 미리보기를 생성해야 하지만, 여기서는 시뮬레이션
    const newImages = Array.from(files).map((file, index) => 
      `https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&h=400&fit=crop&crop=center`
    );
    setUploadedImages([...uploadedImages, ...newImages]);
  };

  const removeImage = (index: number) => {
    setUploadedImages(uploadedImages.filter((_, i) => i !== index));
  };

  const handlePost = () => {
    if (!postContent.trim()) return;
    onCreatePost({ group: selectedGroup, content: postContent, images: uploadedImages });
  };

  return (
    <div className="w-full max-w-md h-screen bg-white flex flex-col">
      {/* 헤더 */}
      <div className="bg-gradient-to-r from-green-500 to-green-600 text-white p-4">
        <div className="flex items-center gap-3">
          <button onClick={onBack} className="p-1 hover:bg-white/20 rounded-lg transition-colors">
            <ArrowLeft className="w-6 h-6" />
          </button>
          <h1 className="text-xl font-bold">새 게시물</h1>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {/* 그룹 선택 */}
        <div>
          <label className="block text-sm font-semibold text-gray-700 mb-2">
            어느 그룹에 올릴까요?
          </label>
          <div className="relative">
            <button
              onClick={() => setShowGroupDropdown(!showGroupDropdown)}
              className="w-full px-4 py-3 border-2 border-gray-300 rounded-lg flex items-center justify-between bg-white hover:border-green-500 transition-colors"
            >
              <span className="flex items-center gap-2">
                <span className="text-xl">{groups.find(g => g.id === selectedGroup)?.icon}</span>
                <span className="font-medium">{groups.find(g => g.id === selectedGroup)?.name}</span>
              </span>
              <ChevronDown className={`w-5 h-5 text-gray-400 transition-transform ${showGroupDropdown ? 'rotate-180' : ''}`} />
            </button>

            {showGroupDropdown && (
              <div className="absolute top-full left-0 right-0 mt-2 bg-white border border-gray-200 rounded-lg shadow-lg z-10">
                {groups.map((group) => (
                  <button
                    key={group.id}
                    onClick={() => {
                      setSelectedGroup(group.id);
                      setShowGroupDropdown(false);
                    }}
                    className={`w-full px-4 py-3 flex items-center gap-2 hover:bg-gray-50 transition-colors first:rounded-t-lg last:rounded-b-lg ${
                      selectedGroup === group.id ? 'bg-green-50 text-green-600' : 'text-gray-700'
                    }`}
                  >
                    <span className="text-xl">{group.icon}</span>
                    <span className="font-medium">{group.name}</span>
                  </button>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* 사진 업로드 */}
        <div>
          <label className="block text-sm font-semibold text-gray-700 mb-2">
            사진 추가
          </label>
          
          {/* 업로드된 이미지 미리보기 */}
          {uploadedImages.length > 0 && (
            <div className="grid grid-cols-3 gap-2 mb-3">
              {uploadedImages.map((image, index) => (
                <div key={index} className="relative aspect-square">
                  <img 
                    src={image} 
                    alt={`Upload ${index + 1}`}
                    className="w-full h-full object-cover rounded-lg"
                  />
                  <button
                    onClick={() => removeImage(index)}
                    className="absolute -top-2 -right-2 w-6 h-6 bg-red-500 text-white rounded-full flex items-center justify-center hover:bg-red-600 transition-colors shadow-md"
                  >
                    <X className="w-4 h-4" />
                  </button>
                </div>
              ))}
            </div>
          )}

          {/* 업로드 버튼 */}
          <label className="block">
            <input
              type="file"
              accept="image/*"
              multiple
              onChange={handleImageUpload}
              className="hidden"
            />
            <div className="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center cursor-pointer hover:border-green-500 hover:bg-green-50 transition-colors">
              <ImageIcon className="w-12 h-12 mx-auto mb-3 text-gray-400" />
              <p className="text-sm text-gray-600 font-medium">사진을 추가하려면 클릭하세요</p>
              <p className="text-xs text-gray-400 mt-1">JPG, PNG, GIF (최대 10MB)</p>
            </div>
          </label>
        </div>

        {/* 글 작성 */}
        <div>
          <label className="block text-sm font-semibold text-gray-700 mb-2">
            내용
          </label>
          <textarea
            value={postContent}
            onChange={(e) => setPostContent(e.target.value)}
            placeholder="무슨 생각을 하고 계신가요?&#10;오늘의 식단이나 운동 기록을 공유해보세요!"
            rows={8}
            className="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:outline-none focus:border-green-500 resize-none"
          />
          <div className="text-right text-sm text-gray-400 mt-1">
            {postContent.length} / 1000
          </div>
        </div>
      </div>

      {/* 업로드 버튼 */}
      <div className="p-4 border-t border-gray-200 bg-white">
        <button
          onClick={handlePost}
          disabled={!postContent.trim()}
          className={`w-full py-4 rounded-lg font-bold transition-all ${
            postContent.trim()
              ? 'bg-gradient-to-r from-green-500 to-green-600 text-white hover:shadow-lg active:scale-95'
              : 'bg-gray-200 text-gray-400 cursor-not-allowed'
          }`}
        >
          업로드하기
        </button>
      </div>
    </div>
  );
}