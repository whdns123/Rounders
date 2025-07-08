import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/refund_request.dart';
import '../models/booking.dart';
import '../models/meeting.dart';
import '../config/booking_policy_config.dart';

/// 개선된 환불 서비스
class EnhancedRefundService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 환불 가능 여부 및 금액 확인
  Future<Map<String, dynamic>> checkRefundEligibility({
    required Booking booking,
    required Meeting meeting,
  }) async {
    try {
      // 1. 기본 검증
      if (booking.status == BookingStatus.cancelled ||
          booking.status == BookingStatus.completed) {
        return {
          'canRefund': false,
          'reason': '이미 취소되었거나 완료된 예약입니다.',
          'refundAmount': 0.0,
          'refundRate': 0.0,
        };
      }

      // 2. 환불 정책 적용
      final refundPolicy = BookingPolicyConfig.getApplicableRefundPolicy(
        meeting.scheduledDate,
        booking.createdAt,
      );

      if (refundPolicy == null || !refundPolicy.canRefund) {
        return {
          'canRefund': false,
          'reason': '환불 가능 기간이 지났습니다.',
          'refundAmount': 0.0,
          'refundRate': 0.0,
        };
      }

      // 3. 환불 금액 계산
      final refundAmount = BookingPolicyConfig.calculateRefundAmount(
        booking.amount,
        refundPolicy.refundRate,
      );

      return {
        'canRefund': true,
        'reason': null,
        'refundAmount': refundAmount,
        'refundRate': refundPolicy.refundRate,
        'policy': refundPolicy,
        'originalAmount': booking.amount,
      };
    } catch (e) {
      if (kDebugMode) {
        print('환불 가능 여부 확인 오류: $e');
      }
      return {
        'canRefund': false,
        'reason': '환불 정책 확인 중 오류가 발생했습니다.',
        'refundAmount': 0.0,
        'refundRate': 0.0,
      };
    }
  }

  /// 환불 처리 시뮬레이션
  Future<Map<String, dynamic>> simulateRefund({
    required DateTime meetingDate,
    required DateTime paymentDate,
    required double originalAmount,
  }) async {
    final policy = BookingPolicyConfig.getApplicableRefundPolicy(
      meetingDate,
      paymentDate,
    );

    if (policy == null) {
      return {'canRefund': false, 'refundAmount': 0.0, 'policy': '해당 없음'};
    }

    final refundAmount = BookingPolicyConfig.calculateRefundAmount(
      originalAmount,
      policy.refundRate,
    );

    return {
      'canRefund': policy.canRefund,
      'refundAmount': refundAmount,
      'policy': policy.description,
      'refundRate': policy.refundRatePercent,
      'originalAmount': originalAmount,
    };
  }
}
