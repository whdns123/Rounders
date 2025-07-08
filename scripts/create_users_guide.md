# 🧪 테스트 사용자 생성 가이드

## 방법 1: Firebase Console에서 직접 생성 (추천)

1. **Firebase Console 접속**: https://console.firebase.google.com
2. **roundus-game 프로젝트 선택**
3. **Authentication > Users 탭으로 이동**
4. **"Add user" 버튼 클릭**

### 생성할 계정 목록:
```
1번 유저: 1@test.com / 111111
2번 유저: 2@test.com / 222222
3번 유저: 3@test.com / 333333
4번 유저: 4@test.com / 444444
5번 유저: 5@test.com / 555555
6번 유저: 6@test.com / 666666
7번 유저: 7@test.com / 777777
8번 유저: 8@test.com / 888888
9번 유저: 9@test.com / 999999
10번 유저: 10@test.com / 101010
11번 유저: 11@test.com / 111111
12번 유저: 12@test.com / 121212
```

## 방법 2: 앱에서 회원가입으로 생성

앱의 회원가입 화면에서 위 계정들을 하나씩 생성할 수도 있습니다.

## 방법 3: Flutter 테스트 코드로 생성

아래 코드를 `test/` 폴더에 추가해서 실행할 수 있습니다:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  testWidgets('Create test users', (WidgetTester tester) async {
    await Firebase.initializeApp();
    
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;
    
    for (int i = 1; i <= 12; i++) {
      try {
        final email = '${i}@test.com';
        final password = i.toString() * 6;
        final name = '테스트유저$i';
        
        // Firebase Auth에 계정 생성
        final userCredential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        // Firestore에 사용자 정보 저장
        await firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': name,
          'email': email,
          'phoneNumber': '010-1234-${i.toString().padLeft(4, '0')}',
          'tier': 'clover',
          'tierDisplayName': '클로버',
          'tierScore': 0,
          'meetingsPlayed': 0,
          'meetingsWon': 0,
          'averageRank': 0.0,
          'isHost': false,
          'hostStatus': 'none',
          'favoriteGames': [],
          'participatedMeetings': [],
          'hostedMeetings': [],
          'profileImageUrl': '',
          'bio': '안녕하세요! $name입니다.',
          'joinedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });
        
        print('✅ $i번 사용자 생성 완료: $email');
        
        // 로그아웃
        await auth.signOut();
        
      } catch (e) {
        print('❌ $i번 사용자 생성 실패: $e');
      }
    }
  });
}
```

## 🎉 생성 후 확인 방법

생성된 계정들로 앱에 로그인해서 테스트할 수 있습니다:

- **로그인 화면**에서 이메일: `1@test.com`, 비밀번호: `111111`
- 각 계정으로 모임 신청/취소 테스트
- 여러 계정이 같은 모임에 신청하는 시나리오 테스트

## 📝 추가 사용법

- **호스트 계정**: 일부 계정을 호스트로 승격시켜서 모임 생성 테스트
- **다양한 상태**: 일부는 승인, 일부는 거절로 설정해서 상태별 테스트
- **리뷰 시스템**: 완료된 모임에서 리뷰 작성/조회 테스트 