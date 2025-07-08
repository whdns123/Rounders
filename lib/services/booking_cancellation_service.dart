import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_cancellation.dart';
import '../config/booking_policy_config.dart';

class BookingCancellationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 예약 취소 요청
  Future<String> cancelBooking({
    required String bookingId,
    required String userId,
    required String meetingId,
    required String reason,
    String? customReason,
  }) async {
    try {
      // 트랜잭션으로 예약 취소 처리
      return await _firestore.runTransaction<String>((transaction) async {
        // === 1단계: 모든 READ 작업 먼저 실행 ===

        // 1-1. 예약 정보 읽기
        DocumentReference bookingRef = _firestore
            .collection('bookings')
            .doc(bookingId);
        DocumentSnapshot bookingSnapshot = await transaction.get(bookingRef);

        // 1-2. 모임 정보 읽기
        DocumentReference meetingRef = _firestore
            .collection('meetings')
            .doc(meetingId);
        DocumentSnapshot meetingSnapshot = await transaction.get(meetingRef);

        // === 2단계: READ 결과 검증 ===

        if (!bookingSnapshot.exists) {
          throw Exception('예약 정보를 찾을 수 없습니다.');
        }

        final bookingData = bookingSnapshot.data() as Map<String, dynamic>;
        if (bookingData['userId'] != userId) {
          throw Exception('본인의 예약만 취소할 수 있습니다.');
        }

        if (bookingData['status'] == 'cancelled') {
          throw Exception('이미 취소된 예약입니다.');
        }

        // === 3단계: 모든 WRITE 작업 실행 ===

        // 3-1. 취소 정보 생성 및 저장
        DocumentReference cancellationRef = _firestore
            .collection('booking_cancellations')
            .doc();

        final cancellation = BookingCancellation(
          id: cancellationRef.id,
          bookingId: bookingId,
          userId: userId,
          meetingId: meetingId,
          reason: reason,
          customReason: customReason,
          cancelledAt: DateTime.now(),
          status: 'requested',
          refundAmount: (bookingData['amount'] ?? 0.0).toDouble(),
          refundStatus: 'pending',
        );

        transaction.set(cancellationRef, cancellation.toFirestore());

        // 3-2. 예약 상태를 취소로 변경
        transaction.update(bookingRef, {
          'status': 'cancelled',
          'cancelledAt': Timestamp.fromDate(DateTime.now()),
          'cancellationId': cancellationRef.id,
        });

        // 3-3. 모임의 현재 참가자 수 감소
        if (meetingSnapshot.exists) {
          final meetingData = meetingSnapshot.data() as Map<String, dynamic>;
          final currentParticipants = meetingData['currentParticipants'] ?? 0;

          transaction.update(meetingRef, {
            'currentParticipants': (currentParticipants - 1)
                .clamp(0, double.infinity)
                .toInt(),
          });
        }

        return cancellationRef.id;
      });
    } catch (e) {
      print('Error cancelling booking: $e');
      rethrow;
    }
  }

  // 사용자의 취소 내역 조회
  Stream<List<BookingCancellation>> getUserCancellations(String userId) {
    return _firestore
        .collection('booking_cancellations')
        .where('userId', isEqualTo: userId)
        .orderBy('cancelledAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BookingCancellation.fromFirestore(doc))
              .toList(),
        );
  }

  // 특정 예약의 취소 정보 조회
  Future<BookingCancellation?> getCancellationByBookingId(
    String bookingId,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('booking_cancellations')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return BookingCancellation.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting cancellation: $e');
      return null;
    }
  }

  // 예약 취소 가능 여부 확인
  Future<Map<String, dynamic>> checkCancellationPolicy(String bookingId) async {
    try {
      // 예약 정보 조회
      DocumentSnapshot bookingSnapshot = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!bookingSnapshot.exists) {
        return {'canCancel': false, 'reason': '예약 정보를 찾을 수 없습니다.'};
      }

      final bookingData = bookingSnapshot.data() as Map<String, dynamic>;

      if (bookingData['status'] == 'cancelled') {
        return {'canCancel': false, 'reason': '이미 취소된 예약입니다.'};
      }

      if (bookingData['status'] == 'completed') {
        return {'canCancel': false, 'reason': '완료된 예약은 취소할 수 없습니다.'};
      }

      // 모임 정보 조회
      DocumentSnapshot meetingSnapshot = await _firestore
          .collection('meetings')
          .doc(bookingData['meetingId'])
          .get();

      if (meetingSnapshot.exists) {
        final meetingData = meetingSnapshot.data() as Map<String, dynamic>;
        final scheduledDate = (meetingData['scheduledDate'] as Timestamp)
            .toDate();
        final paymentDate = (bookingData['createdAt'] as Timestamp).toDate();

        // 새로운 정책 설정을 사용하여 취소 가능 여부 확인
        if (!BookingPolicyConfig.canCancelBooking(scheduledDate)) {
          final deadlineHours =
              BookingPolicyConfig.cancellationDeadline.inHours;
          return {
            'canCancel': false,
            'reason': '모임 시작 ${deadlineHours}시간 전까지만 취소할 수 있습니다.',
          };
        }

        // 환불 정책 확인
        final refundPolicy = BookingPolicyConfig.getApplicableRefundPolicy(
          scheduledDate,
          paymentDate,
        );

        if (refundPolicy == null) {
          return {'canCancel': false, 'reason': '환불 정책을 확인할 수 없습니다.'};
        }

        final originalAmount = (bookingData['amount'] ?? 0.0).toDouble();
        final refundAmount = BookingPolicyConfig.calculateRefundAmount(
          originalAmount,
          refundPolicy.refundRate,
        );

        return {
          'canCancel': true,
          'reason': null,
          'refundAmount': refundAmount,
          'originalAmount': originalAmount,
          'refundRate': refundPolicy.refundRate,
          'refundPolicy': refundPolicy.name,
          'policyDescription': refundPolicy.description,
          'meetingDate': scheduledDate,
        };
      }

      return {'canCancel': false, 'reason': '모임 정보를 찾을 수 없습니다.'};
    } catch (e) {
      print('Error checking cancellation policy: $e');
      return {'canCancel': false, 'reason': '취소 정책 확인 중 오류가 발생했습니다.'};
    }
  }
}
