# Services

비즈니스 로직 및 외부 서비스와의 통신을 담당하는 디렉토리입니다.

## 용도
- API 통신 서비스
- 데이터베이스 연동 서비스
- 인증/인가 서비스
- 로컬 저장소 서비스

## 예시
```dart
class ApiService {
  Future<List<User>> getUsers() async {
    // API 호출 로직
  }
}
```
