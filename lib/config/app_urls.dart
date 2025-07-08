/// 앱에서 사용하는 외부 URL 상수 관리
class AppUrls {
  // ==================== 법적 문서 URL ====================

  /// 개인정보 처리방침 URL
  /// Google Play Console에 등록할 URL
  static const String privacyPolicy = 'https://rounders-app.com/privacy-policy';

  /// 서비스 이용약관 URL
  static const String termsOfService =
      'https://rounders-app.com/terms-of-service';

  /// 환불 정책 URL (상세)
  static const String refundPolicy = 'https://rounders-app.com/refund-policy';

  // ==================== 고객 지원 URL ====================

  /// 고객센터 웹사이트
  static const String customerService =
      'https://rounders-admin.com/customer-service';

  /// 제휴 및 호스트 지원
  static const String partnership = 'https://rounders-admin.com/partnership';

  /// 호스트 지원 페이지
  static const String hostSupport = 'https://rounders-admin.com/host-support';

  /// FAQ 페이지
  static const String faq = 'https://rounders-app.com/faq';

  // ==================== 소셜 미디어 ====================

  /// 공식 인스타그램
  static const String instagram = 'https://instagram.com/rounders_official';

  /// 공식 카카오톡 채널
  static const String kakaoChannel = 'https://pf.kakao.com/rounders';

  /// 공식 블로그
  static const String blog = 'https://blog.rounders-app.com';

  // ==================== 앱스토어 링크 ====================

  /// Google Play Store 앱 페이지
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.example.roundus';

  /// App Store 앱 페이지 (iOS)
  static const String appStoreUrl =
      'https://apps.apple.com/kr/app/rounders/id123456789';

  // ==================== 개발/테스트 환경 ====================

  /// 개발 서버 개인정보 처리방침 (테스트용)
  static const String privacyPolicyDev =
      'https://dev.rounders-app.com/privacy-policy';

  /// 운영 환경 여부에 따른 동적 URL 반환
  static String getPrivacyPolicyUrl({bool isProduction = true}) {
    return isProduction ? privacyPolicy : privacyPolicyDev;
  }

  // ==================== URL 유효성 검증 ====================

  /// URL이 유효한지 검증
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// 모든 필수 URL이 설정되었는지 확인 (개발용)
  static Map<String, bool> validateUrls() {
    return {
      'privacyPolicy': isValidUrl(privacyPolicy),
      'termsOfService': isValidUrl(termsOfService),
      'customerService': isValidUrl(customerService),
      'playStoreUrl': isValidUrl(playStoreUrl),
    };
  }
}
