import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 호스트에게 예약 취소 알림 전송
  Future<void> notifyHostOfCancellation({
    required String hostId,
    required String meetingId,
    required String meetingTitle,
    required String userName,
    required String bookingNumber,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': hostId,
        'type': 'booking_cancelled',
        'title': '예약 취소 알림',
        'message': '$userName님이 "$meetingTitle" 모임 예약을 취소했습니다.',
        'data': {
          'meetingId': meetingId,
          'meetingTitle': meetingTitle,
          'bookingNumber': bookingNumber,
          'userName': userName,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ 호스트 알림 전송 완료: $hostId');
    } catch (e) {
      print('❌ 호스트 알림 전송 실패: $e');
      throw Exception('호스트 알림 전송에 실패했습니다: $e');
    }
  }

  // 사용자에게 예약 취소 완료 알림 전송
  Future<void> notifyUserOfCancellationComplete({
    required String userId,
    required String meetingTitle,
    required String bookingNumber,
    required bool refundProcessed,
  }) async {
    try {
      final message = refundProcessed
          ? '"$meetingTitle" 모임 예약이 취소되었으며, 환불이 완료되었습니다.'
          : '"$meetingTitle" 모임 예약이 취소되었습니다.';

      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'booking_cancellation_complete',
        'title': '예약 취소 완료',
        'message': message,
        'data': {
          'meetingTitle': meetingTitle,
          'bookingNumber': bookingNumber,
          'refundProcessed': refundProcessed,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ 사용자 취소 완료 알림 전송 완료: $userId');
    } catch (e) {
      print('❌ 사용자 취소 완료 알림 전송 실패: $e');
    }
  }

  // 사용자의 알림 목록 조회
  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  // 알림 읽음 처리
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print('알림 읽음 처리 실패: $e');
    }
  }

  // 모든 알림 읽음 처리
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('전체 알림 읽음 처리 실패: $e');
    }
  }
}
