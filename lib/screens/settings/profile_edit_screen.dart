import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ttm/models/user.dart';
import 'package:ttm/services/auth_service.dart';
import 'package:ttm/widgets/profile_avatar.dart';
import 'package:ttm/constants/api_config.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final AuthService _authService = AuthService();
  User? _currentUser;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoadingUser = true;
  bool _isSavingProfile = false;
  bool _isChangingPassword = false;
  bool _isEditingBasicInfo = false;
  
  XFile? _selectedProfileImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      // 먼저 로컬 캐시에서 사용자 정보 가져오기
      final localUser = await _authService.getCurrentUser();
      if (localUser != null) {
        setState(() {
          _currentUser = localUser;
          _nameController.text = localUser.memberName ?? '';
          _emailController.text = localUser.email;
        });
      }
      
      // 서버에서 최신 정보 가져오기 (프로필 이미지 포함)
      if (localUser != null) {
        final response = await http.get(
          Uri.parse(ApiConfig.getUrl('/api/members/${localUser.memberId}')),
          headers: {
            'Content-Type': 'application/json',
            if (await _authService.getToken() != null) 
              'Authorization': 'Bearer ${await _authService.getToken()}',
          },
        ).timeout(ApiConfig.timeout);
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final updatedUser = User.fromJson(data);
          await _authService.saveUserLocally(updatedUser);
          
          if (!mounted) return;
          setState(() {
            _currentUser = updatedUser;
            _nameController.text = updatedUser.memberName ?? '';
            _emailController.text = updatedUser.email;
          });
          print('✅ 서버에서 최신 사용자 정보 로드: profileImage=${updatedUser.profileImage}');
        }
      }
    } catch (e) {
      print('⚠️ 서버 정보 로드 실패 (로컬 캐시 사용): $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
    }
  }

  Future<void> _pickProfileImage() async {
    print('🖼️ _pickProfileImage 호출됨');
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      print('🖼️ 선택된 이미지: ${image?.path ?? "null"}');
      
      if (image != null) {
        setState(() {
          _selectedProfileImage = image;
        });
        
        print('✅ _selectedProfileImage 업데이트됨: $_selectedProfileImage');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('프로필 사진이 선택되었습니다'),
              backgroundColor: Color(0xFF1DB954),
            ),
          );
        }
      } else {
        print('⚠️ 이미지 선택 취소됨');
      }
    } catch (e) {
      print('❌ 이미지 선택 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 선택 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '이메일을 입력해주세요';
    }
    final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return '올바른 이메일 형식이 아닙니다';
    }
    return null;
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
      ),
      child: const Icon(
        Icons.person,
        size: 50,
        color: Colors.white,
      ),
    );
  }

  String? _validatePassword(String? value) {
    if (value != null && value.isNotEmpty) {
      if (value.length < 8) {
        return '비밀번호는 최소 8자 이상이어야 합니다';
      }
      final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
      final hasDigit = RegExp(r'[0-9]').hasMatch(value);
      if (!hasLetter || !hasDigit) {
        return '영문과 숫자를 포함해야 합니다';
      }
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (_passwordController.text.isNotEmpty && value != _passwordController.text) {
      return '비밀번호가 일치하지 않습니다';
    }
    return null;
  }

  String? _validateCurrentPassword(String? value) {
    if (_passwordController.text.isNotEmpty && (value == null || value.isEmpty)) {
      return '현재 비밀번호를 입력해주세요';
    }
    return null;
  }

  Future<void> _changePassword() async {
    if (_isChangingPassword) return;

    if (_currentPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('현재 비밀번호를 입력해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('새 비밀번호를 입력해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final passwordError = _validatePassword(_passwordController.text);
    if (passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(passwordError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('새 비밀번호가 일치하지 않습니다'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isChangingPassword = true);

    // TODO: Replace with real API call when backend is ready.
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isChangingPassword = false);

    _currentPasswordController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('비밀번호가 성공적으로 변경되었습니다'),
        backgroundColor: Color(0xFF1DB954),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_isSavingProfile) return;
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인 정보를 불러올 수 없습니다'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();

    final currentName = _currentUser!.memberName ?? '';
    final currentEmail = _currentUser!.email;

    final nameChanged = newName.isNotEmpty && newName != currentName;
    final emailChanged = newEmail.isNotEmpty && newEmail != currentEmail;
    final imageChanged = _selectedProfileImage != null;

    print('🔍 프로필 저장 체크:');
    print('  - nameChanged: $nameChanged (현재: $currentName, 새: $newName)');
    print('  - emailChanged: $emailChanged (현재: $currentEmail, 새: $newEmail)');
    print('  - imageChanged: $imageChanged (_selectedProfileImage: $_selectedProfileImage)');

    if (!nameChanged && !emailChanged && !imageChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('변경된 항목이 없습니다'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() => _isSavingProfile = true);

      String? uploadedImageUrl;
      
      // 이미지가 선택되었으면 먼저 업로드
      if (imageChanged) {
        print('🖼️ 프로필 이미지 업로드 시작...');
        uploadedImageUrl = await _authService.uploadProfileImage(_selectedProfileImage!);
        if (uploadedImageUrl == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이미지 업로드에 실패했습니다'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isSavingProfile = false);
          return;
        }
        print('✅ 이미지 업로드 성공: $uploadedImageUrl');
      }

      print('💾 프로필 업데이트 시작...');
      print('  - memberId: ${_currentUser!.memberId}');
      print('  - name: ${nameChanged ? newName : null}');
      print('  - email: ${emailChanged ? newEmail : null}');
      print('  - profileImage: $uploadedImageUrl');
      
      final updatedUser = await _authService.updateProfile(
        memberId: _currentUser!.memberId,
        name: nameChanged ? newName : null,
        email: emailChanged ? newEmail : null,
        profileImage: uploadedImageUrl,
      );

      print('✅ 프로필 업데이트 완료: $updatedUser');

      if (!mounted) return;

      setState(() {
        _currentUser = updatedUser ?? _currentUser;
        _nameController.text = _currentUser?.memberName ?? '';
        _emailController.text = _currentUser?.email ?? '';
        _selectedProfileImage = null;  // 저장 후 선택된 이미지 초기화
        _isEditingBasicInfo = false;
        _isSavingProfile = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('프로필이 성공적으로 수정되었습니다'),
          backgroundColor: Color(0xFF1DB954),
        ),
      );

      // 화면을 닫기 전에 서버에서 최신 정보 로드하여 화면 갱신
      await _loadUser();
      
      if (mounted) {
        Navigator.pop(context, true); // true를 반환하여 이전 화면에 알림
      }
    } catch (e, stackTrace) {
      print('❌ 프로필 저장 오류: $e');
      print('❌ StackTrace: $stackTrace');
      if (!mounted) return;
      setState(() => _isSavingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('프로필 저장 실패: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '내 정보 수정',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (_isLoadingUser)
            const Center(child: CircularProgressIndicator())
          else
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              print('👆 프로필 이미지 영역 탭됨!');
                              _pickProfileImage();
                            },
                            child: Stack(
                              children: [
                                ProfileAvatar(
                                  size: 100,
                                  profileImage: _selectedProfileImage,
                                  profileImageUrl: _currentUser?.profileImage,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF1DB954),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              print('👆 "프로필 사진 변경" 텍스트 탭됨!');
                              _pickProfileImage();
                            },
                            child: Text(
                              '프로필 사진 변경',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF1DB954),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '기본 정보',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: _isLoadingUser
                              ? null
                              : () {
                                  setState(() {
                                    _isEditingBasicInfo = !_isEditingBasicInfo;
                                  });
                                },
                          child: Text(
                            _isEditingBasicInfo ? '취소' : '수정',
                            style: const TextStyle(
                              color: Color(0xFF1DB954),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '이름',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      enabled: _isEditingBasicInfo,
                      decoration: InputDecoration(
                        hintText: '이름을 입력하세요',
                        filled: true,
                        fillColor:
                            _isEditingBasicInfo ? Colors.grey[50] : Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '이름을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '이메일',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      enabled: _isEditingBasicInfo,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'email@example.com',
                        filled: true,
                        fillColor:
                            _isEditingBasicInfo ? Colors.grey[50] : Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 40),
                    Row(
                      children: [
                        const Text(
                          '비밀번호 변경',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(선택사항)',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '현재 비밀번호',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrentPassword,
                      decoration: InputDecoration(
                        hintText: '현재 비밀번호를 입력하세요',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrentPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureCurrentPassword = !_obscureCurrentPassword;
                            });
                          },
                        ),
                      ),
                      validator: _validateCurrentPassword,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '새 비밀번호',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: '영문, 숫자 포함 8자 이상',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey[400],
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '비밀번호 확인',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        hintText: '비밀번호를 다시 입력하세요',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey[400],
                          ),
                          onPressed: () {
                            setState(
                              () => _obscureConfirmPassword = !_obscureConfirmPassword,
                            );
                          },
                        ),
                      ),
                      validator: _validateConfirmPassword,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isChangingPassword || _isLoadingUser
                            ? null
                            : _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1DB954),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isChangingPassword
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                '비밀번호 변경',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const Divider(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSavingProfile || _isLoadingUser
                            ? null
                            : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1DB954),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSavingProfile
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                '프로필 저장',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          if ((_isSavingProfile || _isChangingPassword) && !_isLoadingUser)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withOpacity(0.08),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
