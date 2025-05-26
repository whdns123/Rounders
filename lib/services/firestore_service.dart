import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/meeting.dart';
import '../models/game_result.dart';
import '../models/chat_message.dart';
import '../models/user_model.dart';
import '../models/reservation_model.dart';
import '../models/coupon_model.dart';
import '../models/post.dart';

class FirestoreService {
  // 싱글톤 인스턴스
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 컬렉션 참조
  CollectionReference get _users => _firestore.collection('users');
  CollectionReference get _meetings => _firestore.collection('meetings');
  CollectionReference get _gameResults => _firestore.collection('game_results');
  CollectionReference get _chatRooms => _firestore.collection('chat_rooms');
  CollectionReference get _reservations =>
      _firestore.collection('reservations');
  CollectionReference get _coupons => _firestore.collection('coupons');
  CollectionReference get _posts => _firestore.collection('posts');

  // 현재 로그인된 사용자 ID
  String? get currentUserId => _auth.currentUser?.uid;

  // 사용자 프로필 초기화
  Future<void> initializeUserProfile(User user) async {
    try {
      final userDoc = await _users.doc(user.uid).get();

      if (!userDoc.exists) {
        await _users.doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'name': user.displayName ?? '게스트',
          'photoURL': user.photoURL,
          'gender': '',
          'ageGroup': '',
          'location': '',
          'phone': '',
          'createdAt': FieldValue.serverTimestamp(),
          'participatedMeetings': [],
          'hostedMeetings': [],
          'tags': [],
          'totalScore': 0,
          'meetingsPlayed': 0,
          'tier': '브론즈',
          'isHost': false,
          'hostStatus': 'none',
          'hostAppliedAt': null,
          'hostSince': null,
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('사용자 프로필 초기화 실패: $e');
      }
      rethrow;
    }
  }

  // 사용자 정보 가져오기
  Future<UserModel?> getUserById(String userId) async {
    try {
      final userDoc = await _users.doc(userId).get();
      if (!userDoc.exists) {
        return null;
      }

      final data = userDoc.data() as Map<String, dynamic>;
      return UserModel.fromMap(userId, data);
    } catch (e) {
      if (kDebugMode) {
        print('사용자 정보 가져오기 실패: $e');
      }
      rethrow;
    }
  }

