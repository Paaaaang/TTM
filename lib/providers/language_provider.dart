import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LanguageProvider with ChangeNotifier {
  static final LanguageProvider _instance = LanguageProvider._internal();
  factory LanguageProvider() => _instance;
  LanguageProvider._internal();

  Locale _locale = const Locale('ko', 'KR');

  Locale get locale => _locale;
  bool get isKorean => _locale.languageCode == 'ko';

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  // 간단한 번역 맵 (실제 앱에서는 arb 파일 등 사용 권장)
  final Map<String, Map<String, String>> _localizedValues = {
    'ko': {
      'app_title': 'TTM',
      'home': '홈',
      'activity': '내 활동',
      'community': '커뮤니티',
      'ai_coach': 'AI 코치',
      'profile': '내 정보',
      'settings': '설정',
      'language_settings': '언어 설정',
      'delete_account': '회원 탈퇴',
      'confirm_delete': '정말로 탈퇴하시겠습니까?',
      'delete_warning': '탈퇴 시 모든 데이터가 영구적으로 삭제됩니다.',
      'cancel': '취소',
      'delete': '탈퇴',
      'quick_q_1': '오늘 칼로리는 얼마나 섭취했나요?',
      'quick_q_2': '단백질 섭취량을 늘리려면?',
      'quick_q_3': '다이어트에 좋은 운동은?',
      'ai_welcome': '안녕하세요! AI 코치입니다.\n식단과 운동에 대해 무엇이든 물어보세요! 😊',
      'logout': '로그아웃',
      'feedback': '피드백 보내기',
      'help': '도움말',
      'friends': '친구 목록',
      'edit_profile': '내 정보 수정',
    },
    'en': {
      'app_title': 'TTM',
      'home': 'Home',
      'activity': 'My Activity',
      'community': 'Community',
      'ai_coach': 'AI Coach',
      'profile': 'Profile',
      'settings': 'Settings',
      'language_settings': 'Language',
      'delete_account': 'Delete Account',
      'confirm_delete': 'Are you sure?',
      'delete_warning': 'This will permanently delete all your data.',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'quick_q_1': 'How many calories did I eat today?',
      'quick_q_2': 'How to increase protein intake?',
      'quick_q_3': 'Best exercises for diet?',
      'ai_welcome': 'Hello! I am your AI Coach.\nAsk me anything about diet and workout! 😊',
      'logout': 'Logout',
      'feedback': 'Feedback',
      'help': 'Help',
      'friends': 'Friends',
      'edit_profile': 'Edit Profile',
    }
  };

  String getText(String key) {
    return _localizedValues[_locale.languageCode]?[key] ?? key;
  }
}
