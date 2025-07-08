const admin = require('firebase-admin');

// Firebase Admin SDK 초기화
const serviceAccount = require('../android/app/google-services.json');

admin.initializeApp({
  credential: admin.credential.cert({
    projectId: serviceAccount.project_info.project_id,
    privateKey: "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDG...\n-----END PRIVATE KEY-----\n",
    clientEmail: "firebase-adminsdk-abcd@roundus-game.iam.gserviceaccount.com"
  }),
  databaseURL: `https://${serviceAccount.project_info.project_id}.firebaseio.com`
});

const auth = admin.auth();
const firestore = admin.firestore();

async function createTestUsers() {
  console.log('🚀 테스트 사용자 12명 생성 시작...');
  
  for (let i = 1; i <= 12; i++) {
    try {
      const email = `${i}@test.com`;
      const password = i.toString().repeat(6); // 1 -> 111111, 2 -> 222222
      const name = `테스트유저${i}`;
      
      console.log(`\n📝 ${i}번째 사용자 생성 중...`);
      console.log(`  - 이메일: ${email}`);
      console.log(`  - 비밀번호: ${password}`);
      console.log(`  - 이름: ${name}`);
      
      // 1. Firebase Auth에 사용자 생성
      const userRecord = await auth.createUser({
        email: email,
        password: password,
        displayName: name,
      });
      
      const uid = userRecord.uid;
      console.log(`  ✅ Auth 계정 생성 완료: ${uid}`);
      
      // 2. Firestore에 사용자 정보 저장
      await firestore.collection('users').doc(uid).set({
        name: name,
        email: email,
        phoneNumber: `010-1234-${i.toString().padStart(4, '0')}`,
        tier: 'clover',
        tierDisplayName: '클로버',
        tierScore: 0,
        meetingsPlayed: 0,
        meetingsWon: 0,
        averageRank: 0.0,
        isHost: false,
        hostStatus: 'none',
        favoriteGames: [],
        participatedMeetings: [],
        hostedMeetings: [],
        profileImageUrl: '',
        bio: `안녕하세요! ${name}입니다.`,
        joinedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        isActive: true,
      });
      
      console.log(`  ✅ Firestore 사용자 정보 저장 완료`);
      
      // 잠시 대기 (Rate limiting 방지)
      await new Promise(resolve => setTimeout(resolve, 500));
      
    } catch (error) {
      console.log(`  ❌ ${i}번째 사용자 생성 실패: ${error.message}`);
    }
  }
  
  console.log('\n🎉 테스트 사용자 생성 완료!');
  console.log('\n📋 생성된 계정 목록:');
  for (let i = 1; i <= 12; i++) {
    const password = i.toString().repeat(6);
    console.log(`  ${i}번 유저: ${i}@test.com / ${password}`);
  }
  
  console.log('\n💡 사용법:');
  console.log('  - 로그인 시 이메일: 1@test.com, 2@test.com, ..., 12@test.com');
  console.log('  - 비밀번호: 111111, 222222, 333333, ..., 121212');
  
  process.exit(0);
}

createTestUsers().catch(console.error); 