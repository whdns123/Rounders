import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/terms_service.dart';
import '../services/phone_auth_service.dart';
import '../services/email_validation_service.dart';
import '../models/user_model.dart';
import 'terms_detail_screen.dart';
import 'phone_verification_screen.dart';
import '../utils/toast_utils.dart';

class SignupScreen extends StatefulWidget {
  final VoidCallback? onSignupSuccess;

  const SignupScreen({Key? key, this.onSignupSuccess}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  bool _isPhoneVerified = false;
  bool _isPhoneSending = false;
  String? _errorMessage;

  // 비밀번호 조건
  bool _hasValidLength = false;
  bool _hasValidCombination = false;

  // 약관 동의
  bool _allAgreed = false;
  bool _agreeTerms = false;
  bool _agreeAge = false;
  bool _agreePrivacy = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final password = _passwordController.text;
    setState(() {
      _hasValidLength = password.length >= 10 && password.length <= 15;

      int types = 0;
      if (password.contains(RegExp(r'[a-zA-Z]'))) types++; // 영문
      if (password.contains(RegExp(r'[0-9]'))) types++; // 숫자
      if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) types++; // 특수문자

      _hasValidCombination = types >= 2;
    });
  }

  bool get _canSignup {
    return _nameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        EmailValidationService.isValidEmailFormat(_emailController.text) &&
        _phoneController.text.isNotEmpty &&
        _isPhoneVerified &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text &&
        _hasValidLength &&
        _hasValidCombination &&
        _agreeTerms &&
        _agreeAge &&
        _agreePrivacy;
  }

  // 전화번호 인증 코드 전송
  Future<void> _sendPhoneVerification() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ToastUtils.showError(context, '전화번호를 먼저 입력해주세요.');
      return;
    }

    if (!PhoneAuthService.isValidPhoneNumber(phone)) {
      ToastUtils.showError(context, '올바른 전화번호 형식이 아닙니다.');
      return;
    }

    setState(() {
      _isPhoneSending = true;
    });

    try {
      final result = await PhoneAuthService.sendVerificationCode(
        phone,
        context,
      );

      setState(() {
        _isPhoneSending = false;
      });

      if (result['success']) {
        // 인증 화면으로 이동
        final verified = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => PhoneVerificationScreen(
              phoneNumber: phone,
              onVerificationComplete: (success) {
                setState(() {
                  _isPhoneVerified = success;
                });
              },
            ),
          ),
        );

        if (verified == true) {
          setState(() {
            _isPhoneVerified = true;
          });
          ToastUtils.showSuccess(context, '전화번호 인증이 완료되었습니다.');
        }
      } else {
        ToastUtils.showError(context, result['message'] ?? '인증번호 전송에 실패했습니다.');
      }
    } catch (e) {
      setState(() {
        _isPhoneSending = false;
      });

      ToastUtils.showError(context, '전화번호 인증 중 오류가 발생했습니다.');
    }
  }

  Future<void> _signup() async {
    if (!_canSignup) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(
        context,
        listen: false,
      );

      // Firebase Auth로 회원가입
      final userCredential = await authService.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (userCredential?.user != null) {
        // 사용자 추가 정보 저장
        final user = UserModel(
          id: userCredential!.user!.uid,
          email: _emailController.text.trim(),
          name: _nameController.text.trim(),
          gender: '미설정',
          ageGroup: '미설정',
          location: '미설정',
          phone: PhoneAuthService.formatPhoneNumber(
            _phoneController.text.trim(),
          ),
        );

        await firestoreService.updateUserProfile(user);

        if (mounted) {
          widget.onSignupSuccess?.call();
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().contains('email-already-in-use')
            ? '이미 사용 중인 이메일입니다.'
            : '회원가입 중 오류가 발생했습니다.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleAllAgreement(bool? value) {
    setState(() {
      _allAgreed = value ?? false;
      _agreeTerms = _allAgreed;
      _agreeAge = _allAgreed;
      _agreePrivacy = _allAgreed;
    });
  }

  void _updateIndividualAgreement() {
    setState(() {
      _allAgreed = _agreeTerms && _agreeAge && _agreePrivacy;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // 이름 입력
                        _buildNameField(),

                        const SizedBox(height: 36),

                        // 이메일 입력 + 검증
                        _buildEmailField(),

                        const SizedBox(height: 36),

                        // 전화번호 입력 + 인증
                        _buildPhoneField(),

                        const SizedBox(height: 36),

                        // 비밀번호 섹션
                        _buildPasswordSection(),

                        const SizedBox(height: 36),

                        // 약관 동의
                        _buildAgreementSection(),

                        const SizedBox(height: 24),

                        // 오류 메시지
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.red),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 회원가입 버튼
            _buildSignupButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Color(0xFFEAEAEA),
              size: 20,
            ),
          ),
          const Expanded(
            child: Text(
              '회원가입',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
          const SizedBox(width: 44), // IconButton과 같은 크기
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '이름',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFFEAEAEA),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF3C3C3C),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextFormField(
            controller: _nameController,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFFFFFFFF),
            ),
            decoration: const InputDecoration(
              hintText: '이름을 입력해주세요.',
              hintStyle: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFFA0A0A0),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '이름을 입력해주세요.';
              }
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '이메일',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFFEAEAEA),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF3C3C3C),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFFFFFFFF),
            ),
            decoration: const InputDecoration(
              hintText: '이메일을 입력해주세요.',
              hintStyle: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFFA0A0A0),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '이메일을 입력해주세요.';
              }
              if (!EmailValidationService.isValidEmailFormat(value)) {
                return '올바른 이메일 형식이 아닙니다.';
              }
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '전화번호',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFFEAEAEA),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF3C3C3C),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFFFFFFFF),
                  ),
                  decoration: const InputDecoration(
                    hintText: '010-1234-5678',
                    hintStyle: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFFA0A0A0),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '전화번호를 입력해주세요.';
                    }
                    if (!PhoneAuthService.isValidPhoneNumber(value)) {
                      return '올바른 전화번호 형식이 아닙니다.';
                    }
                    return null;
                  },
                  onChanged: (_) {
                    setState(() {
                      _isPhoneVerified = false;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 44,
              width: 88,
              decoration: BoxDecoration(
                color: _isPhoneSending
                    ? const Color(0xFF6E6E6E)
                    : (_isPhoneVerified
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF4B4B4B)),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _isPhoneVerified
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF4B4B4B),
                ),
              ),
              child: TextButton(
                onPressed: _isPhoneSending ? null : _sendPhoneVerification,
                child: _isPhoneSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFFFFFFF),
                          ),
                        ),
                      )
                    : Text(
                        _isPhoneVerified ? '인증완료' : '인증하기',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _isPhoneVerified
                              ? const Color(0xFFFFFFFF)
                              : const Color(0xFF6E6E6E),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 비밀번호 입력
        const Text(
          '비밀번호',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFFEAEAEA),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF3C3C3C),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFFFFFFFF),
            ),
            decoration: InputDecoration(
              hintText: '비밀번호를 입력해주세요.',
              hintStyle: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFFA0A0A0),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFFA0A0A0),
                  size: 20,
                ),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),

        const SizedBox(height: 10),

        // 비밀번호 확인
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF3C3C3C),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFFFFFFFF),
            ),
            decoration: InputDecoration(
              hintText: '비밀번호를 다시 입력해주세요.',
              hintStyle: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFFA0A0A0),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: const Color(0xFFA0A0A0),
                  size: 20,
                ),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),

        const SizedBox(height: 8),

        // 비밀번호 조건
        _buildPasswordConditions(),
      ],
    );
  }

  Widget _buildPasswordConditions() {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              _hasValidCombination
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              size: 16,
              color: _hasValidCombination
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFD6D6D6),
            ),
            const SizedBox(width: 8),
            const Text(
              '영문, 숫자 또는 특수문자 중 2가지 조합',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFFD6D6D6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              _hasValidLength
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              size: 16,
              color: _hasValidLength
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFD6D6D6),
            ),
            const SizedBox(width: 8),
            const Text(
              '10~15자 이내',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFFD6D6D6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAgreementSection() {
    return Column(
      children: [
        // 전체 동의
        Row(
          children: [
            GestureDetector(
              onTap: () => _toggleAllAgreement(!_allAgreed),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _allAgreed
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF8C8C8C),
                    width: 2,
                  ),
                  color: _allAgreed
                      ? const Color(0xFF4CAF50)
                      : Colors.transparent,
                ),
                child: _allAgreed
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '전체동의',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFFEAEAEA),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 개별 약관들
        _buildAgreementItem(
          '(필수) 이용 약관 동의',
          _agreeTerms,
          (value) {
            setState(() {
              _agreeTerms = value;
            });
            _updateIndividualAgreement();
          },
          () {
            final terms = TermsService.getServiceTerms();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TermsDetailScreen(terms: terms),
              ),
            );
          },
        ),

        _buildAgreementItem(
          '(필수) 만 14세 이상 확인',
          _agreeAge,
          (value) {
            setState(() {
              _agreeAge = value;
            });
            _updateIndividualAgreement();
          },
          () {
            // 만 14세 이상 확인 약관 (간단한 텍스트)
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF2A2A2A),
                title: const Text(
                  '만 14세 이상 확인',
                  style: TextStyle(color: Colors.white),
                ),
                content: const Text(
                  '본 서비스는 만 14세 이상부터 이용하실 수 있습니다.\n생년월일을 정확히 입력해주세요.',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('확인'),
                  ),
                ],
              ),
            );
          },
        ),

        _buildAgreementItem(
          '(필수) 개인정보 수집 및 이용 동의',
          _agreePrivacy,
          (value) {
            setState(() {
              _agreePrivacy = value;
            });
            _updateIndividualAgreement();
          },
          () {
            final terms = TermsService.getPrivacyPolicy();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TermsDetailScreen(terms: terms),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAgreementItem(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
    VoidCallback onDetailTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onChanged(!value),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: value
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF8C8C8C),
                  width: 2,
                ),
                color: value ? const Color(0xFF4CAF50) : Colors.transparent,
              ),
              child: value
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onDetailTap,
              child: Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Color(0xFFEAEAEA),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Color(0xFF8C8C8C),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF111111),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _canSignup && !_isLoading ? _signup : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _canSignup
                ? const Color(0xFF4CAF50)
                : const Color(0xFFC2C2C2),
            foregroundColor: _canSignup
                ? Colors.white
                : const Color(0xFF111111), // 비활성화 시 어두운 텍스트로 변경
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  '회원가입',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
        ),
      ),
    );
  }
}
