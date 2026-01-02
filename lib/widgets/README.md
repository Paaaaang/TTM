# Widgets

재사용 가능한 커스텀 위젯을 정의하는 디렉토리입니다.

## 용도
- 여러 화면에서 공통으로 사용되는 UI 컴포넌트
- 커스텀 버튼, 카드, 리스트 아이템 등

## 예시
```dart
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  
  CustomButton({required this.text, required this.onPressed});
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }
}
```
