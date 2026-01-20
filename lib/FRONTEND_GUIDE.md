# TTM Flutter Frontend 완벽 가이드

> Flutter 3.x 기반 크로스 플랫폼 헬스케어 앱 개발 통합 문서

**작성일**: 2026-01-14  
**버전**: 1.0.0

---

## 📋 목차

1. [프로젝트 구조](#1-프로젝트-구조)
2. [환경 설정](#2-환경-설정)
3. [아키텍처](#3-아키텍처)
4. [주요 기능](#4-주요-기능)
5. [폴더별 상세 가이드](#5-폴더별-상세-가이드)
6. [개발 가이드](#6-개발-가이드)
7. [최적화 전략](#7-최적화-전략)
8. [트러블슈팅](#8-트러블슈팅)

---

## 1. 프로젝트 구조

```
lib/
├── constants/          # 앱 전역 상수
│   ├── api_constants.dart      # API URL, 타임아웃
│   ├── app_colors.dart         # 색상 테마
│   ├── app_strings.dart        # 문자열 상수
│   └── README.md
│
├── models/             # 데이터 모델 (9개)
│   ├── user.dart               # User, LoginResponse
│   ├── post.dart               # Post, PostListItem, PostImage
│   ├── comment.dart            # Comment, CommentResponse
│   ├── badge.dart              # Badge, MemberBadge, BadgeStats
│   ├── meal_log.dart           # MealLog, MealLogResponse
│   ├── meal_item.dart          # MealItem
│   ├── exercise_log.dart       # ExerciseLog, ExerciseLogResponse
│   ├── health_info.dart        # Disease, Allergy, HealthInfo
│   └── README.md
│
├── providers/          # 상태 관리 (Provider)
│   ├── user_provider.dart      # 사용자 상태
│   ├── post_provider.dart      # 커뮤니티 상태
│   ├── meal_provider.dart      # 식단 상태
│   └── README.md
│
├── services/           # API 통신 서비스 (11개)
│   ├── auth_service.dart       # 인증 (회원가입, 로그인)
│   ├── profile_service.dart    # 프로필 관리
│   ├── post_service.dart       # 커뮤니티 (1시간 캐싱)
│   ├── badge_service.dart      # 배지 시스템
│   ├── meal_service.dart       # 식단 관리
│   ├── exercise_service.dart   # 운동 관리
│   ├── weight_service.dart     # 체중 관리
│   ├── health_service.dart     # 건강 정보
│   ├── ai_service.dart         # AI 챗봇
│   ├── notification_service.dart  # FCM 푸시 알림
│   ├── permission_service.dart    # 권한 관리
│   └── README.md
│
├── screens/            # 화면 UI
│   ├── splash_screen.dart
│   ├── onboarding_screen.dart
│   ├── login_screen.dart
│   ├── main_screen.dart        # 하단 네비게이션
│   ├── home_screen.dart
│   ├── community_home_screen.dart
│   ├── post_detail_screen.dart
│   ├── profile_screen.dart
│   └── settings/
│       └── profile_edit_screen.dart
│
├── widgets/            # 재사용 위젯
│   ├── custom_button.dart
│   ├── custom_text_field.dart
│   ├── post_card.dart
│   └── README.md
│
├── utils/              # 유틸리티
│   ├── token_manager.dart      # JWT 토큰 관리
│   ├── date_formatter.dart     # 날짜 포맷팅
│   └── validators.dart         # 입력 검증
│
├── routes/             # 라우팅 설정
│   └── app_router.dart
│
└── main.dart           # 앱 진입점

```

---

## 2. 환경 설정

### 2.1 필수 요구사항

- **Flutter SDK**: 3.0 이상
- **Dart**: 3.0 이상
- **Android Studio** 또는 **VS Code**

### 2.2 설치

```bash
# 의존성 설치
flutter pub get

# 코드 생성 (필요 시)
flutter pub run build_runner build
```

### 2.3 주요 패키지

```yaml
dependencies:
  # 상태 관리
  provider: ^6.1.2
  
  # 네트워킹
  http: ^1.2.2
  
  # 로컬 저장소
  shared_preferences: ^2.3.3
  flutter_secure_storage: ^9.2.2
  
  # 이미지
  image_picker: ^1.1.2
  
  # 날짜/시간
  intl: ^0.19.0
  
  # 소셜 로그인
  google_sign_in: ^6.2.2
  kakao_flutter_sdk: ^1.9.6
  
  # 기타
  url_launcher: ^6.3.1
```

### 2.4 실행

```bash
# 개발 모드 실행
flutter run

# 특정 디바이스에서 실행
flutter run -d chrome    # 웹
flutter run -d emulator  # 에뮬레이터
flutter run -d <device_id>  # 실제 기기

# 빌드
flutter build apk        # Android APK
flutter build appbundle  # Android App Bundle
flutter build ios        # iOS
```

---

## 3. 아키텍처

### 3.1 전체 구조

```
┌─────────────────────────────────────┐
│          Presentation Layer         │
│  (Screens + Widgets + Providers)    │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│         Business Logic Layer        │
│            (Services)               │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│            Data Layer               │
│   (Models + API + Local Storage)    │
└─────────────────────────────────────┘
```

### 3.2 데이터 흐름

```
User Input → Provider → Service → API → Backend
                ↓                         ↓
            notifyListeners()          Database
                ↓
            UI Update
```

---

## 4. 주요 기능

### 4.1 인증 & 회원가입

**파일**: [auth_service.dart](lib/services/auth_service.dart), [login_screen.dart](lib/screens/login_screen.dart)

```dart
// 로그인
final result = await AuthService().login(loginId, password);
if (result['success']) {
  final token = result['token'];
  await TokenManager.saveToken(token);
}

// 회원가입
await AuthService().signup({
  'loginId': 'testuser',
  'password': 'Test1234!',
  'email': 'test@example.com',
  // ...
});
```

### 4.2 커뮤니티 (좋아요 시스템)

**파일**: [post_service.dart](lib/services/post_service.dart), [community_home_screen.dart](lib/screens/community_home_screen.dart)

**낙관적 업데이트 패턴**:
```dart
Future<void> _toggleLike(PostListItem post) async {
  // 1. UI 즉시 업데이트
  setState(() {
    post.isLiked = !post.isLiked;
    post.likeCount += post.isLiked ? 1 : -1;
  });
  
  try {
    // 2. API 호출
    if (post.isLiked) {
      await PostService().likePost(post.postId, currentMemberId);
    } else {
      await PostService().unlikePost(post.postId, currentMemberId);
    }
  } catch (e) {
    // 3. 에러 시 롤백
    setState(() {
      post.isLiked = !post.isLiked;
      post.likeCount += post.isLiked ? 1 : -1;
    });
  }
}
```

### 4.3 식단 관리 (AI 분석)

**파일**: [meal_service.dart](lib/services/meal_service.dart)

```dart
// AI 이미지 분석
final result = await MealService().analyzeMealImage(
  imageFile: imageFile,
  mealType: 'LUNCH',
  mealDate: DateTime.now(),
);

// 응답: { foods: [...], totalCalories: 500 }
```

### 4.4 배지 시스템

**파일**: [badge_service.dart](lib/services/badge_service.dart), [profile_screen.dart](lib/screens/profile_screen.dart)

```dart
// 배지 목록 조회
final badges = await BadgeService().getAllBadges();

// 회원 배지 조회
final memberBadges = await BadgeService().getMemberBadges(memberId);

// 배지 통계
final stats = await BadgeService().getBadgeStats(memberId);
// { totalBadges: 20, earnedBadges: 8 }
```

---

## 5. 폴더별 상세 가이드

### 5.1 constants/ - 앱 전역 상수

**api_constants.dart**:
```dart
class ApiConstants {
  static const String baseUrl = 'http://localhost:3000';
  static const Duration timeout = Duration(seconds: 10);
  
  // 엔드포인트
  static const String login = '/api/auth/login';
  static const String signup = '/api/auth/signup';
  static const String posts = '/api/posts';
}
```

**app_colors.dart**:
```dart
class AppColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF4CAF50);
  static const Color accent = Color(0xFFFF6B6B);
  static const Color background = Color(0xFFF5F5F5);
}
```

### 5.2 models/ - 데이터 모델

**목적**: API 응답 데이터를 Dart 객체로 변환

**user.dart**:
```dart
class User {
  final int memberId;
  final String loginId;
  final String nickname;
  final String email;
  
  User.fromJson(Map<String, dynamic> json)
    : memberId = json['memberId'],
      loginId = json['loginId'],
      nickname = json['nickname'],
      email = json['email'];
}
```

**post.dart**:
```dart
class PostListItem {
  final int postId;
  final String title;
  final String authorNickname;
  int likeCount;
  bool isLiked;  // 좋아요 상태
  
  PostListItem.fromJson(Map<String, dynamic> json)
    : postId = json['postId'],
      title = json['title'],
      likeCount = json['likeCount'],
      isLiked = json['isLiked'] ?? false;
}
```

### 5.3 services/ - API 통신

**공통 특징**:
- 1시간 TTL 캐싱 (SharedPreferences)
- JWT Bearer 토큰 인증
- snake_case ↔ camelCase 자동 변환

**post_service.dart 예시**:
```dart
class PostService {
  static const _cacheKey = 'posts_cache';
  static const _cacheTTL = Duration(hours: 1);
  
  Future<List<PostListItem>> getPosts({int page = 1}) async {
    // 1. 캐시 확인
    final cached = await _getCachedData();
    if (cached != null) return cached;
    
    // 2. API 호출
    final token = await TokenManager.getToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/posts/list?page=$page'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(ApiConstants.timeout);
    
    // 3. 응답 처리
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final posts = (data as List)
          .map((item) => PostListItem.fromJson(item))
          .toList();
      
      // 4. 캐싱
      await _cacheData(posts);
      return posts;
    }
    
    throw Exception('Failed to load posts');
  }
}
```

### 5.4 providers/ - 상태 관리

**user_provider.dart**:
```dart
class UserProvider extends ChangeNotifier {
  User? _currentUser;
  
  User? get currentUser => _currentUser;
  
  void setUser(User user) {
    _currentUser = user;
    notifyListeners();
  }
  
  void logout() {
    _currentUser = null;
    TokenManager.deleteToken();
    notifyListeners();
  }
}
```

**사용법**:
```dart
// main.dart에서 등록
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => UserProvider()),
  ],
  child: MyApp(),
)

// 화면에서 사용
final userProvider = Provider.of<UserProvider>(context);
final user = userProvider.currentUser;
```

### 5.5 widgets/ - 재사용 위젯

**custom_button.dart**:
```dart
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  
  const CustomButton({
    required this.text,
    this.onPressed,
    this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppColors.primary,
        minimumSize: Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(text, style: TextStyle(fontSize: 16)),
    );
  }
}
```

### 5.6 utils/ - 유틸리티

**token_manager.dart**:
```dart
class TokenManager {
  static const _tokenKey = 'auth_token';
  
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
  
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  static Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
```

---

## 6. 개발 가이드

### 6.1 새로운 화면 추가

1. `lib/screens/` 에 파일 생성
2. StatefulWidget 또는 StatelessWidget 작성
3. `lib/routes/app_router.dart` 에 라우트 추가
4. 필요시 Provider 연결

### 6.2 새로운 API 추가

1. `lib/models/` 에 모델 클래스 추가
2. `lib/services/` 에 서비스 메서드 추가
3. 캐싱이 필요하면 SharedPreferences 활용
4. 화면에서 서비스 호출

### 6.3 코드 스타일

```dart
// ✅ Good
class MyWidget extends StatelessWidget {
  final String title;
  
  const MyWidget({required this.title});
  
  @override
  Widget build(BuildContext context) {
    return Text(title);
  }
}

// ❌ Bad
class mywidget extends StatelessWidget {
  String title;
  
  mywidget(this.title);
  
  Widget build(context) {
    return Text(title);
  }
}
```

---

## 7. 최적화 전략

### 7.1 성능 최적화

**ListView.builder 사용**:
```dart
// ✅ Good - 화면에 보이는 항목만 렌더링
ListView.builder(
  itemCount: posts.length,
  itemBuilder: (context, index) {
    return PostCard(post: posts[index]);
  },
)

// ❌ Bad - 모든 항목을 한 번에 렌더링
ListView(
  children: posts.map((post) => PostCard(post: post)).toList(),
)
```

**const 생성자 활용**:
```dart
// ✅ Good - 빌드 시 한 번만 생성
const Text('Hello', style: TextStyle(fontSize: 16))

// ❌ Bad - 빌드 시마다 재생성
Text('Hello', style: TextStyle(fontSize: 16))
```

### 7.2 캐싱 전략

- **TTL**: 1시간 (3600초)
- **저장소**: SharedPreferences
- **무효화**: 데이터 변경 시 자동

### 7.3 이미지 최적화

```yaml
# pubspec.yaml에 추가 권장
dependencies:
  cached_network_image: ^3.3.1
```

```dart
CachedNetworkImage(
  imageUrl: imageUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

---

## 8. 트러블슈팅

### 8.1 토큰 만료

**증상**: 401 Unauthorized  
**해결**: 
```dart
if (response.statusCode == 401) {
  await TokenManager.deleteToken();
  Navigator.pushReplacementNamed(context, '/login');
}
```

### 8.2 네트워크 타임아웃

**증상**: TimeoutException  
**해결**:
```dart
try {
  final response = await http.get(url).timeout(Duration(seconds: 10));
} on TimeoutException {
  showDialog(context: context, builder: (_) => 
    AlertDialog(title: Text('네트워크 연결을 확인해주세요'))
  );
}
```

### 8.3 JSON 파싱 오류

**증상**: type 'Null' is not a subtype of type 'String'  
**해결**:
```dart
// Null-safety 고려
final nickname = json['nickname'] as String?;
final likeCount = json['likeCount'] ?? 0;
```

---

## 📞 문의 및 지원

- **이슈 트래킹**: GitHub Issues
- **문서 업데이트**: 이 파일 직접 수정 후 커밋

**마지막 업데이트**: 2026-01-14
