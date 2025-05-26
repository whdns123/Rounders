import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 현재 사용자 정보 가져오기
  User? get currentUser => _auth.currentUser;

  // 인증 상태 변경 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 이메일/비밀번호 로그인
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('이메일 로그인 실패: ${e.code}');
      }

      // 자세한 오류 메시지 제공
      switch (e.code) {
        case 'user-not-found':
          throw '등록되지 않은 이메일입니다.';
        case 'wrong-password':
          throw '비밀번호가 일치하지 않습니다.';
        case 'invalid-credential':
          throw '이메일 또는 비밀번호가 잘못되었습니다.';
        case 'user-disabled':
          throw '비활성화된 계정입니다. 관리자에게 문의하세요.';
        case 'too-many-requests':
          throw '너무 많은 로그인 시도가 있었습니다. 잠시 후 다시 시도해주세요.';
        default:
          throw '로그인에 실패했습니다: ${e.message}';
      }
    } catch (e) {
      if (kDebugMode) {
        print('이메일 로그인 실패: $e');
      }
      rethrow;
    }
  }  // 이메일/비밀번호 회원가입
  Future<UserCredential?> registerWithEmail(
      String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('이메일 회원가입 실패: ${e.code}');
      }

      // 자세한 오류 메시지 제공
      switch (e.code) {
        case 'email-already-in-use':
          throw '이미 사용 중인 이메일입니다.';
        case 'invalid-email':
          throw '올바르지 않은 이메일 형식입니다.';
        case 'operation-not-allowed':
          throw '이메일/비밀번호 로그인이 비활성화되어 있습니다.';
        case 'weak-password':
          throw '비밀번호가 너무 약합니다. 더 강력한 비밀번호를 설정해주세요.';
        default:
          throw '회원가입에 실패했습니다: ${e.message}';
      }
    } catch (e) {
      if (kDebugMode) {
        print('이메일 회원가입 실패: $e');
      }
      rethrow;
    }
  }  // 익명 로그인
  Future<UserCredential?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      notifyListeners();
      return credential;
    } catch (e) {
      if (kDebugMode) {
        print('익명 로그인 실패: $e');
      }
      rethrow;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('로그아웃 실패: $e');
      }
      rethrow;
    }
  }

  // 프로필 업데이트
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      if (_auth.currentUser != null) {
        await _auth.currentUser!.updateDisplayName(displayName);
        await _auth.currentUser!.updatePhotoURL(photoURL);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('프로필 업데이트 실패: $e');
      }
      rethrow;
    }
  }
}