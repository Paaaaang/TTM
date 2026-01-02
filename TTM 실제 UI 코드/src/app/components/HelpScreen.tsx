import { ArrowLeft, ChevronDown, ChevronUp } from 'lucide-react';
import { useState } from 'react';

interface HelpScreenProps {
  onBack: () => void;
}

interface FAQ {
  id: number;
  question: string;
  answer: string;
  category: string;
}

export function HelpScreen({ onBack }: HelpScreenProps) {
  const [expandedId, setExpandedId] = useState<number | null>(null);
  const [selectedCategory, setSelectedCategory] = useState<string>('전체');

  const faqs: FAQ[] = [
    {
      id: 1,
      category: '사용법',
      question: 'TAB TO ME는 어떻게 사용하나요?',
      answer: '카메라 버튼을 눌러 음식 사진을 촬영하거나 앨범에서 선택하면 자동으로 칼로리와 영양 정보를 분석해드립니다. 분석된 정보는 자동으로 저장되어 통계와 AI 코치가 맞춤 조언을 제공합니다.',
    },
    {
      id: 2,
      category: '사용법',
      question: '식단은 어떻게 기록하나요?',
      answer: '메인 화면의 아침, 점심, 저녁, 간식 카드를 클릭하면 식단 기록 화면으로 이동합니다. 카메라로 촬영하거나 앨범에서 사진을 선택하면 자동으로 음식을 분석하고 칼로리를 계산해드립니다.',
    },
    {
      id: 3,
      category: '사용법',
      question: '운동 기록은 어떻게 하나요?',
      answer: '메인 화면 하단의 식단 탭 옆에 있는 운동 탭을 클릭하거나, 카메라 버튼 옆의 운동 기록 메뉴를 이용할 수 있습니다. 운동 종류와 시간을 입력하면 소모 칼로리가 자동 계산됩니다.',
    },
    {
      id: 4,
      category: '기능',
      question: '통계 기능은 무엇인가요?',
      answer: '통계 탭에서는 일별, 주별, 월별 칼로리 섭취량과 소모량을 그래프로 확인할 수 있습니다. 영양소 균형, 운동 패턴 등도 한눈에 볼 수 있어 건강 관리에 도움이 됩니다.',
    },
    {
      id: 5,
      category: '기능',
      question: 'AI 코치는 무엇을 해주나요?',
      answer: 'AI 코치는 여러분의 식단과 운동 데이터를 분석하여 맞춤형 건강 조언을 제공합니다. 부족한 영양소, 권장 운동, 식습관 개선 방법 등을 실시간으로 안내해드립니다.',
    },
    {
      id: 6,
      category: '기능',
      question: '커뮤니티는 어떻게 사용하나요?',
      answer: '커뮤니티 탭에서 다른 사용자들과 식단, 운동 인증을 공유하고 소통할 수 있습니다. 글 작성, 좋아요, 댓글 기능을 통해 동기부여를 받고 건강한 습관을 함께 만들어갈 수 있습니다.',
    },
    {
      id: 7,
      category: '계정',
      question: '내 정보는 어떻게 수정하나요?',
      answer: '내정보 탭에서 프로필 정보를 수정할 수 있습니다. 성별, 키, 몸무게, 질병 정보, 운동량, 수면시간 등을 언제든지 업데이트할 수 있습니다.',
    },
    {
      id: 8,
      category: '계정',
      question: '친구는 어떻게 추가하나요?',
      answer: '설정 > 친구 목록에서 친구를 추가할 수 있습니다. 이름과 관계를 입력하면 친구 목록에 저장되며, 커뮤니티에서 친구들의 활동을 쉽게 확인할 수 있습니다.',
    },
    {
      id: 9,
      category: '계정',
      question: '알림은 어떻게 설정하나요?',
      answer: '설정 > 알림 수신에서 푸시 알림을 켜거나 끌 수 있습니다. 식단 기록 알림, 운동 알림, 커뮤니티 알림 등을 받을 수 있습니다.',
    },
    {
      id: 10,
      category: '데이터',
      question: '데이터는 안전하게 보관되나요?',
      answer: '모든 데이터는 안전하게 암호화되어 저장됩니다. 개인정보는 서비스 제공 목적으로만 사용되며, 제3자에게 제공되지 않습니다.',
    },
    {
      id: 11,
      category: '데이터',
      question: '기록한 데이터를 삭제할 수 있나요?',
      answer: '네, 내 활동 화면에서 각 기록을 개별적으로 삭제할 수 있습니다. 또한 설정에서 회원 탈퇴 시 모든 데이터가 영구적으로 삭제됩니다.',
    },
    {
      id: 12,
      category: '문제해결',
      question: '사진 분석이 정확하지 않아요',
      answer: '사진 촬영 시 음식이 잘 보이도록 정면에서 촬영해주세요. 조명이 밝고 음식이 선명하게 보일수록 분석 정확도가 높아집니다. 필요시 수동으로 음식 정보를 수정할 수 있습니다.',
    },
    {
      id: 13,
      category: '문제해결',
      question: '로그인이 안 돼요',
      answer: '아이디와 비밀번호를 다시 확인해주세요. 소셜 로그인 사용 시 해당 계정의 로그인 상태를 확인해주세요. 문제가 계속되면 비밀번호 재설정을 이용해보세요.',
    },
    {
      id: 14,
      category: '기타',
      question: '서비스 이용 요금이 있나요?',
      answer: 'TAB TO ME는 기본적으로 무료로 이용할 수 있습니다. 일부 프리미엄 기능은 추후 유료로 제공될 수 있습니다.',
    },
    {
      id: 15,
      category: '기타',
      question: '문의는 어디로 하나요?',
      answer: '추가 문의사항은 설정 > 고객센터 또는 이메일(support@tabtome.com)로 연락주시면 빠르게 도움드리겠습니다.',
    },
  ];

  const categories = ['전체', ...Array.from(new Set(faqs.map(faq => faq.category)))];

  const filteredFaqs = selectedCategory === '전체' 
    ? faqs 
    : faqs.filter(faq => faq.category === selectedCategory);

  const toggleExpand = (id: number) => {
    setExpandedId(expandedId === id ? null : id);
  };

  return (
    <div className="w-full max-w-md h-screen bg-gray-50 flex flex-col">
      {/* 헤더 */}
      <div className="bg-gradient-to-r from-green-500 to-green-600 text-white p-4">
        <div className="flex items-center gap-3 mb-4">
          <button onClick={onBack} className="p-1 hover:bg-white/20 rounded-lg transition-colors">
            <ArrowLeft className="w-6 h-6" />
          </button>
          <h1 className="text-xl font-bold">도움말</h1>
        </div>

        <p className="text-white/90 text-sm">자주 묻는 질문을 확인해보세요</p>
      </div>

      {/* 카테고리 필터 */}
      <div className="bg-white border-b border-gray-200 p-4">
        <div className="flex gap-2 overflow-x-auto scrollbar-hide">
          {categories.map((category) => (
            <button
              key={category}
              onClick={() => setSelectedCategory(category)}
              className={`px-4 py-2 rounded-full whitespace-nowrap font-semibold transition-colors ${
                selectedCategory === category
                  ? 'bg-green-600 text-white'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              {category}
            </button>
          ))}
        </div>
      </div>

      {/* FAQ 목록 */}
      <div className="flex-1 overflow-y-auto p-4">
        <div className="space-y-3">
          {filteredFaqs.map((faq) => (
            <div
              key={faq.id}
              className="bg-white rounded-xl border border-gray-200 overflow-hidden hover:shadow-md transition-shadow"
            >
              <button
                onClick={() => toggleExpand(faq.id)}
                className="w-full p-4 text-left flex items-start justify-between gap-3"
              >
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-xs font-semibold text-green-600 bg-green-50 px-2 py-1 rounded">
                      {faq.category}
                    </span>
                  </div>
                  <h3 className="font-semibold text-gray-800">Q. {faq.question}</h3>
                </div>
                {expandedId === faq.id ? (
                  <ChevronUp className="w-5 h-5 text-gray-400 flex-shrink-0 mt-1" />
                ) : (
                  <ChevronDown className="w-5 h-5 text-gray-400 flex-shrink-0 mt-1" />
                )}
              </button>
              
              {expandedId === faq.id && (
                <div className="px-4 pb-4 border-t border-gray-100">
                  <div className="pt-3 text-gray-600 leading-relaxed">
                    A. {faq.answer}
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>
      </div>

      {/* 하단 문의 */}
      <div className="bg-white border-t border-gray-200 p-4">
        <div className="bg-green-50 rounded-xl p-4 text-center">
          <p className="text-sm text-gray-700 mb-2">
            원하는 답변을 찾지 못하셨나요?
          </p>
          <p className="text-sm font-semibold text-green-600">
            📧 support@tabtome.com
          </p>
        </div>
      </div>
    </div>
  );
}
