/// 공통 입력 필드 위젯
import 'package:flutter/material.dart';

/// 텍스트 입력 필드
class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final Function(String)? onChanged;
  final TextAlign textAlign;

  const CustomTextField({
    Key? key,
    this.controller,
    required this.hintText,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.focusNode,
    this.onChanged,
    this.textAlign = TextAlign.start,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      focusNode: focusNode,
      onChanged: onChanged,
      textAlign: textAlign,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF66BB6A), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

/// 드롭다운 필드
class CustomDropdown extends StatelessWidget {
  final int? value;
  final String hint;
  final List<int> items;
  final Function(int?) onChanged;

  const CustomDropdown({
    Key? key,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey[600]),
          ),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          items: items.map((item) {
            return DropdownMenuItem<int>(
              value: item,
              child: Text(item.toString()),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// 라벨 텍스트
class FormLabel extends StatelessWidget {
  final String text;

  const FormLabel(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }
}

/// 중복 확인 버튼이 있는 입력 필드
class TextFieldWithDuplicateCheck extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final bool isChecked;
  final bool isAvailable;
  final bool hasInput;
  final VoidCallback onCheckPressed;
  final String? message;
  final FocusNode? focusNode;
  final Function(String)? onChanged;

  const TextFieldWithDuplicateCheck({
    Key? key,
    this.controller,
    required this.hintText,
    required this.isChecked,
    required this.isAvailable,
    required this.hasInput,
    required this.onCheckPressed,
    this.message,
    this.focusNode,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: controller,
                hintText: hintText,
                focusNode: focusNode,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              height: 48,
              child: ElevatedButton(
                onPressed: hasInput ? onCheckPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAvailable
                      ? const Color(0xFF66BB6A)
                      : (hasInput ? const Color(0xFF66BB6A) : Colors.grey[300]),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[500],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  isAvailable ? '확인완료' : '중복확인',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
        if (isChecked && message != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              message!,
              style: TextStyle(
                fontSize: 12,
                color: isAvailable ? const Color(0xFF66BB6A) : Colors.red,
              ),
            ),
          ),
      ],
    );
  }
}
