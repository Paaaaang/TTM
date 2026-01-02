# Utils

유틸리티 함수 및 헬퍼 클래스를 정의하는 디렉토리입니다.

## 용도
- 공통 유틸리티 함수
- 날짜/시간 포맷팅
- 데이터 변환 헬퍼
- 유효성 검사 함수

## 예시
```dart
class DateUtils {
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }
}

class Validators {
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
```
