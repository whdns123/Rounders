# 🚀 실제 결제/환불 시스템 전환 가이드

## 📋 준비물 체크리스트

### 1. 필수 서류
- [ ] 사업자등록증 (개인사업자/법인)
- [ ] 통장 사본 (환불 처리용 계좌)
- [ ] 대표자 신분증
- [ ] 사업장 현황 자료

### 2. 온라인 사업 신고 (필요시)
- [ ] 통신판매업 신고 (연 매출 1억 이상 시 필수)
- [ ] 전자상거래 사업자 신고

## 🏦 PG사 선택 및 계약

### 추천 PG사 비교

| PG사 | 수수료 | 장점 | 단점 | 승인기간 |
|------|--------|------|------|----------|
| **토스페이먼츠** | 2.8-3.3% | 당일승인, 개발친화적 | 상대적 높은 수수료 | 당일 |
| **KG이니시스** | 2.3-2.9% | 시장점유율 1위, 안정적 | 승인 시간 소요 | 3-5일 |
| **NHN페이코** | 2.5-3.0% | 카카오페이 연동 우수 | 제한적 결제수단 | 2-3일 |

### 권장: 토스페이먼츠 (빠른 시작)
1. [토스페이먼츠 홈페이지](https://toss.im/business) 접속
2. 사업자 정보 입력 및 서류 업로드
3. 당일 승인 완료 후 API 키 발급

## 🔧 시스템 설정 변경

### 1단계: PG사에서 발급받은 정보 입력

```dart
// lib/config/payment_config.dart 파일 수정

class PaymentConfig {
  // ⚠️ 실제 서비스 배포 시 true로 변경
  static const bool isProduction = true; // 🔥 여기를 true로 변경!
  
  // ⚠️ 실제 포트원 가맹점 코드로 변경
  static const String userCodeProduction = 'imp12345678'; // 🔥 실제 코드로 변경!
  
  // ⚠️ 실제 PG사 코드로 변경
  static const String pgProduction = 'tosspay.tosstest'; // 🔥 실제 PG로 변경!
  
  // ⚠️ 실제 API 키로 변경
  static const String impKeyProduction = 'YOUR_REAL_IMP_KEY'; // 🔥 실제 키로 변경!
  static const String impSecretProduction = 'YOUR_REAL_IMP_SECRET'; // 🔥 실제 시크릿으로 변경!
}
```

### 2단계: PG사별 설정값

#### 토스페이먼츠 사용 시:
```dart
static const String pgProduction = 'tosspay.tosstest'; // 테스트
static const String pgProduction = 'tosspay'; // 실서비스
```

#### KG이니시스 사용 시:
```dart
static const String pgProduction = 'html5_inicis.INIpayTest'; // 테스트
static const String pgProduction = 'html5_inicis'; // 실서비스
```

#### 카카오페이 사용 시:
```dart
static const String pgProduction = 'kakaopay.TC0ONETIME'; // 테스트
static const String pgProduction = 'kakaopay'; // 실서비스
```

## 📱 앱 스토어 결제 관련 정책

### Apple App Store
- **인앱결제 (IAP) 필수 경우**: 디지털 콘텐츠, 구독 서비스
- **외부결제 허용 경우**: 실물 상품, 실제 서비스 (모임 참가비 ✅)
- 라운더스는 실제 오프라인 모임 서비스이므로 외부결제 허용됨

### Google Play Store
- 2023년부터 완화된 정책으로 실제 서비스는 외부결제 허용
- 라운더스는 실제 오프라인 모임 서비스이므로 문제없음

## 🧪 테스트 방법

### 1. 테스트 환경에서 확인
```dart
// 테스트용으로 설정
static const bool isProduction = false;
```
- 100원 결제로 전체 플로우 테스트
- 환불 기능 테스트
- 다양한 결제 수단 테스트

### 2. 실제 환경 전환
```dart
// 실서비스용으로 설정
static const bool isProduction = true;
```
- 소액 결제 (1,000원) 테스트
- 실제 환불 테스트
- 모든 기능 검증 후 배포

## 💰 수수료 및 정산

### 일반적인 수수료 구조
- **신용카드**: 2.3-3.3%
- **실시간계좌이체**: 1.5-2.0%
- **가상계좌**: 500-800원/건
- **간편결제** (카카오페이 등): 2.8-3.5%

### 정산 주기
- **일반**: T+2 또는 T+3 (영업일 기준)
- **빠른정산**: T+1 (수수료 0.2-0.5% 추가)

## 🔒 보안 고려사항

### 1. API 키 보안
```dart
// ❌ 절대 금지: 코드에 직접 하드코딩
static const String impKey = 'real_key_12345';

// ✅ 권장: 환경변수나 보안 설정 파일 사용
static String get impKey => const String.fromEnvironment('IMP_KEY');
```

### 2. 추천 보안 조치
- [ ] API 키를 환경변수로 관리
- [ ] HTTPS 통신 강제
- [ ] 결제 검증 로직 추가
- [ ] 로그에서 민감정보 제거

## 📞 고객지원 연락처

### 토스페이먼츠
- 고객센터: 1588-7309
- 이메일: support@tosspayments.com
- 개발자 문의: developers@tosspayments.com

### KG이니시스
- 고객센터: 1544-7772
- 이메일: support@inicis.com

### 포트원 (아임포트)
- 고객센터: 1670-5176
- 이메일: support@portone.io

## ⚠️ 주의사항

1. **절대 테스트와 실서비스 API 키를 혼용하지 마세요**
2. **실서비스 전환 전 반드시 소액 테스트를 진행하세요**
3. **환불 프로세스를 충분히 테스트하세요**
4. **개인정보처리방침을 결제 관련 내용으로 업데이트하세요**
5. **사업자 정보를 앱 스토어에 정확히 등록하세요**

## 🎯 체크리스트 (실서비스 전환 시)

- [ ] PG사 계약 완료
- [ ] 포트원 실계정 생성 및 PG 연동
- [ ] API 키 발급 및 설정
- [ ] `PaymentConfig.isProduction = true` 설정
- [ ] 소액 테스트 결제 성공
- [ ] 환불 테스트 성공
- [ ] 개인정보처리방침 업데이트
- [ ] 앱 스토어 배포
- [ ] 고객지원 체계 구축

---

💡 **추가 문의사항이 있으시면 각 PG사 고객센터로 연락하시거나, 포트원 기술문서를 참고하세요.** 