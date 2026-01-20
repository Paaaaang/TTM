// Flutter Material 패키지 임포트
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// 앱 색상 상수 임포트
import 'package:ttm/constants/app_colors.dart';
// 온보딩 화면 임포트
import 'package:ttm/screens/onboarding_screen.dart';
// 로그인 화면 임포트
import 'package:ttm/screens/login_screen.dart';
// 메인 화면 임포트
import 'package:ttm/screens/main_screen.dart';
import 'package:ttm/screens/settings/language_settings_screen.dart';
import 'package:ttm/screens/settings/delete_account_screen.dart';
import 'package:ttm/screens/settings/profile_edit_screen.dart';
import 'package:ttm/providers/language_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
// 운동 추가 화면 임포트
import 'package:ttm/screens/exercise_add_screen.dart';
// 식단 추가 화면 임포트
import 'package:ttm/screens/meal_add_screen.dart';
// 커뮤니티 홈 화면 임포트
import 'package:ttm/screens/community_home_screen.dart';
// 게시글 상세 화면 임포트
import 'package:ttm/screens/post_detail_screen.dart';
// 게시글 작성 화면 임포트
import 'package:ttm/screens/create_post_screen.dart';
// 회원가입 화면 임포트
import 'package:ttm/screens/signup_screen.dart';
// 설정 화면 임포트
import 'package:ttm/screens/settings_screen.dart';
// 도움말 화면 임포트
import 'package:ttm/screens/help_screen.dart';
// 친구 목록 화면 임포트
import 'package:ttm/screens/friends_list_screen.dart';
// 친구 추가 화면 임포트
import 'package:ttm/screens/add_friend_screen.dart';
// 피드백 화면 임포트
import 'package:ttm/screens/settings/feedback_screen.dart';
// 내 활동 상세 화면 임포트
import 'package:ttm/screens/activity_detail_screen.dart';
// 사진 촬영 식단 추가 화면 임포트
import 'package:ttm/screens/meal/camera_meal_screen.dart';
// 인증 서비스 임포트
import 'package:ttm/services/auth_service.dart';
// Google Fonts 임포트
import 'package:google_fonts/google_fonts.dart';
// Firebase 임포트
import 'package:firebase_core/firebase_core.dart';
// 알림 서비스 임포트
import 'package:ttm/services/notification_service.dart';
// 권한 서비스 임포트
import 'package:ttm/services/permission_service.dart';
// 플랫폼 확인
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'dart:async';
import 'dart:io' show Platform;

/// 앱의 진입점 (Entry Point)
/// Flutter 앱이 시작될 때 가장 먼저 실행되는 함수
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 날짜 형식 초기화
  await initializeDateFormatting('ko_KR', null);
  
  // 모바일 플랫폼에서만 Firebase 및 권한 초기화
  if (!kIsWeb) {
    try {
      // Firebase 초기화 (모바일만)
      await Firebase.initializeApp();
      
      // 알림 서비스 초기화 (모바일만)
      await NotificationService().initialize();
      
      // 앱 시작 시 필수 권한 요청 (모바일만)
      await PermissionService.requestAllPermissions();
    } catch (e) {
      print('⚠️ Firebase/권한 초기화 실패: $e');
    }
  }
  
  runZonedGuarded(
    () => runApp(const MyApp()),
    (error, stack) {
      if (!kReleaseMode) {
        // 디버그 모드에서만 로그
        // ignore: avoid_print
        print('Unhandled error: $error');
      }
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, message) {
        if (!kReleaseMode) {
          parent.print(zone, message);
        }
      },
    ),
  );
}

/// 앱의 루트 위젯
/// MaterialApp을 반환하여 앱의 전체 테마와 라우팅을 설정
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// 위젯 빌드 메서드
  /// MaterialApp을 구성하고 앱의 전체 설정을 반환
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageProvider(),
      builder: (context, child) {
        return MaterialApp(
          // 앱 제목
          title: 'TTM',
          // 디버그 배너 숨김
          debugShowCheckedModeBanner: false,
          // 한국어 localization 설정
          locale: const Locale('ko', 'KR'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ko', 'KR'),
            Locale('en', 'US'),
          ],
          // iOS 스와이프 뒤로가기 제스처 활성화
          theme: ThemeData(
            // 기본 폰트를 Pretendard로 설정
            fontFamily: 'Pretendard',
            // 폰트 fallback 설정 - 특수 문자 표시를 위해
            fontFamilyFallback: const ['Noto Sans KR'],
            // 기본 색상
            primaryColor: AppColors.primary,
            // 스캐폴드 배경 색상
            scaffoldBackgroundColor: AppColors.background,
            // 색상 스키마 설정
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              secondary: AppColors.secondary,
            ),
            // Material 3 디자인 사용
            useMaterial3: true,
            // iOS 스타일 페이지 전환 활성화
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              },
            ),
            // AppBar 테마
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
        ),
        // 하단 네비게이션 바 테마
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        // 카드 테마
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        // ElevatedButton 테마
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      // 초기 라우트 설정
      initialRoute: '/',
      // 정적 라우트 정의
      routes: {
        '/': (context) => const AuthWrapper(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/main': (context) => const MainScreen(),
        '/exercise/add': (context) => const ExerciseAddScreen(),
        '/community': (context) => const CommunityHomeScreen(),
        '/community/create': (context) => const CreatePostScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/help': (context) => const HelpScreen(),
        '/settings/language': (context) => const LanguageSettingsScreen(),
        '/friends': (context) => const FriendsListScreen(),
        '/friends/add': (context) => const AddFriendScreen(),
        '/settings/delete-account': (context) => const DeleteAccountScreen(),
        '/settings/profile-edit': (context) => const ProfileEditScreen(),
        '/settings/feedback': (context) => const FeedbackScreen(),
        '/activity': (context) => const ActivityDetailScreen(),
      },
      /// 동적 라우트 생성 핸들러
      /// 정적 라우트에서 찾지 못한 경로를 처리
      onGenerateRoute: (settings) {
        // 식단 추가 화면 (arguments로 날짜와 식사 유형 전달)
        if (settings.name == '/meal/add') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => MealAddScreen(
              selectedDate: args?['selectedDate'] as DateTime?,
              mealType: args?['mealType'] as String?,
            ),
          );
        }
        
        // 사진 촬영 식단 추가 화면 (arguments로 날짜와 식사 유형 전달)
        if (settings.name == '/meal/camera') {
          return MaterialPageRoute(
            builder: (context) => const CameraMealScreen(),
            settings: settings, // arguments 전달
          );
        }
        
        // 게시글 상세 화면 (동적 라우트)
        if (settings.name == '/community/post') {
          final postId = settings.arguments as int?;
          if (postId != null) {
            return MaterialPageRoute(
              builder: (context) => PostDetailScreen(postId: postId),
            );
          }
        }
        
        // 그 외의 경로는 null 반환
        return null;
      },
    );
      },
    );
  }
}

/// 인증 상태에 따라 초기 화면을 결정하는 Wrapper
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService().isLoggedIn(),
      builder: (context, snapshot) {
        // 로딩 중
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 로그인 상태 확인
        final isLoggedIn = snapshot.data ?? false;

        // 로그인 되어 있으면 메인 화면, 아니면 온보딩 화면
        if (isLoggedIn) {
          return const MainScreen();
        } else {
          return const OnboardingScreen();
        }
      },
    );
  }
}