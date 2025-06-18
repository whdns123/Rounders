import 'package:cloud_firestore/cloud_firestore.dart';

class BookingCancellation {
  final String id;
  final String bookingId;
  final String userId;
  final String meetingId;
  final String reason;
  final String? customReason; // 기타 사유일 때 직접 입력한 내용
  final DateTime cancelledAt;
  final String status; // 'requested', 'approved', 'rejected'
  final double refundAmount;
  final String? refundStatus; // 'pending', 'processed', 'failed'

  BookingCancellation({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.meetingId,
    required this.reason,
    this.customReason,
    required this.cancelledAt,
    this.status = 'requested',
    this.refundAmount = 0.0,
    this.refundStatus,
  });

  // Firestore에서 BookingCancellation 객체 생성
  factory BookingCancellation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime parsedDate;
    if (data['cancelledAt'] is Timestamp) {
      parsedDate = (data['cancelledAt'] as Timestamp).toDate();
    } else if (data['cancelledAt'] is DateTime) {
      parsedDate = data['cancelledAt'] as DateTime;
    } else {
      parsedDate = DateTime.now();
    }

    return BookingCancellation(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      userId: data['userId'] ?? '',
      meetingId: data['meetingId'] ?? '',
      reason: data['reason'] ?? '',
      customReason: data['customReason'],
      cancelledAt: parsedDate,
      status: data['status'] ?? 'requested',
      refundAmount: (data['refundAmount'] ?? 0.0).toDouble(),
      refundStatus: data['refundStatus'],
    );
  }

  // BookingCancellation 객체를 Firestore 문서로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'userId': userId,
      'meetingId': meetingId,
      'reason': reason,
      'customReason': customReason,
      'cancelledAt': Timestamp.fromDate(cancelledAt),
      'status': status,
      'refundAmount': refundAmount,
      'refundStatus': refundStatus,
    };
  }

  // 취소 사유 옵션들
  static const List<String> cancellationReasons = [
    '개인 사정이 생겼어요',
    '건강 문제로 참석이 어려워요',
    '일정이 겹쳐서 참여가 불가능해요',
    '위치/시간이 맞지 않아요',
    '기대와 달라서 취소하고 싶어요',
    '함께하려던 사람이 취소했어요',
    '모임 정보가 부족해요',
    '기타(직접입력)',
  ];

  BookingCancellation copyWith({
    String? id,
    String? bookingId,
    String? userId,
    String? meetingId,
    String? reason,
    String? customReason,
    DateTime? cancelledAt,
    String? status,
    double? refundAmount,
    String? refundStatus,
  }) {
    return BookingCancellation(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      meetingId: meetingId ?? this.meetingId,
      reason: reason ?? this.reason,
      customReason: customReason ?? this.customReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      status: status ?? this.status,
      refundAmount: refundAmount ?? this.refundAmount,
      refundStatus: refundStatus ?? this.refundStatus,
    );
  }
}
