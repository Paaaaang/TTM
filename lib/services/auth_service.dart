/// 인증 서비스
/// 
/// REST API와 연동된 실제 인증 서비스
/// - 회원가입, 로그인, 로그아웃 기능 제공
/// - JWT 토큰 기반 인증
/// - SharedPreferences를 통한 로컬 사용자 정보 저장
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
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
        print('로그인 응답 데이터: $data'); // 디버그
        print('사용자 데이터: ${data['user']}'); // 디버그
        final user = User.fromJson(data['user']);
        print('파싱된 사용자: createdAt=${user.createdAt}'); // 디버그
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

  /// 서버에서 최신 사용자 정보 가져와 동기화
  Future<User?> refreshCurrentUser() async {
    try {
      // 1. 로컬 정보 확인
      final localUser = await getCurrentUser();
      if (localUser == null) return null;

      // 2. 서버 요청
      final token = await getToken();
      final response = await http.get(
        Uri.parse(ApiConfig.getUrl('/api/members/${localUser.memberId}')),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.timeout);

      // 3. 응답 처리 및 저장
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final updatedUser = User.fromJson(data);
        await _saveUser(updatedUser);
        print('✅ 사용자 정보 동기화 완료: ${updatedUser.memberName}');
        return updatedUser;
      } else {
        print('⚠️ 사용자 정보 동기화 실패: ${response.statusCode}');
        return localUser;
      }
    } catch (e) {
      print('❌ 사용자 정보 동기화 오류: $e');
      return await getCurrentUser(); // 실패 시 로컬 정보 반환
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

  /// 사용자 정보 로컬 저장 (public 메서드)
  Future<void> saveUserLocally(User user) async {
    await _saveUser(user);
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

  /// 프로필 기본 정보(이름, 이메일) 수정
  Future<User?> updateProfile({
    required int memberId,
    String? name,
    String? email,
    String? profileImage,
  }) async {
    if ((name == null || name.trim().isEmpty) && 
        (email == null || email.trim().isEmpty) &&
        (profileImage == null || profileImage.trim().isEmpty)) {
      throw Exception('수정할 정보가 없습니다.');
    }

    final token = await getToken();
    final body = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) {
      body['member_name'] = name.trim();
    }
    if (email != null && email.trim().isNotEmpty) {
      body['email'] = email.trim();
    }
    if (profileImage != null && profileImage.trim().isNotEmpty) {
      body['profile_image'] = profileImage.trim();
    }

    print('📤 프로필 업데이트 요청:');
    print('  URL: ${ApiConfig.getUrl('/api/members/$memberId/profile')}');
    print('  Body: $body');

    try {
      final response = await http
          .put(
            Uri.parse(ApiConfig.getUrl('/api/members/$memberId/profile')),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);

      print('📥 프로필 업데이트 응답: ${response.statusCode}');
      print('📥 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('🔍 파싱된 데이터: $data');
        final updatedUser = User.fromJson(data);
        print('✅ User 객체 생성 성공: ${updatedUser.memberName}');
        await _saveUser(updatedUser);
        return updatedUser;
      }

      final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
      final message = errorBody['detail']?.toString() ?? '프로필 업데이트에 실패했습니다';
      print('❌ 프로필 업데이트 실패: $message');
      throw Exception(message);
    } catch (e) {
      print('❌ 프로필 업데이트 예외: $e');
      rethrow;
    }
  }

  /// 목표 칼로리 업데이트
  Future<bool> updateCalorieGoal(int memberId, int calorieGoal) async {
    try {
      final token = await getToken();
      if (token == null) {
        print('로그인 토큰이 없습니다.');
        return false;
      }

      final response = await http.put(
        Uri.parse(ApiConfig.getUrl('/api/members/$memberId/calorie-goal')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'calorie_goal': calorieGoal,
        }),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        print('✅ 칼로리 목표 업데이트 성공: $calorieGoal kcal');
        // 현재 사용자 정보 업데이트
        final user = await getCurrentUser();
        if (user != null) {
          final updatedUser = user.copyWith(calorieGoal: calorieGoal);
          await _saveUser(updatedUser);
        }
        return true;
      } else {
        print('❌ 칼로리 목표 업데이트 실패: ${response.statusCode}');
        print('❌ Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ 칼로리 목표 업데이트 오류: $e');
      return false;
    }
  }

  /// 프로필 이미지 업로드
  Future<String?> uploadProfileImage(XFile imageFile) async {
    try {
      final token = await getToken();
      final uri = Uri.parse(ApiConfig.getUrl('/api/members/upload-profile-image'));
      
      final request = http.MultipartRequest('POST', uri);
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      final bytes = await imageFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: imageFile.name,
      );
      request.files.add(multipartFile);
      
      final streamedResponse = await request.send().timeout(ApiConfig.timeout);
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final imageUrl = data['imageUrl'] as String;
        print('✅ 프로필 이미지 업로드 성공: $imageUrl');
        return imageUrl;
      } else {
        print('❌ 프로필 이미지 업로드 실패: ${response.statusCode}');
        print('❌ Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ 프로필 이미지 업로드 오류: $e');
      return null;
    }
  }

  /// 목표 칼로리 업데이트 (기존 - 유지)
  Future<bool> _updateCalorieGoal(int memberId, int calorieGoal) async {
    try {
      final token = await getToken();
      if (token == null) {
        print('로그인 토큰이 없습니다.');
        return false;
      }

      final url = Uri.parse(ApiConfig.getUrl('/api/members/$memberId/calorie-goal'));
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'calorie_goal': calorieGoal}),
      );

      if (response.statusCode == 200) {
        // 로컬에 저장된 사용자 정보도 업데이트
        final currentUser = await getCurrentUser();
        if (currentUser != null) {
          final updatedUser = currentUser.copyWith(calorieGoal: calorieGoal);
          await _saveUser(updatedUser);
        }
        return true;
      } else {
        print('목표 칼로리 업데이트 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('목표 칼로리 업데이트 오류: $e');
      return false;
    }
  }

  /// 친구 목록 조회
  Future<List<User>> getFriends(int memberId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/members/$memberId/friends');
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        print('친구 목록 조회 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('친구 목록 조회 오류: $e');
      return [];
    }
  }
}
