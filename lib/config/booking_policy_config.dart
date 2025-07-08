/// 예약 및 취소환불 정책 설정
///
/// 결제 심사 요구사항에 맞춘 명확한 서비스 정책 정의
class BookingPolicyConfig {
  // ==================== 예약 관련 정책 ====================

  /// 예약 마감 시간 (모임 시작 몇 시간 전까지 예약 가능)
  static const Duration bookingDeadlineBeforeMeeting = Duration(hours: 2);

  /// 당일 예약 허용 여부
  static const bool allowSameDayBooking = true;

  /// 최소 예약 시간 (모임 시작 몇 분 전까지 예약 가능)
  static const Duration minimumBookingTime = Duration(minutes: 30);

  /// 최대 예약 가능 기간 (몇 일 후까지 예약 가능)
  static const Duration maximumBookingAdvance = Duration(days: 30);

  // ==================== 취소 정책 ====================

  /// 예약 취소 마감 시간 (모임 시작 몇 시간 전까지 취소 가능)
  static const Duration cancellationDeadline = Duration(hours: 3);

  /// 결제 후 무조건 환불 가능 시간 (쿨링오프 기간)
  static const Duration coolingOffPeriod = Duration(minutes: 30);

  // ==================== 환불 정책 ====================

  /// 환불 정책 단계별 설정
  static const List<RefundPolicy> refundPolicies = [
    RefundPolicy(
      name: "결제 후 즉시",
      description: "결제 후 30분 이내",
      daysBeforeMeeting: null,
      hoursBeforeMeeting: null,
      refundRate: 1.0, // 100% 환불
      condition: RefundCondition.coolingOff,
    ),
    RefundPolicy(
      name: "모임 4일 전",
      description: "모임 시작 4일(96시간) 전까지",
      daysBeforeMeeting: 4,
      hoursBeforeMeeting: null,
      refundRate: 1.0, // 100% 환불
      condition: RefundCondition.beforeDeadline,
    ),
    RefundPolicy(
      name: "모임 3일 전",
      description: "모임 시작 3일(72시간) 전까지",
      daysBeforeMeeting: 3,
      hoursBeforeMeeting: null,
      refundRate: 0.9, // 90% 환불 (수수료 10%)
      condition: RefundCondition.beforeDeadline,
    ),
    RefundPolicy(
      name: "모임 1일 전",
      description: "모임 시작 1일(24시간) 전까지",
      daysBeforeMeeting: 1,
      hoursBeforeMeeting: null,
      refundRate: 0.5, // 50% 환불
      condition: RefundCondition.beforeDeadline,
    ),
    RefundPolicy(
      name: "모임 3시간 전",
      description: "모임 시작 3시간 전까지",
      daysBeforeMeeting: null,
      hoursBeforeMeeting: 3,
      refundRate: 0.0, // 환불 불가
      condition: RefundCondition.noRefund,
    ),
  ];

  // ==================== 자동 환불 정책 ====================

  /// 호스트에 의한 모임 취소 시 환불율
  static const double hostCancellationRefundRate = 1.0; // 100% 환불

  /// 시스템 오류 시 환불율
  static const double systemErrorRefundRate = 1.0; // 100% 환불

  /// 승인 거절 시 환불율
  static const double rejectionRefundRate = 1.0; // 100% 환불

  // ==================== 서비스 운영 정책 ====================

  /// 환불 처리 예상 소요일
  static const String refundProcessingDays = "영업일 기준 3~5일";

  /// 고객센터 연락처
  static const String customerServicePhone = "1588-0000";

  /// 서비스 운영 시간
  static const String serviceHours = "평일 09:00 ~ 18:00";

  // ==================== 헬퍼 메서드 ====================

  /// 현재 시간 기준으로 예약 가능한지 확인
  static bool canBookMeeting(DateTime meetingDateTime) {
    final now = DateTime.now();
    final deadline = meetingDateTime.subtract(bookingDeadlineBeforeMeeting);
    return now.isBefore(deadline);
  }

