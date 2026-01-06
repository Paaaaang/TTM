/// 인증 서비스
/// 
/// REST API와 연동된 실제 인증 서비스
/// - 회원가입, 로그인, 로그아웃 기능 제공
/// - JWT 토큰 기반 인증
/// - SharedPreferences를 통한 로컬 사용자 정보 저장
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ttm/constants/api_config.dart';
import 'package:ttm/models/user.dart';

class AuthService {
  static const String _keyUser = 'user';
  static const String _keyToken = 'token';

  /// 회원가입
  /// POST /api/auth/signup
  Future<User?> signup({
    required String loginId,
    required String nickname,
    required String email,
    required String password,
    required String name,
    String? phone,
    String? birthdate,
    String? gender,
    String region = '서울',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getUrl(ApiConfig.signupEndpoint)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'login_id': loginId,
          'nickname': nickname,
          'email': email,
          'password': password,
          'member_name': name,
          'region': region,
          if (phone != null) 'phone_number': phone,
          if (birthdate != null) 'birth_date': birthdate,
          if (gender != null) 'gender': gender,
        }),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = User.fromJson(data['user']);
        return user;
      } else if (response.statusCode == 409) {
        // 이미 존재하는 아이디/닉네임/이메일
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        print('회원가입 409 에러: ${errorData['detail']}');
        return null;
      } else {
        print('회원가입 실패: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('회원가입 오류: $e');
      return null;
    }
  }

  /// 아이디 중복 확인
  /// GET /api/auth/check-login-id/{login_id}
  Future<bool> checkLoginIdDuplicate(String loginId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getUrl('/api/auth/check-login-id/$loginId')),
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return !(data['available'] as bool); // available이 false면 중복
      }
      return false;
    } catch (e) {
      print('아이디 중복 확인 오류: $e');
      return false;
    }
  }

  /// 닉네임 중복 확인
  /// GET /api/auth/check-nickname/{nickname}
  Future<bool> checkNicknameDuplicate(String nickname) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getUrl('/api/auth/check-nickname/$nickname')),
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return !(data['available'] as bool); // available이 false면 중복
      }
      return false;
    } catch (e) {
      print('닉네임 중복 확인 오류: $e');
      return false;
    }
  }

  /// 이메일 중복 확인
  /// GET /api/auth/check-email/{email}
  Future<bool> checkEmailDuplicate(String email) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getUrl('/api/auth/check-email/$email')),
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return !(data['available'] as bool); // available이 false면 중복
      }
      return false;
    } catch (e) {
      print('이메일 중복 확인 오류: $e');
      return false;
    }
  }

  /// 로그인
  /// POST /api/auth/login
  Future<User?> login(String loginId, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getUrl(ApiConfig.loginEndpoint)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'login_id': loginId,
          'password': password,
        }),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = User.fromJson(data['user']);
        final token = data['token'] as String;

        // 로컬에 저장
        await _saveUser(user);
        await _saveToken(token);

        return user;
      } else {
        print('로그인 실패: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('로그인 오류: $e');
      return null;
    }
  }

  /// 소셜 로그인 (카카오)
  /// TODO: 실제 카카오 OAuth 연동
  Future<User?> loginWithKakao() async {
    // TODO: 카카오 로그인 SDK 연동
    // 임시로 더미 사용자 반환
    await Future.delayed(const Duration(milliseconds: 500));
    
    final user = User(
      memberId: 100,
      loginId: 'kakao_user',
      nickname: '카카오사용자',
      email: 'kakao@example.com',
      memberName: '카카오 사용자',
      phoneNumber: '',
      birthDate: '1990-01-01',
    );

    await _saveUser(user);
    await _saveToken('kakao_token_dummy');
    
    return user;
  }

  /// 소셜 로그인 (네이버)
  /// TODO: 실제 네이버 OAuth 연동
  Future<User?> loginWithNaver() async {
    // TODO: 네이버 로그인 SDK 연동
    await Future.delayed(const Duration(milliseconds: 500));
    
    final user = User(
      memberId: 200,
      loginId: 'naver_user',
      nickname: '네이버사용자',
      email: 'naver@example.com',
      memberName: '네이버 사용자',
      phoneNumber: '',
      birthDate: '1990-01-01',
    );

    await _saveUser(user);
    await _saveToken('naver_token_dummy');
    
    return user;
  }

  /// 소셜 로그인 (구글)
  /// TODO: 실제 구글 OAuth 연동
  Future<User?> loginWithGoogle() async {
    // TODO: 구글 로그인 SDK 연동
    await Future.delayed(const Duration(milliseconds: 500));
    
    final user = User(
      memberId: 300,
      loginId: 'google_user',
      nickname: '구글사용자',
      email: 'google@example.com',
      memberName: '구글 사용자',
      phoneNumber: '',
      birthDate: '1990-01-01',
    );

    await _saveUser(user);
    await _saveToken('google_token_dummy');
    
    return user;
  }

  /// 로그아웃
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.remove(_keyToken);
  }

  /// 현재 로그인된 사용자 가져오기
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_keyUser);
      
      if (userJson == null) {
        return null;
      }

      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      return User.fromJson(userData);
    } catch (e) {
      print('사용자 정보 로드 오류: $e');
      return null;
    }
  }

  /// 로그인 상태 확인
  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  /// 사용자 정보 저장
  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson());
    await prefs.setString(_keyUser, userJson);
  }

  /// 토큰 저장
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  /// 토큰 가져오기
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }
}
