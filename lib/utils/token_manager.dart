/// 토큰 관리 유틸리티
/// JWT 토큰 저장 및 조회를 담당
/// SharedPreferences를 래핑하여 토큰 관리를 단순화

import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const String _keyToken = 'token';

  /// JWT 토큰 저장
  static Future<bool> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_keyToken, token);
    } catch (e) {
      print('토큰 저장 오류: $e');
      return false;
    }
  }

  /// JWT 토큰 조회
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyToken);
    } catch (e) {
      print('토큰 조회 오류: $e');
      return null;
    }
  }

  /// JWT 토큰 삭제
  static Future<bool> removeToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_keyToken);
    } catch (e) {
      print('토큰 삭제 오류: $e');
      return false;
    }
  }

  /// 토큰 존재 여부 확인
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
