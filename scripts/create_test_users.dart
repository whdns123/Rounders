import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// Firebase 옵션 (Android 사용)
const firebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyDk1v7_NVW6R2g--y4ZCnVw5ayXDHXpjpM',
  appId: '1:864046346586:android:e07720964f50a87f2a8363',
  messagingSenderId: '864046346586',
  projectId: 'roundus-game',
  storageBucket: 'roundus-game.firebasestorage.app',
);

void main() async {
  // Firebase 초기화
  await Firebase.initializeApp(options: firebaseOptions);

  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  print('🚀 테스트 사용자 12명 생성 시작...');

  for (int i = 1; i <= 12; i++) {
    try {
      final email = '${i}@test.com';
      final password = i.toString() * 6; // 1 -> 111111, 2 -> 222222
      final name = '테스트유저$i';

      print('\n📝 $i번째 사용자 생성 중...');
      print('  - 이메일: $email');
      print('  - 비밀번호: $password');
      print('  - 이름: $name');

      // 1. Firebase Auth에 사용자 생성
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      print('  ✅ Auth 계정 생성 완료: $uid');

      // 2. Firestore에 사용자 정보 저장
      await firestore.collection('users').doc(uid).set({
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

      print('  ✅ Firestore 사용자 정보 저장 완료');

      // 로그아웃 (다음 사용자를 위해)
      await auth.signOut();

      // 잠시 대기 (Rate limiting 방지)
      await Future.delayed(Duration(milliseconds: 500));
    } catch (e) {
      print('  ❌ $i번째 사용자 생성 실패: $e');
    }
  }

  print('\n🎉 테스트 사용자 생성 완료!');
  print('\n📋 생성된 계정 목록:');
  for (int i = 1; i <= 12; i++) {
    final password = i.toString() * 6;
    print('  $i번 유저: ${i}@test.com / $password');
  }

  print('\n💡 사용법:');
  print('  - 로그인 시 이메일: 1@test.com, 2@test.com, ..., 12@test.com');
  print('  - 비밀번호: 111111, 222222, 333333, ..., 121212');

  exit(0);
}
