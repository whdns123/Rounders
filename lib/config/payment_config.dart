class PaymentConfig {
  // 🔥 실제 서비스 배포 시 변경 필요한 설정들

  // ✅ STEP 1: 운영 환경 설정 (실제 서비스 시 true로 변경)
  static const bool isProduction = true; // 🔧 실서비스 승인 완료 후 true로 변경

  // ✅ STEP 2: 포트원 고객사 식별코드 (User Code)
  static const String userCodeTest = 'iamport'; // 테스트용
  static const String userCodeProduction = 'imp43463655'; // ✅ 실제 고객사 식별코드

  static String get userCode =>
      isProduction ? userCodeProduction : userCodeTest;

  // ✅ STEP 3: PG사 설정 (KG이니시스 실서비스)
  static const String pgTest = 'html5_inicis.INIpayTest'; // 테스트용
  static const String pgProduction =
      'html5_inicis.channel-key-a0af2262-110e-4d0e-a700-a02efe767c18'; // ✅ KG이니시스 + 채널 키

  static String get pg => isProduction ? pgProduction : pgTest;

  // ✅ STEP 4: 포트원 환불 API 키 (포트원에서 발급받은 실제 키)
  static const String impKeyTest = 'imp_apikey'; // 테스트용
  static const String impSecretTest =
      'ekKoeW8RyKuT0VaRp3BLmGGnlEuREhutfXYHuLhFZ1qbkv3uo8xBOBNEOdSBtEcg'; // 테스트용

  static const String impKeyProduction = '3082034800548040'; // ✅ 실제 REST API 키
  static const String impSecretProduction =
      'vx4EK38OrI78XZRahEfeGHE8CD78jy6eiZG1FW4Afa4LRk98D2irewLJrawC4m0PYS9ru7RQY8tusPkT'; // ✅ 실제 REST API Secret

  static String get impKey => isProduction ? impKeyProduction : impKeyTest;
  static String get impSecret =>
      isProduction ? impSecretProduction : impSecretTest;

  // 테스트 결제 금액 설정
  static double getPaymentAmount(double originalAmount) {
    if (isProduction) {
      return originalAmount; // 실제 금액
    } else {
      return 100.0; // 테스트용 100원
    }
  }

  // 앱 스키마
  static const String appScheme = 'rounders';

  // 결제 수단 설정
  static const List<String> supportedPayMethods = [
    'card', // 신용카드
    'trans', // 실시간계좌이체
    'vbank', // 가상계좌
    'phone', // 휴대폰소액결제
    'kakaopay', // 카카오페이
    'payco', // 페이코
    'lpay', // 롯데페이
    'ssgpay', // SSG페이
    'tosspay', // 토스페이
  ];
}