  // 사용자 정보 업데이트
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _users.doc(user.id).set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('사용자 프로필 업데이트 실패: $e');
      }
      rethrow;
    }
  }

  // 예약 생성
  Future<String> createReservation(ReservationModel reservation) async {
    try {
      final docRef = await _reservations.add(reservation.toMap());
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('예약 생성 실패: $e');
      }
      rethrow;
    }
  }

  // 예약 상태 업데이트 (결제 완료)
  Future<void> markReservationAsPaid(String reservationId) async {
    try {
      await _reservations.doc(reservationId).update({
        'isPaid': true,
        'paidAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('예약 상태 업데이트 실패: $e');
      }
      rethrow;
    }
  }

  // 예약 취소
  Future<void> cancelReservation(String reservationId) async {
    try {
      // 예약 정보 가져오기
      final reservationDoc = await _reservations.doc(reservationId).get();
      if (!reservationDoc.exists) {
        throw Exception('존재하지 않는 예약입니다.');
      }

      final data = reservationDoc.data() as Map<String, dynamic>;
      final eventId = data['eventId'] as String;
      final userId = data['userId'] as String;

      // 트랜잭션으로 예약 취소 및 관련 정보 업데이트
      await _firestore.runTransaction((transaction) async {
        // 모임 정보 가져오기
        final meetingDoc = await transaction.get(_meetings.doc(eventId));

        if (meetingDoc.exists) {
          final meetingData = meetingDoc.data() as Map<String, dynamic>;
          final currentParticipants = meetingData['currentParticipants'] as int;
          final participants =
              List<String>.from(meetingData['participants'] ?? []);

          // 모임에서 사용자 제거 (참가자 명단에 있는 경우)
          if (participants.contains(userId)) {
            transaction.update(_meetings.doc(eventId), {
              'participants': FieldValue.arrayRemove([userId]),
              'currentParticipants': currentParticipants - 1,
            });
          }
        }

        // 사용자의 참가 모임 목록에서 제거
        transaction.update(_users.doc(userId), {
          'participatedMeetings': FieldValue.arrayRemove([eventId]),
        });

        // 예약 상태 취소로 변경 또는 삭제
        // 옵션 1: 예약 상태를 'canceled'로 변경
        transaction.update(_reservations.doc(reservationId), {
          'status': 'canceled',
          'canceledAt': FieldValue.serverTimestamp(),
        });

        // 옵션 2: 예약 삭제 (필요한 경우 주석 해제)
        // transaction.delete(_reservations.doc(reservationId));
      });
    } catch (e) {
      if (kDebugMode) {
        print('예약 취소 실패: $e');
      }
      rethrow;
    }
  }

  // 예약 상태 업데이트 (승인/거절)
  Future<void> updateReservationStatus(
      String reservationId, String status) async {
    try {
      await _reservations.doc(reservationId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 승인된 경우 관련 처리
      if (status == 'accepted') {
        final reservationDoc = await _reservations.doc(reservationId).get();
        if (reservationDoc.exists) {
          final data = reservationDoc.data() as Map<String, dynamic>;
          final eventId = data['eventId'] as String;
          final userId = data['userId'] as String;

          // 참가자 명단에 추가 (아직 추가되지 않은 경우)
          await _firestore.runTransaction((transaction) async {
            final meetingDoc = await transaction.get(_meetings.doc(eventId));

            if (meetingDoc.exists) {
              final meetingData = meetingDoc.data() as Map<String, dynamic>;
              final participants =
                  List<String>.from(meetingData['participants'] ?? []);

              if (!participants.contains(userId)) {
                transaction.update(_meetings.doc(eventId), {
                  'participants': FieldValue.arrayUnion([userId]),
                  'currentParticipants':
                      (meetingData['currentParticipants'] as int) + 1,
                });

                transaction.update(_users.doc(userId), {
                  'participatedMeetings': FieldValue.arrayUnion([eventId]),
                });
              }
            }
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('예약 상태 업데이트 실패: $e');
      }
      rethrow;
    }
  }

  // 출석 상태 업데이트
  Future<void> updateReservationAttendance(
      String reservationId, bool attended) async {
    try {
      await _reservations.doc(reservationId).update({
        'attended': attended,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('출석 상태 업데이트 실패: $e');
      }
      rethrow;
    }
  }

  // 예약 결과 업데이트 (등수, 점수)
  Future<void> updateReservationResult(String reservationId,
      {int? rank, int? score}) async {
    try {
      final Map<String, dynamic> updates = {
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (rank != null) {
        updates['rank'] = rank;
      }

      if (score != null) {
        updates['score'] = score;
      }

      await _reservations.doc(reservationId).update(updates);
    } catch (e) {
      if (kDebugMode) {
        print('예약 결과 업데이트 실패: $e');
      }
      rethrow;
    }
  }

  // 예약 후기 추가
  Future<void> addReservationReview(
      String reservationId, String review, int rating) async {
    try {
      await _reservations.doc(reservationId).update({
        'review': review,
        'rating': rating,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('예약 후기 추가 실패: $e');
      }
      rethrow;
    }
  }

  // 이벤트별 예약 목록 조회
  Stream<List<ReservationModel>> getReservationsByEventId(String eventId) {
    return _reservations
        .where('eventId', isEqualTo: eventId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return ReservationModel.fromMap(doc.id, data);
            }).toList());
  }

  // 사용자별 예약 목록 조회
  Stream<List<ReservationModel>> getReservationsByUserId(String userId) {
    return _reservations
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return ReservationModel.fromMap(doc.id, data);
            }).toList());
  }

  // 새 모임 생성
  Future<String> createMeeting(Meeting meeting) async {
    try {
      final docRef =
          await _firestore.collection('meetings').add(meeting.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating meeting: $e');
      rethrow;
    }
  }

  // 모임 참가
  Future<void> joinMeeting(String meetingId) async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final userId = _auth.currentUser!.uid;

      // 트랜잭션으로 동시성 문제 해결
      await _firestore.runTransaction((transaction) async {
        final meetingDoc = await transaction.get(_meetings.doc(meetingId));

        if (!meetingDoc.exists) {
          throw Exception('존재하지 않는 모임입니다.');
        }

        final meetingData = meetingDoc.data() as Map<String, dynamic>;
        final currentParticipants = meetingData['currentParticipants'] as int;
        final maxParticipants = meetingData['maxParticipants'] as int;
        final participants =
            List<String>.from(meetingData['participants'] ?? []);

        // 인원 초과 체크
        if (currentParticipants >= maxParticipants) {
          throw Exception('모임 정원이 가득 찼습니다.');
        }

        // 이미 참가 중인지 체크
        if (participants.contains(userId)) {
          throw Exception('이미 참가 중인 모임입니다.');
        }

        // 모임에 사용자 추가
        transaction.update(_meetings.doc(meetingId), {
          'participants': FieldValue.arrayUnion([userId]),
          'currentParticipants': currentParticipants + 1,
        });

        // 사용자의 참가 모임 목록에 추가
        transaction.update(_users.doc(userId), {
          'participatedMeetings': FieldValue.arrayUnion([meetingId]),
        });
      });

      // 자동으로 채팅방 생성
      await _createChatRoomForMeeting(meetingId);
    } catch (e) {
      if (kDebugMode) {
        print('모임 참가 실패: $e');
      }
      rethrow;
    }
  }

  // 모임 취소 (참가 취소)
  Future<void> leaveMeeting(String meetingId) async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final userId = _auth.currentUser!.uid;

      await _firestore.runTransaction((transaction) async {
        final meetingDoc = await transaction.get(_meetings.doc(meetingId));

        if (!meetingDoc.exists) {
          throw Exception('존재하지 않는 모임입니다.');
        }

        final meetingData = meetingDoc.data() as Map<String, dynamic>;
        final currentParticipants = meetingData['currentParticipants'] as int;
        final participants =
            List<String>.from(meetingData['participants'] ?? []);

        // 참가 중인지 체크
        if (!participants.contains(userId)) {
          throw Exception('참가 중인 모임이 아닙니다.');
        }

        // 모임에서 사용자 제거
        transaction.update(_meetings.doc(meetingId), {
          'participants': FieldValue.arrayRemove([userId]),
          'currentParticipants': currentParticipants - 1,
        });

        // 사용자의 참가 모임 목록에서 제거
        transaction.update(_users.doc(userId), {
          'participatedMeetings': FieldValue.arrayRemove([meetingId]),
        });
      });
    } catch (e) {
      if (kDebugMode) {
        print('모임 취소 실패: $e');
      }
      rethrow;
    }
  }

  // 채팅방 생성
  Future<String> _createChatRoomForMeeting(String meetingId) async {
    try {
      // 이미 채팅방이 존재하는지 확인
      final existingChatRooms = await _chatRooms
          .where('eventId', isEqualTo: meetingId)
          .where('isActive', isEqualTo: true)
          .get();

      if (existingChatRooms.docs.isNotEmpty) {
        return existingChatRooms.docs.first.id;
      }

      // 모임 정보 가져오기
      final meetingDoc = await _meetings.doc(meetingId).get();
      if (!meetingDoc.exists) {
        throw Exception('존재하지 않는 모임입니다.');
      }

      final meetingData = meetingDoc.data() as Map<String, dynamic>;
      final participants = List<String>.from(meetingData['participants'] ?? []);
      final title = meetingData['title'] as String? ?? '모임 채팅방';

      // scheduledDate 처리 추가 - Timestamp를 DateTime으로 변환
      DateTime? scheduledDate;
      if (meetingData['scheduledDate'] is Timestamp) {
        scheduledDate = (meetingData['scheduledDate'] as Timestamp).toDate();
      } else if (meetingData['scheduledDate'] is DateTime) {
        scheduledDate = meetingData['scheduledDate'] as DateTime;
      }

      // 채팅방 생성
      final chatRoom = ChatRoom(
        id: '', // Firestore에서 자동 생성
        eventId: meetingId,
        eventTitle: title,
        participantIds: participants,
        createdAt: DateTime.now(),
        // 모임 종료 후 7일 뒤에 만료 (scheduledDate null 체크 추가)
        expiredAt: scheduledDate?.add(const Duration(days: 7)),
        isActive: true,
      );

      final docRef = await _chatRooms.add(chatRoom.toMap());
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('채팅방 생성 실패: $e');
      }
      rethrow;
    }
  }

  // 채팅 메시지 전송
  Future<void> sendChatMessage(String chatRoomId, String text,
      {String? imageUrl}) async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 현재 사용자 정보
      final user = _auth.currentUser!;

      // 메시지 생성
      final message = ChatMessage(
        id: '', // Firestore에서 자동 생성
        senderId: user.uid,
        senderName: user.displayName ?? '게스트',
        text: text,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
      );

      // 채팅방에 메시지 추가
      await _chatRooms
          .doc(chatRoomId)
          .collection('messages')
          .add(message.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('메시지 전송 실패: $e');
      }
      rethrow;
    }
  }

  // 게임 결과 등록
  Future<void> submitGameResults(
      String meetingId, List<GameResult> results) async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 모임 호스트 확인
      final meetingDoc = await _meetings.doc(meetingId).get();
      if (!meetingDoc.exists) {
        throw Exception('존재하지 않는 모임입니다.');
      }

      final meetingData = meetingDoc.data() as Map<String, dynamic>;
      final hostId = meetingData['hostId'] as String;

      if (_auth.currentUser!.uid != hostId) {
        throw Exception('모임 호스트만 결과를 등록할 수 있습니다.');
      }

      // 트랜잭션으로 결과 등록
      await _firestore.runTransaction((transaction) async {
        // 게임 결과 저장
        final resultsMap = {
          'meetingId': meetingId,
          'results': results.map((r) => r.toMap()).toList(),
          'submittedBy': _auth.currentUser!.uid,
          'submittedAt': FieldValue.serverTimestamp(),
        };

        // 결과 컬렉션에 저장
        final resultRef = _gameResults.doc();
        transaction.set(resultRef, resultsMap);

        // 모임 상태 업데이트
        transaction.update(_meetings.doc(meetingId), {
          'isCompleted': true,
          'hasResults': true,
          'resultId': resultRef.id,
        });

        // 각 사용자의 태그 업데이트
        for (final result in results) {
          for (final tag in result.tags) {
            transaction.update(_users.doc(result.userId), {
              'tags': FieldValue.arrayUnion([tag]),
            });
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('게임 결과 등록 실패: $e');
      }
      rethrow;
    }
  }

  // 모임 정보 ID로 가져오기
  Future<Meeting> getMeetingById(String meetingId) async {
    try {
      final meetingDoc = await _meetings.doc(meetingId).get();

      if (!meetingDoc.exists) {
        throw Exception('존재하지 않는 모임입니다.');
      }

      final data = meetingDoc.data() as Map<String, dynamic>;
      return Meeting.fromMap(meetingId, data);
    } catch (e) {
      if (kDebugMode) {
        print('모임 정보 가져오기 실패: $e');
      }
      rethrow;
    }
  }

  // 내 모임 목록 조회
  Stream<List<Meeting>> getMyMeetings() {
    if (_auth.currentUser == null) {
      return Stream.value([]);
    }

    final userId = _auth.currentUser!.uid;

    return _meetings
        .where('participants', arrayContains: userId)
        .where('isCompleted', isEqualTo: false)
        .orderBy('scheduledDate')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Meeting.fromMap(doc.id, data);
            }).toList());
  }

  // 내가 호스팅하는 모임 목록 조회
  Stream<List<Meeting>> getMyHostedMeetings() {
    if (_auth.currentUser == null) {
      return Stream.value([]);
    }

    final userId = _auth.currentUser!.uid;

    return _meetings
        .where('hostId', isEqualTo: userId)
        .orderBy('scheduledDate')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Meeting.fromMap(doc.id, data);
            }).toList());
  }

  // 모든 활성 모임 조회 (홈 화면용)
  Stream<List<Meeting>> getActiveMeetings() {
    return _meetings
        .where('isCompleted', isEqualTo: false)
        .orderBy('scheduledDate')
        .snapshots()
        .map((snapshot) {
      if (kDebugMode) {
        print('📊 총 가져온 모임 수: ${snapshot.docs.length}');
      }

      final allMeetings = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final meeting = Meeting.fromMap(doc.id, data);

            if (kDebugMode) {
              print('📋 모임: ${meeting.title}');
              print('   - 날짜: ${meeting.scheduledDate}');
              print('   - 완료 여부: ${meeting.isCompleted}');
              print('   - 현재 시간: ${DateTime.now()}');
              print(
                  '   - 미래 모임인가: ${meeting.scheduledDate.isAfter(DateTime.now())}');
            }

            return meeting;
          })
          .where((meeting) => meeting.scheduledDate.isAfter(DateTime.now()))
          .toList();

      if (kDebugMode) {
        print('✅ 필터링 후 활성 모임 수: ${allMeetings.length}');
      }

      return allMeetings;
    });
  }

  // 채팅 메시지 스트림
  Stream<List<ChatMessage>> getChatMessages(String chatRoomId) {
    return _chatRooms
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100) // 최근 100개 메시지만 가져오기
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return ChatMessage.fromMap(doc.id, data);
            }).toList());
  }

  // 내 채팅방 목록
  Stream<List<ChatRoom>> getMyChatRooms() {
    if (_auth.currentUser == null) {
      return Stream.value([]);
    }

    final userId = _auth.currentUser!.uid;

    return _chatRooms
        .where('participantIds', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return ChatRoom.fromMap(doc.id, data);
            }).toList());
  }

  // 테스트용 모임 생성 메서드
  Future<String> createTestMeeting() async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final userId = _auth.currentUser!.uid;
      final userDoc = await _users.doc(userId).get();

      if (!userDoc.exists) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final userName = userData['name'] ?? '게스트';

      // 테스트용 모임 데이터 생성
      final testMeeting = Meeting(
        id: '',
        title: '보드게임 모임: 뱅!',
        description:
            '뱅!(Bang!) 보드게임 모임입니다. 서부 시대를 배경으로 한 카드 게임으로, 보안관, 무법자, 배신자 등 다양한 역할을 맡아 플레이합니다. 초보자도 쉽게 배울 수 있어요. 간단한 다과와 음료가 준비됩니다. 많은 참여 부탁드립니다!',
        location: '서울시 강남구 테헤란로 123 카페보드',
        scheduledDate:
            DateTime.now().add(const Duration(hours: 2)), // 2시간 후로 변경
        maxParticipants: 8,
        currentParticipants: 1,
        hostId: userId,
        hostName: userName,
        price: 15000,
        participants: [userId],
        imageUrls: [
          'https://cdn.pixabay.com/photo/2019/07/28/08/39/game-4367695_1280.jpg',
          'https://cdn.pixabay.com/photo/2016/09/08/12/00/dice-1654482_1280.jpg',
          'https://cdn.pixabay.com/photo/2017/08/31/03/21/board-game-2699636_1280.jpg'
        ],
        requiredLevel: '초보',
      );

      if (kDebugMode) {
        print('🆕 새 모임 생성:');
        print('   - 제목: ${testMeeting.title}');
        print('   - 날짜: ${testMeeting.scheduledDate}');
        print('   - 완료 여부: ${testMeeting.isCompleted}');
        print('   - 현재 시간: ${DateTime.now()}');
      }

      // Firestore에 저장
      final docRef = await _meetings.add(testMeeting.toFirestore());

      if (kDebugMode) {
        print('✅ 모임이 Firestore에 저장됨: ${docRef.id}');
      }

      // 호스트의 hostedMeetings 배열에 추가
      await _users.doc(userId).update({
        'hostedMeetings': FieldValue.arrayUnion([docRef.id]),
      });

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('테스트 모임 생성 실패: $e');
      }
      rethrow;
    }
  }

  // 모임 종료 및 결과 입력
  Future<void> completeMeeting(String meetingId) async {
    try {
      await _meetings.doc(meetingId).update({
        'isCompleted': true,
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('모임 종료 실패: $e');
      }
      rethrow;
    }
  }

  // 모임 참가자별 등수 및 점수 기록
  Future<void> recordMeetingResults(
      String meetingId, List<Map<String, dynamic>> participantResults) async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 모임 호스트 확인
      final meetingDoc = await _meetings.doc(meetingId).get();
      if (!meetingDoc.exists) {
        throw Exception('존재하지 않는 모임입니다.');
      }

      final meetingData = meetingDoc.data() as Map<String, dynamic>;
      final hostId = meetingData['hostId'] as String;

      if (_auth.currentUser!.uid != hostId) {
        throw Exception('모임 호스트만 결과를 등록할 수 있습니다.');
      }

      // 트랜잭션 시작
      await _firestore.runTransaction((transaction) async {
        // 각 참가자 결과 처리
        for (final result in participantResults) {
          final userId = result['userId'] as String;
          final rank = result['rank'] as int;
          final attended = result['attended'] as bool? ?? true;

          // 등수에 따른 점수 계산
          int score = 0;
          if (attended) {
            if (rank == 1) {
              score = 5;
            } else if (rank == 2) {
              score = 3;
            } else if (rank == 3) {
              score = 2;
            } else {
              score = 1;
            }
          }

          // 해당 사용자의 reservation 찾기
          final reservationQuery = await _reservations
              .where('eventId', isEqualTo: meetingId)
              .where('userId', isEqualTo: userId)
              .limit(1)
              .get();

          if (reservationQuery.docs.isNotEmpty) {
            final reservationId = reservationQuery.docs.first.id;

            // 참가자 등수 및 점수 업데이트
            transaction.update(_reservations.doc(reservationId), {
              'rank': rank,
              'score': score,
              'attended': attended,
              'status': 'completed',
              'updatedAt': FieldValue.serverTimestamp(),
            });

            // 사용자 누적 점수 및 참가 모임 수 업데이트
            final userDoc = await transaction.get(_users.doc(userId));

            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;
              final int currentTotalScore = userData['totalScore'] as int? ?? 0;
              final int currentMeetingsPlayed =
                  userData['meetingsPlayed'] as int? ?? 0;

              // 참여한 경우에만 모임 수 증가
              if (attended) {
                transaction.update(_users.doc(userId), {
                  'totalScore': currentTotalScore + score,
                  'meetingsPlayed': currentMeetingsPlayed + 1,
                });

                // 티어 업데이트
                final newTier = _calculateUserTier(
                    currentTotalScore + score, currentMeetingsPlayed + 1);
                transaction.update(_users.doc(userId), {
                  'tier': newTier,
                });
              }
            }
          }
        }

        // 모임 완료 처리
        transaction.update(_meetings.doc(meetingId), {
          'isCompleted': true,
          'hasResults': true,
          'completedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      if (kDebugMode) {
        print('모임 결과 기록 실패: $e');
      }
      rethrow;
    }
  }

  // 사용자 티어 계산
  String _calculateUserTier(int totalScore, int meetingsPlayed) {
    if (meetingsPlayed == 0) return '브론즈';

    final avgScore = totalScore / meetingsPlayed;

    if (avgScore >= 4.5) return '다이아몬드';
    if (avgScore >= 3.5) return '플래티넘';
    if (avgScore >= 2.5) return '골드';
    if (avgScore >= 1.5) return '실버';
    return '브론즈';
  }

  // 모임의 모든 참가자 가져오기 (결과 입력용)
  Future<List<Map<String, dynamic>>> getMeetingParticipants(
      String meetingId) async {
    try {
      // 모임 정보 가져오기
      final meetingDoc = await _meetings.doc(meetingId).get();
      if (!meetingDoc.exists) {
        throw Exception('존재하지 않는 모임입니다.');
      }

      final meetingData = meetingDoc.data() as Map<String, dynamic>;
      final participants = List<String>.from(meetingData['participants'] ?? []);

      List<Map<String, dynamic>> participantList = [];

      // 각 참가자 정보 가져오기
      for (final userId in participants) {
        final userDoc = await _users.doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          participantList.add({
            'userId': userId,
            'name': userData['name'] ?? '사용자',
            'photoURL': userData['photoURL'],
            'totalScore': userData['totalScore'] ?? 0,
            'tier': userData['tier'] ?? '브론즈',
          });
        }
      }

      return participantList;
    } catch (e) {
      if (kDebugMode) {
        print('모임 참가자 가져오기 실패: $e');
      }
      rethrow;
    }
  }

  // 사용자 통계 가져오기
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final userDoc = await _users.doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      return {
        'totalScore': userData['totalScore'] ?? 0,
        'meetingsPlayed': userData['meetingsPlayed'] ?? 0,
        'tier': userData['tier'] ?? '브론즈',
        'avgScore':
            userData['meetingsPlayed'] != null && userData['meetingsPlayed'] > 0
                ? (userData['totalScore'] ?? 0) / userData['meetingsPlayed']
                : 0.0,
      };
    } catch (e) {
      if (kDebugMode) {
        print('사용자 통계 가져오기 실패: $e');
      }
      rethrow;
    }
  }

  // 호스트 라이선스 신청
  Future<void> applyForHostLicense(
      String userId, Map<String, dynamic> applicationData) async {
    try {
      if (_auth.currentUser == null || _auth.currentUser!.uid != userId) {
        throw Exception('권한이 없습니다.');
      }

      await _users.doc(userId).update({
        'hostStatus': 'pending',
        'hostAppliedAt': FieldValue.serverTimestamp(),
        'hostApplicationData': applicationData, // 신청 폼에서 입력한 추가 정보
      });
    } catch (e) {
      if (kDebugMode) {
        print('호스트 라이선스 신청 실패: $e');
      }
      rethrow;
    }
  }

  // 호스트 신청 상태 확인
  Future<Map<String, dynamic>> getHostApplicationStatus(String userId) async {
    try {
      final userDoc = await _users.doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      final data = userDoc.data() as Map<String, dynamic>;
      return {
        'isHost': data['isHost'] ?? false,
        'hostStatus': data['hostStatus'] ?? 'none',
        'hostAppliedAt': data['hostAppliedAt'],
        'hostSince': data['hostSince'],
      };
    } catch (e) {
      if (kDebugMode) {
        print('호스트 신청 상태 확인 실패: $e');
      }
      rethrow;
    }
  }

  // 호스트 승인 (관리자 전용)
  Future<void> approveHostApplication(String userId) async {
    try {
      // 현재는 관리자 권한 체크 로직이 없으므로 주석 처리
      // 실제로는 관리자 권한 확인 후 승인해야 함

      await _users.doc(userId).update({
        'isHost': true,
        'hostStatus': 'approved',
        'hostSince': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('호스트 승인 실패: $e');
      }
      rethrow;
    }
  }

  // 호스트 신청 거절 (관리자 전용)
  Future<void> rejectHostApplication(String userId, String reason) async {
    try {
      // 현재는 관리자 권한 체크 로직이 없으므로 주석 처리
      // 실제로는 관리자 권한 확인 후 거절해야 함

      await _users.doc(userId).update({
        'hostStatus': 'rejected',
        'rejectionReason': reason,
      });
    } catch (e) {
      if (kDebugMode) {
        print('호스트 신청 거절 실패: $e');
      }
      rethrow;
    }
  }

  // 사용 가능한 쿠폰 조회
  Future<List<CouponModel>> getAvailableCoupons(String userId) async {
    try {
      final now = DateTime.now();
      final snapshot = await _coupons
          .where('userId', isEqualTo: userId)
          .where('used', isEqualTo: false)
          .where('validUntil', isGreaterThanOrEqualTo: now)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return CouponModel.fromMap(doc.id, data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('쿠폰 조회 실패: $e');
      }
      rethrow;
    }
  }

  // 쿠폰 사용 처리
  Future<void> useCoupon(String couponId, String eventId) async {
    try {
      await _coupons.doc(couponId).update({
        'used': true,
        'appliedTo': eventId,
        'usedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('쿠폰 사용 처리 실패: $e');
      }
      rethrow;
    }
  }

  // 예약 생성 (결제 전)
  Future<String> createReservationBeforePayment(
      ReservationModel reservation) async {
    try {
      // isPaid를 false로 설정하여 결제 전 상태로 저장
      final Map<String, dynamic> data = reservation.toMap();
      data['isPaid'] = false;
      data['status'] = 'pending';
      data['createdAt'] = FieldValue.serverTimestamp();

      final docRef = await _reservations.add(data);
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('예약 생성 실패: $e');
      }
      rethrow;
    }
  }

  // 결제 완료 후 예약 업데이트
  Future<void> completeReservationAfterPayment(String reservationId,
      {String? couponId}) async {
    try {
      String eventId = '';

      await _firestore.runTransaction((transaction) async {
        // 예약 정보 가져오기
        final reservationDoc =
            await transaction.get(_reservations.doc(reservationId));

        if (!reservationDoc.exists) {
          throw Exception('존재하지 않는 예약입니다.');
        }

        final reservationData = reservationDoc.data() as Map<String, dynamic>;
        eventId = reservationData['eventId'] as String;
        final userId = reservationData['userId'] as String;

        // 예약 상태 업데이트
        transaction.update(_reservations.doc(reservationId), {
          'isPaid': true,
          'paidAt': FieldValue.serverTimestamp(),
          'status': 'accepted',
        });

        // 모임에 참가자 추가
        final meetingDoc = await transaction.get(_meetings.doc(eventId));

        if (meetingDoc.exists) {
          final meetingData = meetingDoc.data() as Map<String, dynamic>;
          final currentParticipants = meetingData['currentParticipants'] as int;
          final participants =
              List<String>.from(meetingData['participants'] ?? []);

          if (!participants.contains(userId)) {
            transaction.update(_meetings.doc(eventId), {
              'participants': FieldValue.arrayUnion([userId]),
              'currentParticipants': currentParticipants + 1,
            });
          }
        }

        // 사용자의 참가 모임 목록에 추가
        transaction.update(_users.doc(userId), {
          'participatedMeetings': FieldValue.arrayUnion([eventId]),
        });

        // 쿠폰 사용 처리
        if (couponId != null) {
          transaction.update(_coupons.doc(couponId), {
            'used': true,
            'appliedTo': eventId,
            'usedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      // 채팅방 생성 (트랜잭션 외부에서 수행)
      if (eventId.isNotEmpty) {
        await _createChatRoomForMeeting(eventId);
      }
    } catch (e) {
      if (kDebugMode) {
        print('결제 완료 처리 실패: $e');
      }
      rethrow;
    }
  }

  // 예약 정보 조회
  Future<ReservationModel?> getReservationById(String reservationId) async {
    try {
      final doc = await _reservations.doc(reservationId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return ReservationModel.fromMap(doc.id, data);
    } catch (e) {
      if (kDebugMode) {
        print('예약 정보 조회 실패: $e');
      }
      rethrow;
    }
  }

  // 특정 모임과 사용자에 대한 예약 조회
  Future<ReservationModel?> getReservationByEventAndUser(
      String eventId, String userId) async {
    try {
      final snapshot = await _reservations
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      return ReservationModel.fromMap(doc.id, data);
    } catch (e) {
      if (kDebugMode) {
        print('예약 조회 실패: $e');
      }
      rethrow;
    }
  }

  // 모임 삭제 (호스트만 가능)
  Future<void> deleteMeeting(String meetingId) async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final userId = _auth.currentUser!.uid;

      await _firestore.runTransaction((transaction) async {
        // 모임 정보 가져오기
        final meetingDoc = await transaction.get(_meetings.doc(meetingId));

        if (!meetingDoc.exists) {
          throw Exception('존재하지 않는 모임입니다.');
        }

        final meetingData = meetingDoc.data() as Map<String, dynamic>;
        final hostId = meetingData['hostId'] as String;
        final currentParticipants = meetingData['currentParticipants'] as int;
        final scheduledDate = meetingData['scheduledDate'] is Timestamp
            ? (meetingData['scheduledDate'] as Timestamp).toDate()
            : meetingData['scheduledDate'] as DateTime;

        // 호스트 권한 확인
        if (userId != hostId) {
          throw Exception('모임 호스트만 삭제할 수 있습니다.');
        }

        // 삭제 조건 확인
        if (currentParticipants > 1) {
          // 호스트 제외한 참가자가 있는 경우
          throw Exception('참가자가 있는 모임은 삭제할 수 없습니다.');
        }

        if (scheduledDate.isBefore(DateTime.now())) {
          throw Exception('이미 시작된 모임은 삭제할 수 없습니다.');
        }

        // 연결된 예약들을 삭제 상태로 변경
        final reservationsQuery =
            await _reservations.where('eventId', isEqualTo: meetingId).get();

        for (final doc in reservationsQuery.docs) {
          transaction.update(doc.reference, {
            'status': 'host_deleted',
            'deletedAt': FieldValue.serverTimestamp(),
          });
        }

        // 호스트의 hostedMeetings 배열에서 제거
        transaction.update(_users.doc(userId), {
          'hostedMeetings': FieldValue.arrayRemove([meetingId]),
        });

        // 모임 문서 삭제
        transaction.delete(_meetings.doc(meetingId));

        // 관련 채팅방 비활성화
        final chatRoomsQuery =
            await _chatRooms.where('eventId', isEqualTo: meetingId).get();

        for (final doc in chatRoomsQuery.docs) {
          transaction.update(doc.reference, {
            'isActive': false,
            'deletedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('모임 삭제 실패: $e');
      }
      rethrow;
    }
  }

  // ==================== 라운지 관련 메서드 ====================

  /// 새 게시글 작성 (누구나 작성 가능)
  Future<String> createPost({
    required String eventId,
    required List<String> imageUrls,
    required String description,
  }) async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final userId = _auth.currentUser!.uid;

      // 모임이 존재하는지만 확인
      final meetingDoc = await _meetings.doc(eventId).get();
      if (!meetingDoc.exists) {
        throw Exception('존재하지 않는 모임입니다.');
      }

      // 사용자 정보 가져오기
      final userDoc = await _users.doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final userName = userData['name'] ?? '사용자';

      // 새 게시글 생성
      final post = Post(
        id: '',
        imageUrls: imageUrls,
        description: description,
        eventId: eventId,
        createdBy: userId,
        createdByName: userName,
        createdAt: DateTime.now(),
        likes: [],
      );

      // Firestore에 저장
      final docRef = await _posts.add(post.toFirestore());
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('게시글 작성 실패: $e');
      }
      rethrow;
    }
  }

  /// 사용자가 참가 완료한 모임 목록 가져오기
  Future<List<Meeting>> getCompletedMeetingsByUser(String userId) async {
    try {
      // 사용자의 완료된 예약 목록 가져오기
      final reservationsSnapshot = await _reservations
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      List<Meeting> completedMeetings = [];

      // 각 예약에 대해 해당 모임 정보 가져오기
      for (final reservationDoc in reservationsSnapshot.docs) {
        final reservationData = reservationDoc.data() as Map<String, dynamic>;
        final eventId = reservationData['eventId'] as String;

        try {
          final meetingDoc = await _meetings.doc(eventId).get();
          if (meetingDoc.exists) {
            final meetingData = meetingDoc.data() as Map<String, dynamic>;
            final meeting = Meeting.fromMap(eventId, meetingData);
            completedMeetings.add(meeting);
          }
        } catch (e) {
          // 특정 모임 로드 실패 시 스킵
          if (kDebugMode) {
            print('모임 $eventId 로드 실패: $e');
          }
          continue;
        }
      }

      // 최근 완료된 모임부터 정렬
      completedMeetings
          .sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

      return completedMeetings;
    } catch (e) {
      if (kDebugMode) {
        print('완료된 모임 목록 가져오기 실패: $e');
      }
      rethrow;
    }
  }

  /// 모든 게시글 가져오기 (최신순)
  Stream<List<Post>> getAllPosts() {
    return _posts
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Post.fromMap(doc.id, data);
            }).toList());
  }

  /// 특정 모임의 게시글들 가져오기
  Stream<List<Post>> getPostsByEvent(String eventId) {
    return _posts
        .where('eventId', isEqualTo: eventId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Post.fromMap(doc.id, data);
            }).toList());
  }

  /// 게시글 좋아요/좋아요 취소
  Future<void> togglePostLike(String postId) async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final userId = _auth.currentUser!.uid;

      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(_posts.doc(postId));

        if (!postDoc.exists) {
          throw Exception('존재하지 않는 게시글입니다.');
        }

        final postData = postDoc.data() as Map<String, dynamic>;
        final likes = List<String>.from(postData['likes'] ?? []);

        if (likes.contains(userId)) {
          // 좋아요 취소
          transaction.update(_posts.doc(postId), {
            'likes': FieldValue.arrayRemove([userId]),
          });
        } else {
          // 좋아요 추가
          transaction.update(_posts.doc(postId), {
            'likes': FieldValue.arrayUnion([userId]),
          });
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('좋아요 처리 실패: $e');
      }
      rethrow;
    }
  }

  /// 댓글 작성
  Future<String> addComment({
    required String postId,
    required String text,
  }) async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final userId = _auth.currentUser!.uid;

      // 사용자 정보 가져오기
      final userDoc = await _users.doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final userName = userData['name'] ?? '사용자';

      // 댓글 생성
      final comment = Comment(
        id: '',
        userId: userId,
        userName: userName,
        text: text,
        createdAt: DateTime.now(),
      );

      // Firestore에 저장
      final docRef = await _posts
          .doc(postId)
          .collection('comments')
          .add(comment.toFirestore());

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('댓글 작성 실패: $e');
      }
      rethrow;
    }
  }

  /// 게시글의 댓글들 가져오기
  Stream<List<Comment>> getComments(String postId) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Comment.fromMap(doc.id, data);
            }).toList());
  }

  /// 게시글 삭제 (작성자만 가능)
  Future<void> deletePost(String postId) async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final userId = _auth.currentUser!.uid;

      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(_posts.doc(postId));

        if (!postDoc.exists) {
          throw Exception('존재하지 않는 게시글입니다.');
        }

        final postData = postDoc.data() as Map<String, dynamic>;
        if (postData['createdBy'] != userId) {
          throw Exception('작성자만 게시글을 삭제할 수 있습니다.');
        }

        // 게시글 삭제
        transaction.delete(_posts.doc(postId));

        // 댓글들도 모두 삭제
        final commentsSnapshot =
            await _posts.doc(postId).collection('comments').get();

        for (final commentDoc in commentsSnapshot.docs) {
          transaction.delete(commentDoc.reference);
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('게시글 삭제 실패: $e');
      }
      rethrow;
    }
  }

  /// 댓글 삭제 (작성자만 가능)
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final userId = _auth.currentUser!.uid;

      await _firestore.runTransaction((transaction) async {
        final commentDoc = await transaction
            .get(_posts.doc(postId).collection('comments').doc(commentId));

        if (!commentDoc.exists) {
          throw Exception('존재하지 않는 댓글입니다.');
        }

        final commentData = commentDoc.data() as Map<String, dynamic>;
        if (commentData['userId'] != userId) {
          throw Exception('작성자만 댓글을 삭제할 수 있습니다.');
        }

        // 댓글 삭제
        transaction.delete(commentDoc.reference);
      });
    } catch (e) {
      if (kDebugMode) {
        print('댓글 삭제 실패: $e');
      }
      rethrow;
    }
  }

  /// 특정 게시글 정보 가져오기
  Future<Post?> getPostById(String postId) async {
    try {
      final doc = await _posts.doc(postId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return Post.fromMap(doc.id, data);
    } catch (e) {
      if (kDebugMode) {
        print('게시글 조회 실패: $e');
      }
      rethrow;
    }
  }
}
