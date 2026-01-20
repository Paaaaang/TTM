/// 앱 전체 라우트(경로) 상수 클래스
/// 화면 이동 시 일관된 경로 사용을 위해 정의
class AppRoutes {
  // 인증 관련 라우트
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  
  // 메인 화면
  static const String home = '/home'; // 홈 화면
  static const String main = '/main'; // 메인 화면 (네비게이션 바 포함)
  
  // 운동 관련 라우트
  static const String exercise = '/exercise';
  static const String exerciseAdd = '/exercise/add';
  
  // 식단 관련 라우트
  static const String diet = '/diet'; // 식단 목록 화면
  static const String dietAdd = '/diet/add'; // 식단 기록 추가 화면
  
  // 커뮤니티 관련 라우트
  static const String community = '/community';
  static const String communityPost = '/community/post';
  static const String communityCreate = '/community/create';
  
  // 통계 관련 라우트
  static const String statsWeekly = '/stats/weekly'; // 주간 통계
  static const String statsMonthly = '/stats/monthly'; // 월간 통계
  
  // 프로필 관련 라우트
  static const String profile = '/profile';
  static const String profileBadges = '/profile/badges';
  static const String activity = '/activity'; // 내 활동 상세
  static const String settings = '/settings';
  
  // AI Coach
  static const String aiCoach = '/ai-coach';
}
