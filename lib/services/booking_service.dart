import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';
import '../models/meeting.dart';
import 'firestore_service.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // 사용자의 예약 내역 가져오기
  Stream<List<Booking>> getUserBookings(String userId) {
    print('Getting user bookings for userId: $userId'); // 디버깅 로그

    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          print('Found ${snapshot.docs.length} booking documents'); // 디버깅 로그

          List<Booking> bookings = [];

          for (var doc in snapshot.docs) {
            try {
              print('Processing booking document: ${doc.id}'); // 디버깅 로그

              Booking booking = Booking.fromFirestore(doc);
              print(
                'Created booking: ${booking.id}, meetingId: ${booking.meetingId}',
              ); // 디버깅 로그

              // 각 예약에 대해 모임 정보를 가져옴
              try {
                Meeting? meeting = await _getMeetingById(booking.meetingId);
                if (meeting != null) {
                  booking = booking.copyWith(meeting: meeting);
                  print(
                    'Successfully attached meeting to booking: ${meeting.title}',
                  ); // 디버깅 로그
                } else {
                  print(
                    'Meeting not found for booking ${booking.id}, meetingId: ${booking.meetingId}',
                  ); // 디버깅 로그
                }
              } catch (e) {
                print('Error loading meeting for booking ${booking.id}: $e');
              }

              bookings.add(booking);
            } catch (e) {
              print('Error processing booking document ${doc.id}: $e');
            }
          }

          print('Returning ${bookings.length} bookings'); // 디버깅 로그
          return bookings;
        });
  }

  // 모임 ID로 모임 정보 가져오기
  Future<Meeting?> _getMeetingById(String meetingId) async {
    try {
      print('Getting meeting by ID: $meetingId'); // 디버깅 로그

      DocumentSnapshot doc = await _firestore
          .collection('meetings')
          .doc(meetingId)
          .get();

      print('Meeting document exists: ${doc.exists}'); // 디버깅 로그

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        print('Meeting data: $data'); // 디버깅 로그

        if (data != null) {
          final meeting = Meeting.fromFirestore(doc);
          print('Successfully created meeting: ${meeting.title}'); // 디버깅 로그
          return meeting;
        } else {
          print('Meeting document data is null');
          return null;
        }
      } else {
        print('Meeting document does not exist for ID: $meetingId');
        return null;
      }
    } catch (e) {
      print('Error getting meeting: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // 예약 생성 (결제 완료 시 호출)
  Future<String> createBooking({
    required String userId,
    required String meetingId,
    required DateTime bookingDate,
    required double amount,
  }) async {
    try {
      // 예약 번호 생성 (현재 시간 기반)
      String bookingNumber = 'BK${DateTime.now().millisecondsSinceEpoch}';

      Booking booking = Booking(
        id: '', // Firestore에서 자동 생성
        userId: userId,
        meetingId: meetingId,
        bookingDate: bookingDate,
        createdAt: DateTime.now(),
        status: BookingStatus.pending, // 기본적으로 승인 대기중
        bookingNumber: bookingNumber,
        amount: amount,
        userName: '사용자', // 기본값, 실제로는 사용자 정보에서 가져와야 함
      );

      DocumentReference docRef = await _firestore
          .collection('bookings')
          .add(booking.toFirestore());

      return docRef.id;
    } catch (e) {
      print('Error creating booking: $e');
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
      print('Error cancelling booking: $e');
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
      print('Error updating booking status: $e');
      throw Exception('예약 상태 업데이트에 실패했습니다: $e');
    }
  }

  // 샘플 예약 데이터 추가 (테스트용)
  Future<void> addSampleBookings(String userId) async {
    try {
      // 먼저 샘플 모임 데이터 추가
      List<String> meetingIds = await _addSampleMeetings();

      List<Map<String, dynamic>> sampleBookings = [
        {
          'userId': userId,
          'meetingId': meetingIds[0],
          'bookingDate': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 7, hours: 18, minutes: 30)),
          ),
          'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 2)),
          ),
          'status': BookingStatus.confirmed.name,
          'bookingNumber': 'BK${DateTime.now().millisecondsSinceEpoch}1',
          'amount': 15000.0,
          'userName': '김사용자',
        },
        {
          'userId': userId,
          'meetingId': meetingIds[1],
          'bookingDate': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 14, hours: 19, minutes: 0)),
          ),
          'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 5)),
          ),
          'status': BookingStatus.pending.name,
          'bookingNumber': 'BK${DateTime.now().millisecondsSinceEpoch}2',
          'amount': 20000.0,
          'userName': '이사용자',
        },
        {
          'userId': userId,
          'meetingId': meetingIds[2],
          'bookingDate': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 3, hours: 17, minutes: 0)),
          ),
          'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 1)),
          ),
          'status': BookingStatus.confirmed.name,
          'bookingNumber': 'BK${DateTime.now().millisecondsSinceEpoch}3',
          'amount': 18000.0,
          'userName': '박사용자',
        },
        {
          'userId': userId,
          'meetingId': meetingIds[0],
          'bookingDate': Timestamp.fromDate(
            DateTime.now().subtract(
              const Duration(days: 10, hours: 2, minutes: 30),
            ),
          ),
          'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 12)),
          ),
          'status': BookingStatus.cancelled.name,
          'bookingNumber': 'BK${DateTime.now().millisecondsSinceEpoch}4',
          'amount': 15000.0,
          'userName': '최사용자',
        },
      ];

      for (var booking in sampleBookings) {
        await _firestore.collection('bookings').add(booking);
      }
    } catch (e) {
      print('Error adding sample bookings: $e');
      throw Exception('샘플 예약 데이터 추가에 실패했습니다: $e');
    }
  }

  // 샘플 모임 데이터 추가
  Future<List<String>> _addSampleMeetings() async {
    List<String> meetingIds = [];

    List<Map<String, dynamic>> sampleMeetings = [
      {
        'title': '강남 방탈출 체험',
        'description': '친구들과 함께하는 스릴 넘치는 방탈출 게임',
        'location': '강남역 3번 출구',
        'price': 15000.0,
        'maxParticipants': 6,
        'currentParticipants': 4,
        'scheduledDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7, hours: 18, minutes: 30)),
        ),
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 3)),
        ),
        'hostId': 'sample_host_1',
        'hostName': '김호스트',
        'category': '방탈출',
        'status': 'recruiting',
        'difficulty': '중급',
        'participants': [],
        'isCompleted': false,
        'hasResults': false,
        'imageUrls': [],
        'requiredLevel': '모두',
        'isActive': true,
        'tags': ['방탈출', '추리'],
        'rating': 4.5,
        'reviewCount': 20,
        'minParticipants': 2,
      },
      {
        'title': '홍대 보드게임 카페',
        'description': '다양한 보드게임으로 즐거운 시간을!',
        'location': '홍대입구역 2번 출구',
        'price': 20000.0,
        'maxParticipants': 8,
        'currentParticipants': 3,
        'scheduledDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 14, hours: 19, minutes: 0)),
        ),
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 7)),
        ),
        'hostId': 'sample_host_2',
        'hostName': '이호스트',
        'category': '게임',
        'status': 'recruiting',
        'difficulty': '초급',
        'participants': [],
        'isCompleted': false,
        'hasResults': false,
        'imageUrls': [],
        'requiredLevel': '모두',
        'isActive': true,
        'tags': ['보드게임', '친목'],
        'rating': 4.7,
        'reviewCount': 100,
        'minParticipants': 4,
      },
      {
        'title': '종로 미션 게임',
        'description': '도심 속 숨겨진 미션을 해결해보세요',
        'location': '종로3가역 1번 출구',
        'price': 18000.0,
        'maxParticipants': 10,
        'currentParticipants': 7,
        'scheduledDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 3, hours: 17, minutes: 0)),
        ),
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 2)),
        ),
        'hostId': 'sample_host_3',
        'hostName': '박호스트',
        'category': '미션',
        'status': 'recruiting',
        'difficulty': '고급',
        'participants': [],
        'isCompleted': false,
        'hasResults': false,
        'imageUrls': [],
        'requiredLevel': '모두',
        'isActive': true,
        'tags': ['미션', '어드벤처'],
        'rating': 4.5,
        'reviewCount': 20,
        'minParticipants': 3,
      },
    ];

    for (var meeting in sampleMeetings) {
      try {
        DocumentReference docRef = await _firestore
            .collection('meetings')
            .add(meeting);
        meetingIds.add(docRef.id);
        print(
          'Created meeting: ${meeting['title']} with ID: ${docRef.id}',
        ); // 디버깅 로그
      } catch (e) {
        print('Error creating meeting ${meeting['title']}: $e');
      }
    }

    print('Created ${meetingIds.length} meetings'); // 디버깅 로그
    return meetingIds;
  }
}
