# Screens

앱의 각 화면(페이지)을 정의하는 디렉토리입니다.

## 용도
- 전체 화면 단위의 UI 페이지
- 각 화면의 레이아웃 및 로직

## 예시
```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(child: Text('Home Screen')),
    );
  }
}
```
