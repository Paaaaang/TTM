/// AI 코치 화면
/// AICoachScreen.tsx를 Flutter로 변환
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 메시지 타입
enum MessageType {
  user,
  ai,
}

/// 메시지 모델
class Message {
  final int id;
  final MessageType type;
  final String content;
  final DateTime time;

  Message({
    required this.id,
    required this.type,
    required this.content,
    required this.time,
  });
}

/// AI 코치 화면 위젯
class AICoachScreen extends StatefulWidget {
  const AICoachScreen({Key? key}) : super(key: key);

  @override
  State<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends State<AICoachScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  bool _isTyping = false;
  int _messageIdCounter = 0;

  // 빠른 질문 목록
  final List<String> _quickQuestions = [
    '오늘 칼로리는 얼마나 섭취했나요?',
    '단백질 섭취량을 늘리려면?',
    '다이어트에 좋은 운동은?',
  ];

  @override
  void initState() {
    super.initState();
    // AI 환영 메시지
    _addMessage(
      MessageType.ai,
      '안녕하세요! AI 코치입니다.\n식단과 운동에 대해 무엇이든 물어보세요! 😊',
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple[400]!,
              Colors.blue[400]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 헤더
              _buildHeader(),

              // 메시지 리스트
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      // 메시지 목록
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            return _buildMessageBubble(_messages[index]);
                          },
                        ),
                      ),

                      // 타이핑 인디케이터
                      if (_isTyping) _buildTypingIndicator(),

                      // 빠른 질문
                      if (_messages.length == 1) _buildQuickQuestions(),

                      // 입력 바
                      _buildInputBar(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 헤더
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'AI 코치',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '24시간 건강 상담',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48), // 중앙 정렬을 위한 공간
        ],
      ),
    );
  }

  /// 메시지 버블
  Widget _buildMessageBubble(Message message) {
    final isUser = message.type == MessageType.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // AI 아이콘
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[400]!, Colors.blue[400]!],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
          // 메시지 버블
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(
                            colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                          )
                        : null,
                    color: isUser ? null : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: isUser ? null : Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: isUser ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(message.time),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 32), // 오른쪽 여백
        ],
      ),
    );
  }

  /// 타이핑 인디케이터
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple[400]!, Colors.blue[400]!],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 18,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return Container(
                  margin: EdgeInsets.only(left: index > 0 ? 4 : 0),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// 빠른 질문
  Widget _buildQuickQuestions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '빠른 질문',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickQuestions.map((question) {
              return InkWell(
                onTap: () => _sendMessage(question),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    question,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 입력 바
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: '메시지를 입력하세요...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  _sendMessage(text);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple[400]!, Colors.blue[400]!],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () {
                final text = _messageController.text.trim();
                if (text.isNotEmpty) {
                  _sendMessage(text);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 메시지 추가
  void _addMessage(MessageType type, String content) {
    setState(() {
      _messages.add(Message(
        id: _messageIdCounter++,
        type: type,
        content: content,
        time: DateTime.now(),
      ));
    });

    // 스크롤을 맨 아래로
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 메시지 전송
  void _sendMessage(String text) {
    // 사용자 메시지 추가
    _addMessage(MessageType.user, text);
    _messageController.clear();

    // 타이핑 인디케이터 표시
    setState(() {
      _isTyping = true;
    });

    // 1.5초 후 AI 응답
    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() {
        _isTyping = false;
      });
      _addMessage(MessageType.ai, _getAIResponse(text));
    });
  }

  /// AI 응답 생성
  String _getAIResponse(String userMessage) {
    final message = userMessage.toLowerCase();

    if (message.contains('칼로리')) {
      return '칼로리 섭취는 개인의 활동량과 목표에 따라 다릅니다.\n'
          '일반적으로 성인 남성은 하루 2000-2500kcal, 성인 여성은 1800-2000kcal가 권장됩니다.\n'
          '체중 감량이 목표라면 500kcal 정도 줄이는 것이 좋습니다.';
    } else if (message.contains('단백질')) {
      return '단백질은 근육 형성과 유지에 중요합니다.\n'
          '체중 1kg당 1.2-2.0g의 단백질 섭취를 권장합니다.\n'
          '닭가슴살, 계란, 두부, 콩류, 생선 등이 좋은 단백질 공급원입니다.';
    } else if (message.contains('다이어트') || message.contains('운동')) {
      return '효과적인 다이어트를 위해서는 유산소 운동과 근력 운동을 병행하는 것이 좋습니다.\n'
          '주 3-5회, 30분 이상의 운동을 권장합니다.\n'
          '걷기, 조깅, 자전거, 수영 등이 좋은 유산소 운동입니다.';
    } else if (message.contains('아침') || message.contains('식사')) {
      return '규칙적인 식사는 건강한 다이어트의 기본입니다.\n'
          '아침 식사를 거르지 않는 것이 중요하며,\n'
          '하루 3끼를 균형있게 섭취하는 것을 권장합니다.';
    } else if (message.contains('물')) {
      return '하루 2리터(약 8잔)의 물을 마시는 것을 권장합니다.\n'
          '충분한 수분 섭취는 신진대사를 촉진하고\n'
          '체중 관리에도 도움이 됩니다.';
    } else {
      return '좋은 질문이네요!\n'
          '식단과 운동에 대해 더 구체적으로 질문해주시면\n'
          '더 자세한 답변을 드릴 수 있습니다. 😊';
    }
  }
}
