# Constants

앱 전역에서 사용되는 상수를 정의하는 디렉토리입니다.

## 용도
- API URL, 엔드포인트
- 색상 테마
- 문자열 상수
- 앱 설정값

## 예시
```dart
class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF4CAF50);
}

class ApiConstants {
  static const String baseUrl = 'https://api.example.com';
  static const String loginEndpoint = '/auth/login';
}
```
