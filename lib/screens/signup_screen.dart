// 회원가입 화면
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ttm/constants/app_colors.dart';
import 'package:ttm/services/auth_service.dart';
import 'package:ttm/widgets/terms_agreement_widget.dart';
import 'package:ttm/widgets/password_strength_widget.dart';
import 'package:ttm/widgets/custom_form_fields.dart';
import 'package:ttm/screens/survey/welcome_screen.dart';

// 회원가입 화면 위젯
class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailLocalController = TextEditingController();
  final TextEditingController _phone1Controller = TextEditingController();
  final TextEditingController _phone2Controller = TextEditingController();
  final TextEditingController _phone3Controller = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();
  final AuthService _authService = AuthService();
  
  // FocusNode for auto-focus
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _nicknameFocus = FocusNode();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _emailLocalFocus = FocusNode();
  final FocusNode _phone1Focus = FocusNode();
  final FocusNode _phone2Focus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _passwordConfirmFocus = FocusNode();
  
  bool _showPassword = false;
  bool _showPasswordConfirm = false;
  bool _isLoading = false;
  
  // 핸드폰 번호 앞자리
  String _phonePrefix = '010';
  
  // 이메일 도메인 (@ 없이)
  String _emailDomain = 'naver.com';
  bool _isCustomEmailDomain = false; // 직접입력 모드
  final TextEditingController _customEmailDomainController = TextEditingController();
  
  // 생년월일 선택
  int? _selectedYear;
  int? _selectedMonth;
  int? _selectedDay;
  
  // 중복 확인 상태
  bool _nicknameChecked = false;
  bool _nicknameAvailable = false;
  bool _hasNicknameInput = false;
  bool _usernameChecked = false;
  bool _usernameAvailable = false;
  bool _hasUsernameInput = false;
  
  // 비밀번호 강도 체크
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;
  
  // 비밀번호 확인 일치 여부
  bool _passwordConfirmChecked = false;
  bool _passwordsMatch = false;
  
  // 약관 동의 상태
  bool _agreeAll = false;
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _agreeMarketing = false;
  bool _agreeKakao = false;
  bool _agreePush = false;
  bool _agreeSMS = false;
  bool _agreeEmail = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);
    _passwordController.addListener(_checkPasswordMatch);
    _passwordConfirmController.addListener(_checkPasswordMatch);
    _nicknameController.addListener(() {
      final hasInput = _nicknameController.text.isNotEmpty;
      if (_hasNicknameInput != hasInput || _nicknameChecked) {
        setState(() {
          _hasNicknameInput = hasInput;
          if (_nicknameChecked) {
            _nicknameChecked = false;
            _nicknameAvailable = false;
          }
        });
      }
    });
    _usernameController.addListener(() {
      final hasInput = _usernameController.text.isNotEmpty;
      if (_hasUsernameInput != hasInput || _usernameChecked) {
        setState(() {
          _hasUsernameInput = hasInput;
          if (_usernameChecked) {
            _usernameChecked = false;
            _usernameAvailable = false;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(_checkPasswordStrength);
    _passwordController.removeListener(_checkPasswordMatch);
    _passwordConfirmController.removeListener(_checkPasswordMatch);
    _nameController.dispose();
    _nicknameController.dispose();
    _usernameController.dispose();
    _emailLocalController.dispose();
    _customEmailDomainController.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    _phone3Controller.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    
    _nameFocus.dispose();
    _nicknameFocus.dispose();
    _usernameFocus.dispose();
    _emailLocalFocus.dispose();
    _phone1Focus.dispose();
    _phone2Focus.dispose();
    _passwordFocus.dispose();
    _passwordConfirmFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 뒤로가기 버튼
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_back, size: 20, color: Colors.black54),
                          const SizedBox(width: 8),
                          Text(
                            '뒤로',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 로고 및 제목
                    Center(
                      child: Column(
                        children: [
                          // 로고
                          Image.asset(
                            'assets/icons/logoIcon.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '회원가입',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 회원가입 폼
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 이름 입력
                        const FormLabel('이름'),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _nameController,
                          hintText: '홍길동',
                          focusNode: _nameFocus,
                          onSubmitted: (_) => _nicknameFocus.requestFocus(),
                        ),

                        const SizedBox(height: 20),

                        // 닉네임 입력
                        const FormLabel('닉네임'),
                        const SizedBox(height: 8),
                        TextFieldWithDuplicateCheck(
                          controller: _nicknameController,
                          hintText: '닉네임',
                          focusNode: _nicknameFocus,
                          isChecked: _nicknameChecked,
                          isAvailable: _nicknameAvailable,
                          hasInput: _hasNicknameInput,
                          onCheckPressed: _checkNicknameDuplicate,
                          onSubmitted: (_) => _usernameFocus.requestFocus(),
                          message: _nicknameAvailable
                              ? '✓ 사용 가능한 닉네임입니다'
                              : '✗ 이미 사용중인 닉네임입니다',
                        ),

                        const SizedBox(height: 20),

                        // 아이디 입력
                        const FormLabel('아이디'),
                        const SizedBox(height: 8),
                        TextFieldWithDuplicateCheck(
                          controller: _usernameController,
                          hintText: '아이디',
                          focusNode: _usernameFocus,
                          isChecked: _usernameChecked,
                          isAvailable: _usernameAvailable,
                          hasInput: _hasUsernameInput,
                          onCheckPressed: _checkUsernameDuplicate,
                          onSubmitted: (_) => _emailLocalFocus.requestFocus(),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_-]')),
                          ],
                          message: _usernameAvailable
                              ? '✓ 사용 가능한 아이디입니다'
                              : '✗ 이미 사용중인 아이디입니다',
                        ),

                        const SizedBox(height: 20),
                        
                        // 이메일 입력
                        const FormLabel('이메일'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: CustomTextField(
                                controller: _emailLocalController,
                                hintText: 'example',
                                focusNode: _emailLocalFocus,
                                keyboardType: TextInputType.emailAddress,
                                onSubmitted: (_) => _phone1Focus.requestFocus(),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '@',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: _isCustomEmailDomain
                                  ? CustomTextField(
                                      controller: _customEmailDomainController,
                                      hintText: 'example.com',
                                      keyboardType: TextInputType.emailAddress,
                                      onSubmitted: (_) => _phone1Focus.requestFocus(),
                                    )
                                  : Container(
                                      height: 48,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        _emailDomain,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _emailDomain,
                              isExpanded: true,
                              icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                              items: [
                                'naver.com',
                                'gmail.com',
                                'daum.net',
                                'kakao.com',
                                'hanmail.net',
                                'nate.com',
                                '직접입력',
                              ].map((domain) {
                                return DropdownMenuItem<String>(
                                  value: domain,
                                  child: Text(domain, style: const TextStyle(fontSize: 14)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _emailDomain = value!;
                                  if (value == '직접입력') {
                                    _isCustomEmailDomain = true;
                                    _customEmailDomainController.clear();
                                  } else {
                                    _isCustomEmailDomain = false;
                                  }
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 핸드폰 번호 입력
                        const FormLabel('핸드폰 번호'),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 010 드롭다운
                            SizedBox(
                              width: 80,
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Center(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _phonePrefix,
                                      isExpanded: true,
                                      icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                                      items: ['010', '011', '016', '017', '018', '019'].map((prefix) {
                                        return DropdownMenuItem<String>(
                                          value: prefix,
                                          child: Text(prefix),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() => _phonePrefix = value!);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 하이픈
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Text('-', style: TextStyle(fontSize: 20, color: Colors.grey)),
                            ),
                            const SizedBox(width: 8),
                            // 중간 4자리
                            Expanded(
                              child: CustomTextField(
                                controller: _phone1Controller,
                                hintText: '0000',
                                focusNode: _phone1Focus,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                onChanged: (value) {
                                  if (value.length == 4) {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      _phone2Focus.requestFocus();
                                    });
                                  }
                                },
                                onSubmitted: (_) => _phone2Focus.requestFocus(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 하이픈
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Text('-', style: TextStyle(fontSize: 20, color: Colors.grey)),
                            ),
                            const SizedBox(width: 8),
                            // 마지막 4자리
                            Expanded(
                              child: CustomTextField(
                                controller: _phone2Controller,
                                hintText: '0000',
                                focusNode: _phone2Focus,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                onSubmitted: (_) => _passwordFocus.requestFocus(),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // 생년월일 입력
                        const FormLabel('생년월일'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: CustomDropdown(
                                value: _selectedYear,
                                hint: '년도',
                                items: List.generate(
                                  100,
                                  (index) => DateTime.now().year - index,
                                ),
                                onChanged: (value) {
                                  setState(() => _selectedYear = value);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CustomDropdown
                               (
                                value: _selectedMonth,
                                hint: '월',
                                items: List.generate(12, (index) => index + 1),
                                onChanged: (value) {
                                  setState(() => _selectedMonth = value);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CustomDropdown(
                                value: _selectedDay,
                                hint: '일',
                                items: List.generate(31, (index) => index + 1),
                                onChanged: (value) {
                                  setState(() => _selectedDay = value);
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // 비밀번호 입력
                        const FormLabel('비밀번호'),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _passwordController,
                          hintText: '비밀번호 입력',
                          focusNode: _passwordFocus,
                          obscureText: !_showPassword,
                          onSubmitted: (_) => _passwordConfirmFocus.requestFocus(),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(50),
                          ],
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              setState(() {
                                _showPassword = !_showPassword;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 비밀번호 강도 체크
                        PasswordStrengthWidget(
                          hasMinLength: _hasMinLength,
                          hasUppercase: _hasUppercase,
                          hasLowercase: _hasLowercase,
                          hasDigit: _hasDigit,
                          hasSpecialChar: _hasSpecialChar,
                        ),

                        const SizedBox(height: 20),

                        // 비밀번호 확인 입력
                        const FormLabel('비밀번호 확인'),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _passwordConfirmController,
                          hintText: '비밀번호를 한번 더 입력해주세요',
                          focusNode: _passwordConfirmFocus,
                          obscureText: !_showPasswordConfirm,
                          onSubmitted: (_) => FocusScope.of(context).unfocus(),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(50),
                          ],
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPasswordConfirm ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              setState(() {
                                _showPasswordConfirm = !_showPasswordConfirm;
                              });
                            },
                          ),
                        ),
                        if (_passwordConfirmChecked)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 4),
                            child: Row(
                              children: [
                                Icon(
                                  _passwordsMatch ? Icons.check_circle : Icons.cancel,
                                  size: 16,
                                  color: _passwordsMatch ? const Color(0xFF66BB6A) : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _passwordsMatch ? '비밀번호가 일치합니다!' : '비밀번호가 일치하지 않습니다',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _passwordsMatch ? const Color(0xFF66BB6A) : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 32),

                        // 약관 동의
                        TermsAgreementWidget(
                          agreeAll: _agreeAll,
                          agreeTerms: _agreeTerms,
                          agreePrivacy: _agreePrivacy,
                          agreeMarketing: _agreeMarketing,
                          agreeKakao: _agreeKakao,
                          agreePush: _agreePush,
                          agreeSMS: _agreeSMS,
                          agreeEmail: _agreeEmail,
                          onAgreeAllChanged: (value) {
                            setState(() {
                              _agreeAll = value;
                              _agreeTerms = value;
                              _agreePrivacy = value;
                              _agreeMarketing = value;
                              _agreeKakao = value;
                              _agreePush = value;
                              _agreeSMS = value;
                              _agreeEmail = value;
                            });
                          },
                          onAgreeTermsChanged: (value) {
                            setState(() {
                              _agreeTerms = value;
                              _updateAgreeAll();
                            });
                          },
                          onAgreePrivacyChanged: (value) {
                            setState(() {
                              _agreePrivacy = value;
                              _updateAgreeAll();
                            });
                          },
                          onAgreeMarketingChanged: (value) {
                            setState(() {
                              _agreeMarketing = value;
                              if (_agreeMarketing) {
                                // 마케팅 수신동의 체크하면 하위 항목 모두 체크
                                _agreeKakao = true;
                                _agreePush = true;
                                _agreeSMS = true;
                                _agreeEmail = true;
                              } else {
                                // 마케팅 수신동의 해제하면 하위 항목 모두 해제
                                _agreeKakao = false;
                                _agreePush = false;
                                _agreeSMS = false;
                                _agreeEmail = false;
                              }
                              _updateAgreeAll();
                            });
                          },
                          onAgreeKakaoChanged: (value) {
                            setState(() {
                              _agreeKakao = value;
                              // 하나라도 체크되면 마케팅 수신동의 자동 체크
                              if (_agreeKakao || _agreePush || _agreeSMS || _agreeEmail) {
                                _agreeMarketing = true;
                              } else {
                                _agreeMarketing = false;
                              }
                              _updateAgreeAll();
                            });
                          },
                          onAgreePushChanged: (value) {
                            setState(() {
                              _agreePush = value;
                              // 하나라도 체크되면 마케팅 수신동의 자동 체크
                              if (_agreeKakao || _agreePush || _agreeSMS || _agreeEmail) {
                                _agreeMarketing = true;
                              } else {
                                _agreeMarketing = false;
                              }
                              _updateAgreeAll();
                            });
                          },
                          onAgreeSMSChanged: (value) {
                            setState(() {
                              _agreeSMS = value;
                              // 하나라도 체크되면 마케팅 수신동의 자동 체크
                              if (_agreeKakao || _agreePush || _agreeSMS || _agreeEmail) {
                                _agreeMarketing = true;
                              } else {
                                _agreeMarketing = false;
                              }
                              _updateAgreeAll();
                            });
                          },
                          onAgreeEmailChanged: (value) {
                            setState(() {
                              _agreeEmail = value;
                              // 하나라도 체크되면 마케팅 수신동의 자동 체크
                              if (_agreeKakao || _agreePush || _agreeSMS || _agreeEmail) {
                                _agreeMarketing = true;
                              } else {
                                _agreeMarketing = false;
                              }
                              _updateAgreeAll();
                            });
                          },
                        ),

                        const SizedBox(height: 32),

                        // 회원가입 버튼
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _handleSignup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF66BB6A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              '가입하기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 로그인 링크
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '이미 계정이 있으신가요? ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const Text(
                                  '로그인',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF66BB6A),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 로딩 인디케이터
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF66BB6A)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 전체 동의 상태 업데이트
  void _updateAgreeAll() {
    _agreeAll = _agreeTerms && 
                _agreePrivacy && 
                _agreeMarketing &&
                _agreeKakao &&
                _agreePush &&
                _agreeSMS &&
                _agreeEmail;
  }

  /// 이메일 중복 확인
  Future<void> _checkEmailDuplicate() async {
    final emailLocal = _emailLocalController.text.trim();
    final domain = _isCustomEmailDomain ? _customEmailDomainController.text.trim() : _emailDomain;
    final email = '$emailLocal@$domain';
    
    if (emailLocal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일을 입력해주세요')),
      );
      return;
    }

    if (_isCustomEmailDomain && domain.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('도메인을 입력해주세요')),
      );
      return;
    }

    if (emailLocal.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 이메일 형식이 아닙니다')),
      );
      return;
    }

    try {
      final isDuplicate = await _authService.checkEmailDuplicate(email);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isDuplicate ? '이미 사용중인 이메일입니다' : '사용 가능한 이메일입니다')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일 확인 중 오류가 발생했습니다')),
      );
    }
  }

  /// 닉네임 중복 확인
  Future<void> _checkNicknameDuplicate() async {
    final nickname = _nicknameController.text.trim();
    
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임을 입력해주세요')),
      );
      return;
    }

    try {
      final isDuplicate = await _authService.checkNicknameDuplicate(nickname);
      
      setState(() {
        _nicknameChecked = true;
        _nicknameAvailable = !isDuplicate;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임 확인 중 오류가 발생했습니다')),
      );
    }
  }

  /// 아이디 중복 확인
  Future<void> _checkUsernameDuplicate() async {
    final username = _usernameController.text.trim();
    
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디를 입력해주세요')),
      );
      return;
    }

    if (username.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디는 3자 이상이어야 합니다')),
      );
      return;
    }

    try {
      final isDuplicate = await _authService.checkLoginIdDuplicate(username);
      
      setState(() {
        _usernameChecked = true;
        _usernameAvailable = !isDuplicate;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디 확인 중 오류가 발생했습니다')),
      );
    }
  }

  /// 비밀번호 강도 체크
  void _checkPasswordStrength() {
    final password = _passwordController.text;
    
    setState(() {
      _hasMinLength = password.length >= 10;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasDigit = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  /// 비밀번호 확인 일치 여부 체크
  void _checkPasswordMatch() {
    final password = _passwordController.text;
    final passwordConfirm = _passwordConfirmController.text;
    
    if (passwordConfirm.isEmpty) {
      setState(() {
        _passwordConfirmChecked = false;
        _passwordsMatch = false;
      });
      return;
    }
    
    setState(() {
      _passwordConfirmChecked = true;
      _passwordsMatch = password == passwordConfirm;
    });
  }

  /// 회원가입 처리
  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final nickname = _nicknameController.text.trim();
    final username = _usernameController.text.trim();
    final emailLocal = _emailLocalController.text.trim();
    final domain = _isCustomEmailDomain ? _customEmailDomainController.text.trim() : _emailDomain;
    final email = '$emailLocal@$domain';
    final phone1 = _phone1Controller.text.trim();
    final phone2 = _phone2Controller.text.trim();
    final phone = '$_phonePrefix-$phone1-$phone2';
    final password = _passwordController.text.trim();
    final passwordConfirm = _passwordConfirmController.text.trim();

    // 유효성 검사
    if (name.isEmpty || nickname.isEmpty || username.isEmpty || emailLocal.isEmpty || phone1.isEmpty || phone2.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필드를 입력해주세요')),
      );
      return;
    }

    // 도메인 입력 확인
    if (_isCustomEmailDomain && domain.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일 도메인을 입력해주세요')),
      );
      return;
    }

    // 닉네임 중복 확인
    if (!_nicknameChecked || !_nicknameAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임 중복 확인을 해주세요')),
      );
      return;
    }

    // 아이디 중복 확인
    if (!_usernameChecked || !_usernameAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디 중복 확인을 해주세요')),
      );
      return;
    }

    if (username.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디는 3자 이상이어야 합니다')),
      );
      return;
    }

    if (emailLocal.isEmpty || emailLocal.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 이메일을 입력해주세요')),
      );
      return;
    }

    // 핸드폰 번호 검증
    if (phone1.length < 3 || phone1.length > 4 || phone2.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 핸드폰 번호를 입력해주세요')),
      );
      return;
    }

    // 생년월일 검증
    if (_selectedYear == null || _selectedMonth == null || _selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('생년월일을 선택해주세요')),
      );
      return;
    }

    // 비밀번호 강도 체크
    if (!_hasMinLength || !_hasUppercase || !_hasLowercase || !_hasDigit || !_hasSpecialChar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호 조건을 모두 충족해주세요')),
      );
      return;
    }

    if (password != passwordConfirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 일치하지 않습니다')),
      );
      return;
    }

    // 필수 약관 동의 확인
    if (!_agreeTerms || !_agreePrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 약관에 동의해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. 회원가입 시도
      final user = await _authService.signup(
        loginId: _usernameController.text.trim(),
        nickname: _nicknameController.text.trim(),
        email: email,
        password: password,
        name: name,
        phone: phone,
        birthdate: birthdate,
        gender: 'M', // TODO: 성별 선택 UI 추가 시 실제 값 사용
      );

      if (!mounted) return;

      if (user != null) {
        // 2. 회원가입 성공 -> 자동 로그인 시도
        final loggedInUser = await _authService.login(
          _usernameController.text.trim(),
          password,
        );
        
        if (!mounted) return;
        
        if (loggedInUser != null) {
          // 3. 로그인 성공 - Welcome Screen으로 이동
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${loggedInUser.nickname}님 가입을 환영합니다!')),
          );
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => WelcomeScreen(
                nickname: loggedInUser.nickname,
                memberId: loggedInUser.memberId,
              ),
            ),
          );
        } else {
          // 로그인 실패 - 로그인 화면으로 이동
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('가입은 완료되었습니다. 로그인해주세요.')),
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        // 회원가입 실패
        print('회원가입 실패: 닉네임=$nickname, 아이디=$username');
        print('닉네임 중복확인: checked=$_nicknameChecked, available=$_nicknameAvailable');
        print('아이디 중복확인: checked=$_usernameChecked, available=$_usernameAvailable');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('회원가입에 실패했습니다. 중복 확인을 다시 진행해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원가입 중 오류가 발생했습니다: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String get birthdate {
    if (_selectedYear == null || _selectedMonth == null || _selectedDay == null) {
      return '';
    }
    return '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}-${_selectedDay.toString().padLeft(2, '0')}';
  }
}
