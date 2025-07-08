import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../models/meeting.dart';
import 'firestore_service.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // 사용자의 예약 내역 가져오기
  Stream<List<Booking>> getUserBookings(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Booking> bookings = [];

          for (var doc in snapshot.docs) {
            try {
              Booking booking = Booking.fromFirestore(doc);

              // 각 예약에 대해 모임 정보를 가져옴
              try {
                Meeting? meeting = await _getMeetingById(booking.meetingId);
                if (meeting != null) {
                  booking = booking.copyWith(meeting: meeting);
                }
              } catch (e) {
                if (kDebugMode) {
                  print('Error loading meeting for booking ${booking.id}: $e');
                }
              }

              bookings.add(booking);
            } catch (e) {
              if (kDebugMode) {
                print('Error processing booking document ${doc.id}: $e');
              }
            }
          }

          return bookings;
        });
  }

  // 모임 ID로 모임 정보 가져오기
  Future<Meeting?> _getMeetingById(String meetingId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('meetings')
          .doc(meetingId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;

        if (data != null) {
          final meeting = Meeting.fromFirestore(doc);
          return meeting;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting meeting: $e');
      }
      return null;
    }
  }

  // 예약 생성 (결제 완료 시 호출)
  Future<String> createBooking({
    required String userId,
    required String meetingId,
    required DateTime bookingDate,
    required double amount,
    String? bookingNumber,
    String? userName,
  }) async {
    try {
      // 예약 번호가 없으면 자동 생성
      final finalBookingNumber =
          bookingNumber ?? 'BK${DateTime.now().millisecondsSinceEpoch}';

      // 사용자 이름이 없으면 기본값 사용
      final finalUserName = userName ?? '사용자';

      Booking booking = Booking(
        id: '', // Firestore에서 자동 생성
        userId: userId,
        meetingId: meetingId,
        bookingDate: bookingDate,
        createdAt: DateTime.now(),
        status: BookingStatus.confirmed, // 결제 완료 시 바로 확정
        bookingNumber: finalBookingNumber,
        amount: amount,
        userName: finalUserName,
      );

      DocumentReference docRef = await _firestore
          .collection('bookings')
          .add(booking.toFirestore());

      if (kDebugMode) {
        print('✅ 예약 생성 완료 - ID: ${docRef.id}, 예약번호: $finalBookingNumber');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 예약 생성 실패: $e');
      }
      throw Exception('예약 생성에 실패했습니다: $e');
    }
  }

  // 예약 취소
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.cancelled.name,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling booking: $e');
      }
      throw Exception('예약 취소에 실패했습니다: $e');
    }
  }

  // 예약 상태 업데이트
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status.name,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating booking status: $e');
      }
      throw Exception('예약 상태 업데이트에 실패했습니다: $e');
    }
  }

  // 사용자의 특정 모임 예약 여부 확인
  Future<Booking?> getUserBookingForMeeting(
    String userId,
    String meetingId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('meetingId', isEqualTo: meetingId)
          .where(
            'status',
            whereIn: ['confirmed', 'pending', 'approved', 'rejected'],
          )
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Booking.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 사용자 예약 확인 실패: $e');
      }
      return null;
    }
  }

  // 모든 예약 데이터 삭제 (테스트 전용)
  Future<void> deleteAllBookings() async {
    try {
      final snapshot = await _firestore.collection('bookings').get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      if (kDebugMode) {
        print('✅ 모든 예약 데이터가 삭제되었습니다.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 예약 데이터 삭제 실패: $e');
      }
      throw Exception('예약 데이터 삭제에 실패했습니다: $e');
    }
  }
}
