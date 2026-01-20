/// 비밀번호 강도 체크 위젯
import 'package:flutter/material.dart';

class PasswordStrengthWidget extends StatelessWidget {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigit;
  final bool hasSpecialChar;

  const PasswordStrengthWidget({
    Key? key,
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigit,
    required this.hasSpecialChar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool allValid = hasMinLength && hasUppercase && hasLowercase && hasDigit && hasSpecialChar;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            allValid ? Icons.check_circle : Icons.circle_outlined,
            size: 18,
            color: allValid ? const Color(0xFF66BB6A) : Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Text(
            allValid 
                ? '비밀번호 조건을 모두 충족했습니다'
                : '영문 대소문자, 숫자, 특수문자 포함 10자 이상',
            style: TextStyle(
              fontSize: 13,
              color: allValid ? const Color(0xFF66BB6A) : Colors.grey[600],
              fontWeight: allValid ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

}

/// 비밀번호 강도 검사 유틸리티
class PasswordStrengthChecker {
  /// 비밀번호 강도 검사
  static Map<String, bool> checkPassword(String password) {
    return {
      'hasMinLength': password.length >= 10,
      'hasUppercase': password.contains(RegExp(r'[A-Z]')),
      'hasLowercase': password.contains(RegExp(r'[a-z]')),
      'hasDigit': password.contains(RegExp(r'[0-9]')),
      'hasSpecialChar': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    };
  }

  /// 모든 조건 충족 여부
  static bool isValid(String password) {
    final result = checkPassword(password);
    return result.values.every((isValid) => isValid);
  }
}
