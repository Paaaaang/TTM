// Flutter Material 패키지 임포트
import 'package:flutter/material.dart';

/// 앱 전체에서 사용되는 색상 상수 클래스
/// 일관된 디자인을 위해 모든 화면에서 이 색상들을 사용
class AppColors {
  // 주요 색상
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF1DB954);
  static const Color accent = Color(0xFFFF6B6B);
  
  // 배경 색상
  static const Color background = Color(0xFFF5F5F5); // 앱 전체 배경
  static const Color cardBackground = Colors.white; // 카드 배경
  
  // 텍스트 색상
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);
  
  // 상태 색상
  static const Color success = Color(0xFF4CAF50); // 성공
  static const Color warning = Color(0xFFFF9800); // 경고
  static const Color error = Color(0xFFF44336); // 오류
  static const Color info = Color(0xFF2196F3); // 정보
  
  // 기타 색상
  static const Color divider = Color(0xFFEEEEEE); // 구분선
  static const Color shadow = Color(0x1A000000); // 그림자 (투명도 10%)
}
