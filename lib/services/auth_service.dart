/// 인증 서비스
/// TODO: 실제 API 연동 시 이 파일만 수정하면 됨
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ttm/models/user.dart';

class AuthService {
  static const String _keyUser = 'user';
  static const String _keyToken = 'token';

  /// 더미 사용자 데이터
  /// TODO: 실제 API로 교체 필요
  static final List<Map<String, dynamic>> _dummyUsers = [
    {
      'id': '1',
      'username': 'test',
      'password': '1234',
      'email': 'test@test.com',
      'name': '테스트 사용자',
    },
    {
      'id': '2',
      'username': 'admin',
      'password': 'admin',
      'email': 'admin@ttm.com',
      'name': '관리자',
    },
  ];

  /// 회원가입
  /// TODO: 실제 API 호출로 교체
  /// POST /api/auth/signup
  Future<User?> signup({
    required String username,
    required String password,
    required String email,
    required String name,
  }) async {
    try {
      // TODO: 실제 API 호출
      // final response = await http.post(
      //   Uri.parse('$baseUrl/api/auth/signup'),
      //   body: {'username': username, 'password': password, 'email': email, 'name': name},
      // );

      // 더미 데이터 중복 체크
      await Future.delayed(const Duration(milliseconds: 500)); // API 호출 시뮬레이션

      final existingUser = _dummyUsers.where((user) => user['username'] == username).toList();
      
      if (existingUser.isNotEmpty) {
        return null; // 이미 존재하는 아이디
      }

      // 새 사용자 추가
      final newUser = {
        'id': (_dummyUsers.length + 1).toString(),
        'username': username,
        'password': password,
        'email': email,
        'name': name,
      };
      
      _dummyUsers.add(newUser);

      // User 객체 생성 (회원가입 후 자동 로그인 안 함)
      final user = User(
        id: newUser['id'] as String,
        username: newUser['username'] as String,
        email: newUser['email'] as String,
        name: newUser['name'] as String?,
      );

      return user;
    } catch (e) {
      print('회원가입 오류: $e');
      return null;
    }
  }

  /// 로그인
  /// TODO: 실제 API 호출로 교체
  /// POST /api/auth/login
  Future<User?> login(String username, String password) async {
    try {
      // TODO: 실제 API 호출
      // final response = await http.post(
      //   Uri.parse('$baseUrl/api/auth/login'),
      //   body: {'username': username, 'password': password},
      // );

      // 더미 데이터 검증
      await Future.delayed(const Duration(milliseconds: 500)); // API 호출 시뮬레이션

      final userData = _dummyUsers.firstWhere(
        (user) => user['username'] == username && user['password'] == password,
        orElse: () => {},
      );

      if (userData.isEmpty) {
        return null; // 로그인 실패
      }

      // User 객체 생성
      final user = User(
        id: userData['id'] as String,
        username: userData['username'] as String,
        email: userData['email'] as String,
        name: userData['name'] as String?,
      );

      // 로컬에 저장
      await _saveUser(user);
      await _saveToken('dummy_token_${user.id}'); // 더미 토큰

      return user;
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
      id: '100',
      username: 'kakao_user',
      email: 'kakao@example.com',
      name: '카카오 사용자',
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
      id: '200',
      username: 'naver_user',
      email: 'naver@example.com',
      name: '네이버 사용자',
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
      id: '300',
      username: 'google_user',
      email: 'google@example.com',
      name: '구글 사용자',
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