  /// 현재 시간 기준으로 취소 가능한지 확인
  static bool canCancelBooking(DateTime meetingDateTime) {
    final now = DateTime.now();
    final deadline = meetingDateTime.subtract(cancellationDeadline);
    return now.isBefore(deadline);
  }

  /// 결제 후 경과 시간으로 쿨링오프 기간 내인지 확인
  static bool isInCoolingOffPeriod(DateTime paymentDateTime) {
    final now = DateTime.now();
    final deadline = paymentDateTime.add(coolingOffPeriod);
    return now.isBefore(deadline);
  }

  /// 현재 시간과 모임 시간을 기준으로 적용 가능한 환불 정책 조회
  static RefundPolicy? getApplicableRefundPolicy(
    DateTime meetingDateTime,
    DateTime paymentDateTime,
  ) {
    final now = DateTime.now();

    // 1. 쿨링오프 기간 확인
    if (isInCoolingOffPeriod(paymentDateTime)) {
      return refundPolicies.firstWhere(
        (policy) => policy.condition == RefundCondition.coolingOff,
      );
    }

    // 2. 모임 시작 시간까지 남은 시간 계산
    final timeToMeeting = meetingDateTime.difference(now);

    // 3. 해당하는 정책 찾기 (가장 관대한 정책부터 확인)
    for (final policy in refundPolicies) {
      if (policy.condition == RefundCondition.coolingOff) continue;

      if (policy.daysBeforeMeeting != null) {
        final requiredDays = Duration(days: policy.daysBeforeMeeting!);
        if (timeToMeeting >= requiredDays) {
          return policy;
        }
      } else if (policy.hoursBeforeMeeting != null) {
        final requiredHours = Duration(hours: policy.hoursBeforeMeeting!);
        if (timeToMeeting >= requiredHours) {
          return policy;
        }
      }
    }

    // 4. 해당하는 정책이 없으면 환불 불가
    return refundPolicies.lastWhere(
      (policy) => policy.condition == RefundCondition.noRefund,
    );
  }

  /// 환불 금액 계산
  static double calculateRefundAmount(
    double originalAmount,
    double refundRate,
  ) {
    return originalAmount * refundRate;
  }

  /// 환불 정책 설명 텍스트 생성
  static String getRefundPolicyDescription() {
    final buffer = StringBuffer();
    buffer.writeln('=== 환불 정책 안내 ===\n');

    buffer.writeln('📌 전액 환불 (100%)');
    buffer.writeln('• 결제 후 30분 이내');
    buffer.writeln('• 모임 시작 4일 전까지');
    buffer.writeln('• 호스트에 의한 모임 취소');
    buffer.writeln('• 승인 거절 또는 시스템 오류\n');

    buffer.writeln('📌 부분 환불');
    buffer.writeln('• 모임 시작 3일 전까지: 90% 환불');
    buffer.writeln('• 모임 시작 1일 전까지: 50% 환불\n');

    buffer.writeln('📌 환불 불가');
    buffer.writeln('• 모임 시작 3시간 전부터');
    buffer.writeln('• 모임 진행 중 또는 완료 후\n');

    buffer.writeln('⚠️ 환불 처리는 $refundProcessingDays 소요됩니다.');
    buffer.writeln('📞 문의: $customerServicePhone ($serviceHours)');

    return buffer.toString();
  }
}

/// 환불 정책 정보 클래스
class RefundPolicy {
  final String name;
  final String description;
  final int? daysBeforeMeeting;
  final int? hoursBeforeMeeting;
  final double refundRate; // 0.0 ~ 1.0
  final RefundCondition condition;

  const RefundPolicy({
    required this.name,
    required this.description,
    this.daysBeforeMeeting,
    this.hoursBeforeMeeting,
    required this.refundRate,
    required this.condition,
  });

  /// 환불율을 퍼센트로 표시
  String get refundRatePercent => '${(refundRate * 100).toInt()}%';

  /// 환불 가능 여부
  bool get canRefund => refundRate > 0;
}

/// 환불 조건 타입
enum RefundCondition {
  coolingOff, // 쿨링오프 기간
  beforeDeadline, // 마감일 이전
  noRefund, // 환불 불가
}
