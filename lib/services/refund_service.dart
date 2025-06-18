import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/refund_request.dart';
import '../models/booking.dart';
import '../models/meeting.dart';

class RefundService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 환불 요청 생성
  Future<String> createRefundRequest({
    required String bookingId,
    required String userId,
    required String meetingId,
    required double amount,
    required RefundReason reason,
    String? reasonDetail,
    required String bookingNumber,
    required String userName,
    required String meetingTitle,
  }) async {
    try {
      // 중복 환불 요청 확인
      final existingRequest = await _firestore
          .collection('refund_requests')
          .where('bookingId', isEqualTo: bookingId)
          .where('status', whereIn: ['pending', 'approved'])
          .get();

      if (existingRequest.docs.isNotEmpty) {
        throw Exception('이미 환불 요청이 진행 중입니다.');
      }

      final refundRequest = RefundRequest(
        id: '',
        bookingId: bookingId,
        userId: userId,
        meetingId: meetingId,
        amount: amount,
        reason: reason,
        reasonDetail: reasonDetail,
        status: RefundStatus.pending,
        requestedAt: DateTime.now(),
        bookingNumber: bookingNumber,
        userName: userName,
        meetingTitle: meetingTitle,
      );

      final docRef = await _firestore
          .collection('refund_requests')
          .add(refundRequest.toFirestore());

      // 예약 상태를 환불 요청 중으로 변경
      await _firestore.collection('bookings').doc(bookingId).update({
        'refundRequested': true,
      });

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('환불 요청 생성 오류: $e');
      }
      rethrow;
    }
  }

  // 사용자의 환불 요청 목록 조회
  Stream<List<RefundRequest>> getUserRefundRequests(String userId) {
    return _firestore
        .collection('refund_requests')
        .where('userId', isEqualTo: userId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RefundRequest.fromFirestore(doc))
              .toList(),
        );
  }

  // 모든 환불 요청 조회 (관리자용)
  Stream<List<RefundRequest>> getAllRefundRequests() {
    return _firestore
        .collection('refund_requests')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RefundRequest.fromFirestore(doc))
              .toList(),
        );
  }

  // 환불 승인 (관리자용)
  Future<void> approveRefund(String refundRequestId, String adminId) async {
    try {
      await _firestore
          .collection('refund_requests')
          .doc(refundRequestId)
          .update({
            'status': RefundStatus.approved.name,
            'processedAt': FieldValue.serverTimestamp(),
            'processedBy': adminId,
          });

      // 실제 환불 처리 로직 (PG사 연동)
      // 여기서는 시뮬레이션으로 바로 완료 상태로 변경
      await Future.delayed(const Duration(seconds: 2));

      await _firestore
          .collection('refund_requests')
          .doc(refundRequestId)
          .update({'status': RefundStatus.completed.name});
    } catch (e) {
      if (kDebugMode) {
        print('환불 승인 오류: $e');
      }
      rethrow;
    }
  }

  // 환불 거절 (관리자용)
  Future<void> rejectRefund(
    String refundRequestId,
    String adminId,
    String rejectionReason,
  ) async {
    try {
      await _firestore
          .collection('refund_requests')
          .doc(refundRequestId)
          .update({
            'status': RefundStatus.rejected.name,
            'processedAt': FieldValue.serverTimestamp(),
            'processedBy': adminId,
            'rejectionReason': rejectionReason,
          });

      // 예약 상태 복구
      final refundDoc = await _firestore
          .collection('refund_requests')
          .doc(refundRequestId)
          .get();
      final refund = RefundRequest.fromFirestore(refundDoc);

      await _firestore.collection('bookings').doc(refund.bookingId).update({
        'refundRequested': false,
      });
    } catch (e) {
      if (kDebugMode) {
        print('환불 거절 오류: $e');
      }
      rethrow;
    }
  }

  // 환불 가능 여부 확인
  Future<bool> canRequestRefund(Booking booking, Meeting meeting) async {
    try {
      // 이미 환불 요청이 있는지 확인
      final existingRequest = await _firestore
          .collection('refund_requests')
          .where('bookingId', isEqualTo: booking.id)
          .where('status', whereIn: ['pending', 'approved'])
          .get();

      if (existingRequest.docs.isNotEmpty) {
        return false;
      }

      // 예약 상태 확인
      if (booking.status == BookingStatus.cancelled ||
          booking.status == BookingStatus.completed) {
        return false;
      }

      // 모임 시작 시간 기준으로 환불 가능 여부 확인
      final now = DateTime.now();
      final refundDeadline = meeting.scheduledDate.subtract(
        const Duration(days: 3),
      );

      // 환불 가능 기간 확인 (모임 3일 전까지)
      if (now.isAfter(refundDeadline)) {
        return false;
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('환불 가능 여부 확인 오류: $e');
      }
      return false;
    }
  }

  // 자동 환불 처리 (모임 취소 시)
  Future<void> processAutomaticRefund({
    required String meetingId,
    required RefundReason reason,
  }) async {
    try {
      // 해당 모임의 모든 예약 조회
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('meetingId', isEqualTo: meetingId)
          .where('status', whereIn: ['confirmed', 'approved'])
          .get();

      for (final bookingDoc in bookingsSnapshot.docs) {
        final booking = Booking.fromFirestore(bookingDoc);

        // 자동 환불 요청 생성
        await createRefundRequest(
          bookingId: booking.id,
          userId: booking.userId,
          meetingId: booking.meetingId,
          amount: booking.amount,
          reason: reason,
          reasonDetail: '모임 자동 취소로 인한 전액 환불',
          bookingNumber: booking.bookingNumber,
          userName: booking.userName,
          meetingTitle: '취소된 모임',
        );

        // 자동으로 승인 처리
        final refundRequests = await _firestore
            .collection('refund_requests')
            .where('bookingId', isEqualTo: booking.id)
            .where('status', isEqualTo: 'pending')
            .get();

        for (final refundDoc in refundRequests.docs) {
          await approveRefund(refundDoc.id, 'system');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('자동 환불 처리 오류: $e');
      }
      rethrow;
    }
  }

  // 환불 통계 조회 (관리자용)
  Future<Map<String, dynamic>> getRefundStatistics() async {
    try {
      final snapshot = await _firestore.collection('refund_requests').get();

      int totalRequests = snapshot.docs.length;
      int pendingRequests = 0;
      int approvedRequests = 0;
      int rejectedRequests = 0;
      int completedRequests = 0;
      double totalRefundAmount = 0;

      for (final doc in snapshot.docs) {
        final refund = RefundRequest.fromFirestore(doc);

        switch (refund.status) {
          case RefundStatus.pending:
            pendingRequests++;
            break;
          case RefundStatus.approved:
            approvedRequests++;
            break;
          case RefundStatus.rejected:
            rejectedRequests++;
            break;
          case RefundStatus.completed:
            completedRequests++;
            totalRefundAmount += refund.amount;
            break;
        }
      }

      return {
        'totalRequests': totalRequests,
        'pendingRequests': pendingRequests,
        'approvedRequests': approvedRequests,
        'rejectedRequests': rejectedRequests,
        'completedRequests': completedRequests,
        'totalRefundAmount': totalRefundAmount,
      };
    } catch (e) {
      if (kDebugMode) {
        print('환불 통계 조회 오류: $e');
      }
      return {};
    }
  }
}
