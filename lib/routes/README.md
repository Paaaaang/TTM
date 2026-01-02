# Routes

앱의 라우팅(네비게이션)을 관리하는 디렉토리입니다.

## 용도
- 화면 전환 경로 정의
- 라우트 이름 관리
- 네비게이션 로직

## 예시
```dart
class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String profile = '/profile';
  
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      home: (context) => HomeScreen(),
      login: (context) => LoginScreen(),
      profile: (context) => ProfileScreen(),
    };
  }
}
```
