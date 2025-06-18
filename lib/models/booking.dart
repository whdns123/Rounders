import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'meeting.dart';

enum BookingStatus {
  confirmed, // 예약 확정
  pending, // 승인 대기중
  cancelled, // 예약 취소
  completed, // 완료
  approved, // 승인됨
  rejected, // 거절됨
}

class Booking {
  final String id;
  final String userId;
  final String meetingId;
  final Meeting? meeting; // 모임 정보
  final DateTime bookingDate; // 예약한 날짜
  final DateTime createdAt; // 예약 생성 날짜
  final BookingStatus status;
  final String bookingNumber;
  final double amount; // 결제 금액
  final String userName; // 사용자 이름
  final int? rank; // 순위 (게임 완료 후)

  Booking({
    required this.id,
    required this.userId,
    required this.meetingId,
    this.meeting,
    required this.bookingDate,
    required this.createdAt,
    required this.status,
    required this.bookingNumber,
    required this.amount,
    required this.userName,
    this.rank,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      meetingId: data['meetingId'] ?? '',
      meeting: null, // 별도로 로드해야 함
      bookingDate: (data['bookingDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: _parseStatus(data['status']),
      bookingNumber: data['bookingNumber'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      userName: data['userName'] ?? '',
      rank: data['rank'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'meetingId': meetingId,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.name,
      'bookingNumber': bookingNumber,
      'amount': amount,
      'userName': userName,
      'rank': rank,
    };
  }

  static BookingStatus _parseStatus(String? status) {
    switch (status) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'pending':
        return BookingStatus.pending;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'completed':
        return BookingStatus.completed;
      case 'approved':
        return BookingStatus.approved;
      case 'rejected':
        return BookingStatus.rejected;
      default:
        return BookingStatus.pending;
    }
  }

  String get statusText {
    switch (status) {
      case BookingStatus.confirmed:
        return '예약 확정';
      case BookingStatus.pending:
        return '승인 대기중';
      case BookingStatus.cancelled:
        return '예약 취소';
      case BookingStatus.completed:
        return '완료';
      case BookingStatus.approved:
        return '승인됨';
      case BookingStatus.rejected:
        return '거절됨';
    }
  }

  Color get statusColor {
    switch (status) {
      case BookingStatus.confirmed:
        return const Color(0xFFF44336);
      case BookingStatus.pending:
        return const Color(0xFFF44336);
      case BookingStatus.cancelled:
        return const Color(0xFFEAEAEA);
      case BookingStatus.completed:
        return const Color(0xFF4CAF50);
      case BookingStatus.approved:
        return const Color(0xFF4CAF50);
      case BookingStatus.rejected:
        return const Color(0xFFF44336);
    }
  }

  Color get statusTextColor {
    switch (status) {
      case BookingStatus.confirmed:
        return const Color(0xFFEAEAEA);
      case BookingStatus.pending:
        return const Color(0xFFEAEAEA);
      case BookingStatus.cancelled:
        return const Color(0xFF4B4B4B);
      case BookingStatus.completed:
        return const Color(0xFFEAEAEA);
      case BookingStatus.approved:
        return const Color(0xFFEAEAEA);
      case BookingStatus.rejected:
        return const Color(0xFFEAEAEA);
    }
  }

  // 복사본 생성 (meeting 정보 추가용)
  Booking copyWith({
    String? id,
    String? userId,
    String? meetingId,
    Meeting? meeting,
    DateTime? bookingDate,
    DateTime? createdAt,
    BookingStatus? status,
    String? bookingNumber,
    double? amount,
    String? userName,
    int? rank,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      meetingId: meetingId ?? this.meetingId,
      meeting: meeting ?? this.meeting,
      bookingDate: bookingDate ?? this.bookingDate,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      bookingNumber: bookingNumber ?? this.bookingNumber,
      amount: amount ?? this.amount,
      userName: userName ?? this.userName,
      rank: rank ?? this.rank,
    );
  }
}
