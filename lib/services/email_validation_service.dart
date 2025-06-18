class EmailValidationService {
  // 이메일 형식 검증
  static bool isValidEmailFormat(String email) {
    if (email.isEmpty) return false;

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    return emailRegex.hasMatch(email);
  }

  // 간단한 이메일 도메인 존재 확인 (실제 서버 없이 형식만 검증)
  static Future<Map<String, dynamic>> validateEmail(String email) async {
    try {
      // 기본 형식 검증
      if (!isValidEmailFormat(email)) {
        return {'isValid': false, 'message': '올바른 이메일 형식이 아닙니다.'};
      }

      // 도메인 추출
      final domain = email.split('@')[1];

      // 일반적인 이메일 도메인들 확인
      final commonDomains = [
        'gmail.com',
        'naver.com',
        'daum.net',
        'kakao.com',
        'yahoo.com',
        'outlook.com',
        'hotmail.com',
        'nate.com',
        'hanmail.net',
        'korea.kr',
        'co.kr',
        'ac.kr',
      ];

      // 도메인이 일반적인 것들 중 하나이거나 .com, .kr, .net 등으로 끝나면 유효
      bool isDomainValid =
          commonDomains.contains(domain) ||
          domain.endsWith('.com') ||
          domain.endsWith('.kr') ||
          domain.endsWith('.net') ||
          domain.endsWith('.org') ||
          domain.endsWith('.edu');

      if (!isDomainValid) {
        return {'isValid': false, 'message': '존재하지 않는 이메일 도메인입니다.'};
      }

      // 간단한 DNS 조회 시뮬레이션 (실제로는 하지 않음)
      await Future.delayed(const Duration(milliseconds: 500));

      return {'isValid': true, 'message': '유효한 이메일입니다.'};
    } catch (e) {
      return {'isValid': false, 'message': '이메일 검증 중 오류가 발생했습니다.'};
    }
  }

  // 이메일 중복 확인 (추후 Firebase에서 확인)
  static Future<bool> checkEmailExists(String email) async {
    // 실제로는 Firebase Auth에서 확인해야 함
    // 현재는 간단히 형식만 검증
    await Future.delayed(const Duration(milliseconds: 300));
    return false; // 중복되지 않음
  }
}
