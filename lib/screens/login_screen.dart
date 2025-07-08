import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
// import '../services/mock_auth_service.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../services/firestore_service.dart';
import '../utils/toast_utils.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginScreen({Key? key, this.onLoginSuccess}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 이미 로그인되어 있는지 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Provider.of<AuthService>(context, listen: false).currentUser !=
          null) {
        _navigateToHome();
      }
    });
  }

  // 로그인 성공 후 홈 화면으로 이동하는 함수
  void _navigateToHome() {
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false, // 이전 스택을 모두 제거
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userCredential = await authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // 사용자 프로필 초기화 확인
      if (userCredential != null && userCredential.user != null) {
        // MVP: 이메일 인증 체크 주석처리
        /*
        // 이메일 인증 확인
        if (!userCredential.user!.emailVerified) {
          setState(() {
            _errorMessage = '이메일 인증이 필요합니다. 이메일을 확인해주세요.';
          });

          // 인증 메일 재발송 옵션 제공
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('이메일 인증이 필요합니다.'),
              action: SnackBarAction(
                label: '재발송',
                onPressed: () async {
                  try {
                    await userCredential.user!.sendEmailVerification();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('인증 메일을 재발송했습니다.')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('메일 발송에 실패했습니다.')),
                    );
                  }
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );

          // 로그아웃 처리
          await authService.signOut();
          return;
        }
        */

        final firestoreService = Provider.of<FirestoreService>(
          context,
          listen: false,
        );
        await firestoreService.initializeUserProfile(userCredential.user!);
      }

      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      }

      if (mounted) {
        _navigateToHome();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '로그인에 실패했습니다. 이메일과 비밀번호를 확인해주세요.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToSignup() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            SignupScreen(onSignupSuccess: widget.onLoginSuccess),
      ),
    );
  }

  void _navigateToForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  void _loginWithSocial(String provider) {
    // TODO: SNS 로그인 구현
    ToastUtils.showToast(context, '$provider 로그인 기능은 곧 추가될 예정입니다.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 120),
                _buildLogoSection(),

                const SizedBox(height: 60),
                _buildEmailLoginSection(),

                // SNS 로그인 기능 개발 중 (임시 비활성화)
                // const SizedBox(height: 60),
                // _buildSocialLoginSection(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return SizedBox(
      width: 140,
      height: 120,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 70,
            child: Image.asset(
              'assets/images/login icon@4x.png',
              width: 80,
              height: 70,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'ROUNDUS',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFFFFFFFF),
              letterSpacing: 0,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailLoginSection() {
    return SizedBox(
      width: 360,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextField(
              controller: _emailController,
              hintText: '이메일',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '이메일을 입력해주세요.';
                }
                if (!value.contains('@')) {
                  return '유효한 이메일 형식이 아닙니다.';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordController,
              hintText: '비밀번호',
              obscureText: !_isPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFFA0A0A0),
                  size: 24,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '비밀번호를 입력해주세요.';
                }
                if (value.length < 6) {
                  return '비밀번호는 6자 이상이어야 합니다.';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2E2E),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFFF44336),
                  ),
                ),
              ),

            if (_errorMessage != null) const SizedBox(height: 16),

            _buildLoginButton(),

            const SizedBox(height: 24),
            _buildTextButtonSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF3C3C3C),
        borderRadius: BorderRadius.circular(6),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Color(0xFFEAEAEA),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFFA0A0A0),
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: 360,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF44336),
          foregroundColor: const Color(0xFFF5F5F5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Color(0xFFF5F5F5),
                  strokeWidth: 2,
                ),
              )
            : const Text(
                '로그인',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: 0,
                  height: 1.5,
                ),
              ),
      ),
    );
  }

  Widget _buildTextButtonSection() {
    return SizedBox(
      width: 360,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _navigateToForgotPassword,
            child: const Text(
              '비밀번호 찾기',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF8C8C8C),
                letterSpacing: 0,
                height: 1.5,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 20,
            color: const Color(0xFF8C8C8C),
            margin: const EdgeInsets.symmetric(horizontal: 40),
          ),
          GestureDetector(
            onTap: _navigateToSignup,
            child: const Text(
              '회원가입',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF8C8C8C),
                letterSpacing: 0,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLoginSection() {
    return SizedBox(
      width: 280,
      child: Column(
        children: [
          const Text(
            'SNS 계정으로 간편로그인하기',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Color(0xFFA0A0A0),
              letterSpacing: 0,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 220,
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSocialButton(
                  onTap: () => _loginWithSocial('Apple'),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset(
                        'assets/images/Group 126.png',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                _buildSocialButton(
                  onTap: () => _loginWithSocial('Google'),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset(
                        'assets/images/Group 127.png',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                _buildSocialButton(
                  onTap: () => _loginWithSocial('Kakao'),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset(
                        'assets/images/Group 128.png',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(onTap: onTap, child: child);
  }
}
