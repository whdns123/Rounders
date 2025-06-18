import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PhoneAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static String? _verificationId;
  static int? _resendToken;

  // 전화번호 유효성 검사
  static bool isValidPhoneNumber(String phoneNumber) {
    // 한국 전화번호 형식 확인 (010, 011, 016, 017, 018, 019)
    final regex = RegExp(r'^01[0-9]-?[0-9]{3,4}-?[0-9]{4}$');
    final cleanNumber = phoneNumber.replaceAll('-', '').replaceAll(' ', '');
    return regex.hasMatch(cleanNumber);
  }

  // 전화번호 포맷 (010-1234-5678 형태로)
  static String formatPhoneNumber(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll('-', '').replaceAll(' ', '');
    if (cleanNumber.length == 11) {
      return '${cleanNumber.substring(0, 3)}-${cleanNumber.substring(3, 7)}-${cleanNumber.substring(7)}';
    }
    return phoneNumber;
  }

  // 전화번호로 인증 코드 전송
  static Future<Map<String, dynamic>> sendVerificationCode(
    String phoneNumber,
    BuildContext context,
  ) async {
    try {
      // 한국 국가 코드 추가 (+82)
      String formattedPhone = phoneNumber;
      if (!formattedPhone.startsWith('+82')) {
        // 010-1234-5678 -> 01012345678
        formattedPhone = formattedPhone.replaceAll('-', '').replaceAll(' ', '');
        if (formattedPhone.startsWith('0')) {
          formattedPhone = '+82${formattedPhone.substring(1)}';
        } else {
          formattedPhone = '+82$formattedPhone';
        }
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // 자동 인증 완료 (Android에서만 가능)
        },
        verificationFailed: (FirebaseAuthException e) {
          String errorMessage = '인증에 실패했습니다.';
          if (e.code == 'invalid-phone-number') {
            errorMessage = '잘못된 전화번호 형식입니다.';
          } else if (e.code == 'too-many-requests') {
            errorMessage = '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: const Color(0xFFF44336),
            ),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('인증 코드가 전송되었습니다.'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        forceResendingToken: _resendToken,
      );

      return {'success': true, 'message': '인증 코드가 전송되었습니다.'};
    } catch (e) {
      return {'success': false, 'message': '인증 코드 전송에 실패했습니다: ${e.toString()}'};
    }
  }

  // 인증 코드 확인
  static Future<Map<String, dynamic>> verifyCode(String code) async {
    try {
      if (_verificationId == null) {
        return {'success': false, 'message': '인증 ID가 없습니다. 다시 시도해주세요.'};
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );

      return {
        'success': true,
        'credential': credential,
        'message': '전화번호 인증이 완료되었습니다.',
      };
    } catch (e) {
      String errorMessage = '인증에 실패했습니다.';
      if (e.toString().contains('invalid-verification-code')) {
        errorMessage = '잘못된 인증 코드입니다.';
      } else if (e.toString().contains('session-expired')) {
        errorMessage = '인증 시간이 만료되었습니다. 다시 시도해주세요.';
      }

      return {'success': false, 'message': errorMessage};
    }
  }

  // 인증 상태 초기화
  static void reset() {
    _verificationId = null;
    _resendToken = null;
  }
}
