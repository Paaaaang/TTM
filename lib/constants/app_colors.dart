// Flutter Material 패키지 임포트
import 'package:flutter/material.dart';

/// 앱 전체에서 사용되는 색상 상수 클래스
/// 일관된 디자인을 위해 모든 화면에서 이 색상들을 사용
class AppColors {
  // ========== 브랜드 컬러 (Primary - 고정) ==========
  static const Color primary = Color(0xFF1DB954); // 브랜드 메인 그린
  static const Color primaryLight = Color(0xFFE8F5E9); // 연한 그린 배경
  static const Color primaryDark = Color(0xFF43A047); // 진한 그린

  // ========== Base Grey Friends ==========
  /// 제목, 주요 수치
  static const Color textPrimary = Color(0xFF3C4A3E);
  /// 설명 텍스트, 보조 정보
  static const Color textSecondary = Color(0xFFA0AFA1);
  /// 메인 배경 (권장)
  static const Color background = Color(0xFFFFFFFF);
  /// 카드 구분선 (opacity 20%)
  static const Color divider = Color(0x33A0AFA1);
  /// 연한 테두리
  static const Color borderLight = Color(0xFFE0E0E0);
  /// 회색 아이콘
  static const Color iconGrey = Color(0xFF9E9E9E);

  // ========== Identity Natural Palette ==========
  /// 섹션 배경, 그래프 보조
  static const Color natureMid = Color(0xFF739A77);
  /// 카드 배경, 결과 요약
  static const Color softBackground = Color(0xFFEEFDEF);
  /// 추천 식단, 팁 영역
  static const Color warmNeutral = Color(0xFFF6EDD9);

  // ========== Action Spot Palette ==========
  /// 분석 시작, 저장 (primary와 동일)
  static const Color ctaMain = Color(0xFF1DB954);
  /// 보조 버튼
  static const Color ctaSub = Color(0xFF497850);
  /// 완료 배경, 긍정 결과
  static const Color successBg = Color(0xFFD8F9DB);
  /// 선택 카드, 포커스
  static const Color focusAccent = Color(0xFF334574);

  // ========== 레거시 컬러 (하위 호환성) ==========
  static const Color secondary = Color(0xFF1DB954); // primary와 동일
  static const Color accent = Color(0xFF497850); // ctaSub와 동일
  static const Color cardBackground = Colors.white; // 카드 배경
  static const Color textHint = Color(0xFFA0AFA1); // textSecondary와 동일

  // ========== 상태 색상 (유지) ==========
  static const Color success = Color(0xFF4CAF50); // 성공
  static const Color warning = Color(0xFFFF9800); // 경고
  static const Color error = Color(0xFFF44336); // 오류
  static const Color info = Color(0xFF2196F3); // 정보

  // ========== 차트/영양소 색상 (기능적 색상 - 유지) ==========
  /// 탄수화물 차트 색상
  static const Color carbs = Color(0xFF2196F3); // 파란색
  /// 단백질 차트 색상  
  static const Color protein = Color(0xFFFF6B6B); // 오렌지/빨강
  /// 지방 차트 색상
  static const Color fat = Color(0xFFFFA726); // 앰버/오렌지

  // ========== 기타 색상 ==========
  static const Color shadow = Color(0x1A000000); // 그림자 (투명도 10%)
  static const Color overlayDark = Color(0x80000000); // 어두운 오버레이 (50%)
  static const Color overlayLight = Color(0x0D000000); // 밝은 오버레이 (5%)
  
  // ========== 소셜 로그인 브랜드 색상 (변경 금지) ==========
  static const Color kakao = Color(0xFFFEE500); // 카카오 노랑
  static const Color naver = Color(0xFF03C75A); // 네이버 초록
  static const Color google = Color(0xFF4285F4); // 구글 파랑
}

