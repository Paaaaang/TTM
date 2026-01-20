import 'package:ttm/constants/api_constants.dart';

/// API 설정
class ApiConfig {
  /// 베이스 URL (ApiConstants와 일치)
  static String get baseUrl => ApiConstants.baseUrl;
  
  /// API 엔드포인트
  static const String loginEndpoint = '/api/auth/login';
  static const String signupEndpoint = '/api/auth/signup';
  static const String logoutEndpoint = '/api/auth/logout';
  static const String userEndpoint = '/api/user/profile';
  
  /// 타임아웃 설정
  static const Duration timeout = Duration(seconds: 30);
  
  /// 전체 URL 생성
  static String getUrl(String endpoint) => '$baseUrl$endpoint';
}
