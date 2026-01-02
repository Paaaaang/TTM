# Models

데이터 모델 클래스를 정의하는 디렉토리입니다.

## 용도
- 데이터베이스 테이블에 매핑되는 모델 클래스
- API 응답 데이터 모델
- 앱 내에서 사용되는 데이터 구조

## 예시
```dart
class User {
  final String id;
  final String name;
  final String email;
  
  User({required this.id, required this.name, required this.email});
}
```
