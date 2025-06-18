import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum RefundStatus {
  pending, // 환불 요청 중
  approved, // 환불 승인
  rejected, // 환불 거절
  completed, // 환불 완료
}

enum RefundReason {
  meetingCancellation, // 모임 취소
  hostKickout, // 호스트에 의한 내보내기
  beforeDeadline, // 환불 가능 기간 내 취소
  systemError, // 시스템 오류
  paymentError, // 결제 오류
  other, // 기타
}

class RefundRequest {
  final String id;
  final String bookingId;
  final String userId;
  final String meetingId;
  final double amount; // 환불 금액
  final RefundReason reason; // 환불 사유
  final String? reasonDetail; // 상세 사유
  final RefundStatus status;
  final DateTime requestedAt; // 환불 요청 날짜
  final DateTime? processedAt; // 처리 날짜
  final String? processedBy; // 처리자 (관리자 ID)
  final String? rejectionReason; // 거절 사유
  final String bookingNumber; // 예약 번호
  final String userName; // 사용자 이름
  final String meetingTitle; // 모임 제목

  RefundRequest({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.meetingId,
    required this.amount,
    required this.reason,
    this.reasonDetail,
    required this.status,
    required this.requestedAt,
    this.processedAt,
    this.processedBy,
    this.rejectionReason,
    required this.bookingNumber,
    required this.userName,
    required this.meetingTitle,
  });

  factory RefundRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return RefundRequest(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      userId: data['userId'] ?? '',
      meetingId: data['meetingId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      reason: _parseReason(data['reason']),
      reasonDetail: data['reasonDetail'],
      status: _parseStatus(data['status']),
      requestedAt: (data['requestedAt'] as Timestamp).toDate(),
      processedAt: data['processedAt'] != null
          ? (data['processedAt'] as Timestamp).toDate()
          : null,
      processedBy: data['processedBy'],
      rejectionReason: data['rejectionReason'],
      bookingNumber: data['bookingNumber'] ?? '',
      userName: data['userName'] ?? '',
      meetingTitle: data['meetingTitle'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'userId': userId,
      'meetingId': meetingId,
      'amount': amount,
      'reason': reason.name,
      'reasonDetail': reasonDetail,
      'status': status.name,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'processedAt': processedAt != null
          ? Timestamp.fromDate(processedAt!)
          : null,
      'processedBy': processedBy,
      'rejectionReason': rejectionReason,
      'bookingNumber': bookingNumber,
      'userName': userName,
      'meetingTitle': meetingTitle,
    };
  }

  static RefundStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return RefundStatus.pending;
      case 'approved':
        return RefundStatus.approved;
      case 'rejected':
        return RefundStatus.rejected;
      case 'completed':
        return RefundStatus.completed;
      default:
        return RefundStatus.pending;
    }
  }

  static RefundReason _parseReason(String? reason) {
    switch (reason) {
      case 'meetingCancellation':
        return RefundReason.meetingCancellation;
      case 'hostKickout':
        return RefundReason.hostKickout;
      case 'beforeDeadline':
        return RefundReason.beforeDeadline;
      case 'systemError':
        return RefundReason.systemError;
      case 'paymentError':
        return RefundReason.paymentError;
      case 'other':
        return RefundReason.other;
      default:
        return RefundReason.other;
    }
  }

  String get statusText {
    switch (status) {
      case RefundStatus.pending:
        return '환불 요청 중';
      case RefundStatus.approved:
        return '환불 승인';
      case RefundStatus.rejected:
        return '환불 거절';
      case RefundStatus.completed:
        return '환불 완료';
    }
  }

  Color get statusColor {
    switch (status) {
      case RefundStatus.pending:
        return const Color(0xFFFFA726);
      case RefundStatus.approved:
        return const Color(0xFF66BB6A);
      case RefundStatus.rejected:
        return const Color(0xFFEF5350);
      case RefundStatus.completed:
        return const Color(0xFF42A5F5);
    }
  }

  String get reasonText {
    switch (reason) {
      case RefundReason.meetingCancellation:
        return '모임 취소';
      case RefundReason.hostKickout:
        return '호스트에 의한 내보내기';
      case RefundReason.beforeDeadline:
        return '환불 가능 기간 내 취소';
      case RefundReason.systemError:
        return '시스템 오류';
      case RefundReason.paymentError:
        return '결제 오류';
      case RefundReason.other:
        return '기타';
    }
  }

  RefundRequest copyWith({
    String? id,
    String? bookingId,
    String? userId,
    String? meetingId,
    double? amount,
    RefundReason? reason,
    String? reasonDetail,
    RefundStatus? status,
    DateTime? requestedAt,
    DateTime? processedAt,
    String? processedBy,
    String? rejectionReason,
    String? bookingNumber,
    String? userName,
    String? meetingTitle,
  }) {
    return RefundRequest(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      meetingId: meetingId ?? this.meetingId,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      reasonDetail: reasonDetail ?? this.reasonDetail,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      processedAt: processedAt ?? this.processedAt,
      processedBy: processedBy ?? this.processedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      bookingNumber: bookingNumber ?? this.bookingNumber,
      userName: userName ?? this.userName,
      meetingTitle: meetingTitle ?? this.meetingTitle,
    );
  }
}
