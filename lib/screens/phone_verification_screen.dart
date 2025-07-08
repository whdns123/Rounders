import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import '../services/phone_auth_service.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final Function(bool success) onVerificationComplete;

  const PhoneVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.onVerificationComplete,
  });

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60;
    });

    _countdownTimer();
  }

  void _countdownTimer() async {
    while (_resendCountdown > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendCountdown--;
        });
      }
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.length != 6) {
      _showMessage('6자리 인증번호를 입력해주세요.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await PhoneAuthService.verifyCode(_codeController.text);

      if (result['success']) {
        _showMessage(result['message'], isError: false);
        widget.onVerificationComplete(true);
        Navigator.of(context).pop(true);
      } else {
        _showMessage(result['message'], isError: true);
      }
    } catch (e) {
      _showMessage('인증에 실패했습니다. 다시 시도해주세요.', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0) return;

    setState(() {
      _isResending = true;
    });

    try {
      final result = await PhoneAuthService.sendVerificationCode(
        widget.phoneNumber,
        context,
      );

      if (result['success']) {
        _startResendCountdown();
        _showMessage('인증번호가 재전송되었습니다.', isError: false);
      } else {
        _showMessage(result['message'], isError: true);
      }
    } catch (e) {
      _showMessage('재전송에 실패했습니다. 다시 시도해주세요.', isError: true);
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFF44336)
            : const Color(0xFF4CAF50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 20,
        color: Color(0xFFEAEAEA),
        fontWeight: FontWeight.w600,
        fontFamily: 'Pretendard',
      ),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF3C3C3C)),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF2E2E2E),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: const Color(0xFFF44336)),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: const Color(0xFF3C3C3C),
        border: Border.all(color: const Color(0xFFF44336)),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: const Text(
          '전화번호 인증',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // 아이콘
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2E2E),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.sms_outlined,
                  color: Color(0xFFF44336),
                  size: 40,
                ),
              ),

              const SizedBox(height: 24),

              // 제목
              const Text(
                '인증번호를 입력해주세요',
                style: TextStyle(
                  color: Color(0xFFEAEAEA),
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                ),
              ),

              const SizedBox(height: 12),

              // 설명
              Text(
                '${PhoneAuthService.formatPhoneNumber(widget.phoneNumber)}로\n발송된 6자리 인증번호를 입력해주세요',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFC2C2C2),
                  fontSize: 14,
                  fontFamily: 'Pretendard',
                ),
              ),

              const SizedBox(height: 40),

              // 인증번호 입력 필드
              Pinput(
                controller: _codeController,
                length: 6,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                submittedPinTheme: submittedPinTheme,
                showCursor: true,
                onCompleted: (pin) => _verifyCode(),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),

              const SizedBox(height: 24),

              // 재전송 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '인증번호를 받지 못하셨나요? ',
                    style: TextStyle(
                      color: Color(0xFFC2C2C2),
                      fontSize: 14,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  GestureDetector(
                    onTap: _resendCountdown > 0 || _isResending
                        ? null
                        : _resendCode,
                    child: Text(
                      _resendCountdown > 0
                          ? '재전송 (${_resendCountdown}s)'
                          : _isResending
                          ? '전송 중...'
                          : '재전송',
                      style: TextStyle(
                        color: _resendCountdown > 0 || _isResending
                            ? const Color(0xFF8C8C8C)
                            : const Color(0xFFF44336),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // 확인 버튼
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF44336),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '확인',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
