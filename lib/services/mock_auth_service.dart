import 'dart:async';

// 목업 User 클래스
class MockUser {
  final String uid;
  final String? email;
  final String? displayName;

  MockUser({required this.uid, this.email, this.displayName});
}

// 목업 UserCredential 클래스
class MockUserCredential {
  final MockUser? user;

  MockUserCredential({this.user});
}

class MockAuthService {
  // 현재 로그인된 사용자
  MockUser? _currentUser;

  // 사용자 상태 변경 컨트롤러
  final _authStateController = StreamController<MockUser?>.broadcast();

  // 현재 로그인된 사용자 상태 스트림
  Stream<MockUser?> get authStateChanges => _authStateController.stream;

  // 현재 로그인된 사용자
  MockUser? get currentUser => _currentUser;

  // 목업 사용자 데이터
  final Map<String, MockUser> _users = {
    'test@example.com': MockUser(
      uid: '1',
      email: 'test@example.com',
      displayName: '테스트 사용자',
    ),
  };

  // 이메일/비밀번호로 로그인
  Future<MockUserCredential?> signInWithEmail(
    String email,
    String password,
  ) async {
    await Future.delayed(const Duration(seconds: 1)); // 네트워크 지연 시뮬레이션

    if (_users.containsKey(email)) {
      _currentUser = _users[email];
      _authStateController.add(_currentUser);
      return MockUserCredential(user: _currentUser);
    }

    throw Exception('로그인 실패: 사용자를 찾을 수 없습니다.');
  }

  // 이메일/비밀번호로 회원가입
  Future<MockUserCredential?> registerWithEmail(
    String email,
    String password,
  ) async {
    await Future.delayed(const Duration(seconds: 1)); // 네트워크 지연 시뮬레이션

    if (_users.containsKey(email)) {
      throw Exception('이미 등록된 이메일입니다.');
    }

    final newUser = MockUser(
      uid: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      displayName: email.split('@').first,
    );

    _users[email] = newUser;
    _currentUser = newUser;
    _authStateController.add(_currentUser);

    return MockUserCredential(user: _currentUser);
  }

  // 게스트 로그인 (테스트용)
  Future<MockUserCredential?> signInAnonymously() async {
    await Future.delayed(const Duration(seconds: 1)); // 네트워크 지연 시뮬레이션

    final guestUser = MockUser(
      uid: 'guest-${DateTime.now().millisecondsSinceEpoch}',
      displayName: '게스트',
    );

    _currentUser = guestUser;
    _authStateController.add(_currentUser);

    return MockUserCredential(user: _currentUser);
  }



  // 로그아웃
  Future<void> signOut() async {
    await Future.delayed(const Duration(seconds: 1)); // 네트워크 지연 시뮬레이션
    _currentUser = null;
    _authStateController.add(null);
  }

  // 서비스 종료
  void dispose() {
    _authStateController.close();
  }
}
