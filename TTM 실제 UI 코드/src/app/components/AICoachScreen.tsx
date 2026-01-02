import { useState, useRef, useEffect } from 'react';
import { ArrowLeft, Send, Sparkles } from 'lucide-react';
import { getTranslation, type Language } from '../utils/translations';

interface AICoachScreenProps {
  language: Language;
  onBack: () => void;
}

interface Message {
  id: number;
  type: 'user' | 'ai';
  content: string;
  time: string;
}

export function AICoachScreen({ language, onBack }: AICoachScreenProps) {
  const t = (key: any) => getTranslation(key, language);
  
  const [messages, setMessages] = useState<Message[]>([
    {
      id: 1,
      type: 'ai',
      content: t('aiGreeting'),
      time: '10:00',
    },
  ]);
  const [inputText, setInputText] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages, isTyping]);

  const quickQuestions = [t('q1'), t('q2'), t('q3')];

  const getAIResponse = (userMessage: string): string => {
    const lowerMessage = userMessage.toLowerCase();
    
    // 질문에 해당하는 답변 반환
    if (lowerMessage.includes(t('q1').toLowerCase()) || 
        lowerMessage.includes('calorie') || 
        lowerMessage.includes('卡��리') ||
        lowerMessage.includes('칼로리')) {
      return t('a1');
    }
    
    if (lowerMessage.includes(t('q2').toLowerCase()) || 
        lowerMessage.includes('protein') || 
        lowerMessage.includes('蛋白质') ||
        lowerMessage.includes('단백질')) {
      return t('a2');
    }
    
    if (lowerMessage.includes(t('q3').toLowerCase()) || 
        lowerMessage.includes('diet') || 
        lowerMessage.includes('减肥') ||
        lowerMessage.includes('다이어트')) {
      return t('a3');
    }
    
    return t('aiHelper');
  };

  const handleSend = () => {
    if (!inputText.trim()) return;

    const now = new Date();
    const timeString = `${now.getHours()}:${now.getMinutes().toString().padStart(2, '0')}`;

    // 사용자 메시지 추가
    const userMessage: Message = {
      id: Date.now(),
      type: 'user',
      content: inputText,
      time: timeString,
    };

    setMessages([...messages, userMessage]);
    setInputText('');
    setIsTyping(true);

    // AI 응답 시뮬레이션 (1-2초 후)
    setTimeout(() => {
      const aiMessage: Message = {
        id: Date.now() + 1,
        type: 'ai',
        content: getAIResponse(inputText),
        time: timeString,
      };
      setMessages(prev => [...prev, aiMessage]);
      setIsTyping(false);
    }, 1500);
  };

  const handleQuickQuestion = (question: string) => {
    setInputText(question);
  };

  return (
    <div className="w-full max-w-md h-screen bg-gradient-to-b from-purple-50 to-blue-50 flex flex-col">
      {/* 헤더 */}
      <div className="bg-gradient-to-r from-purple-500 to-blue-600 text-white p-4">
        <div className="flex items-center gap-3">
          <button onClick={onBack} className="p-1 hover:bg-white/20 rounded-lg transition-colors">
            <ArrowLeft className="w-6 h-6" />
          </button>
          <div className="flex items-center gap-2">
            <div className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
              <Sparkles className="w-6 h-6" />
            </div>
            <div>
              <h1 className="text-lg font-bold">{t('aiCoachTitle')}</h1>
              <p className="text-xs text-white/90">{t('aiHelper')}</p>
            </div>
          </div>
        </div>
      </div>

      {/* 메시지 목록 */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((message) => (
          <div
            key={message.id}
            className={`flex ${message.type === 'user' ? 'justify-end' : 'justify-start'}`}
          >
            <div
              className={`max-w-[80%] rounded-2xl p-4 ${
                message.type === 'user'
                  ? 'bg-gradient-to-r from-green-500 to-green-600 text-white'
                  : 'bg-white shadow-sm border border-gray-200 text-gray-800'
              }`}
            >
              {message.type === 'ai' && (
                <div className="flex items-center gap-2 mb-2">
                  <Sparkles className="w-4 h-4 text-purple-500" />
                  <span className="text-xs font-semibold text-purple-500">AI 코치</span>
                </div>
              )}
              <p className="whitespace-pre-line">{message.content}</p>
              <div className={`text-xs mt-2 ${message.type === 'user' ? 'text-white/70' : 'text-gray-400'}`}>
                {message.time}
              </div>
            </div>
          </div>
        ))}

        {isTyping && (
          <div className="flex justify-start">
            <div className="bg-white shadow-sm border border-gray-200 rounded-2xl p-4">
              <div className="flex items-center gap-2">
                <div className="flex gap-1">
                  <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
                  <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '150ms' }} />
                  <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '300ms' }} />
                </div>
                <span className="text-sm text-gray-500">AI 코치가 답변 중...</span>
              </div>
            </div>
          </div>
        )}

        <div ref={messagesEndRef} />
      </div>

      {/* 빠른 질문 */}
      {messages.length === 1 && (
        <div className="px-4 pb-3">
          <div className="text-xs text-gray-500 mb-2">💡 {t('quickQuestions')}</div>
          <div className="flex gap-2 overflow-x-auto pb-2">
            {quickQuestions.map((question, index) => (
              <button
                key={index}
                onClick={() => handleQuickQuestion(question)}
                className="whitespace-nowrap px-4 py-2 bg-white border border-gray-200 rounded-full text-sm text-gray-700 hover:border-purple-400 hover:bg-purple-50 transition-all"
              >
                {question}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* 입력 영역 */}
      <div className="p-4 bg-white border-t border-gray-200">
        <div className="flex items-center gap-2">
          <input
            type="text"
            value={inputText}
            onChange={(e) => setInputText(e.target.value)}
            onKeyPress={(e) => e.key === 'Enter' && handleSend()}
            placeholder={t('typeMessage')}
            className="flex-1 px-4 py-3 border border-gray-300 rounded-full focus:outline-none focus:border-purple-500 transition-colors"
          />
          <button
            onClick={handleSend}
            disabled={!inputText.trim()}
            className={`w-12 h-12 rounded-full flex items-center justify-center transition-all ${
              inputText.trim()
                ? 'bg-gradient-to-r from-purple-500 to-blue-600 text-white hover:shadow-lg'
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