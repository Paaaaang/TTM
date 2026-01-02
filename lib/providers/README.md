# Providers

상태 관리를 담당하는 디렉토리입니다.

## 용도
- Provider, Riverpod, Bloc 등 상태 관리 클래스
- 앱 전역 상태 관리
- 화면 간 데이터 공유

## 예시
```dart
class UserProvider extends ChangeNotifier {
  User? _currentUser;
  
  User? get currentUser => _currentUser;
  
  void setUser(User user) {
    _currentUser = user;
    notifyListeners();
  }
}
```
