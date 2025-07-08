import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/meeting.dart';
import '../models/user_model.dart';
import '../models/game.dart';
import '../models/booking.dart';
import '../models/venue.dart';

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
  CollectionReference get _applications =>
      _firestore.collection('applications');
  CollectionReference get _favorites => _firestore.collection('favorites');
  CollectionReference get _games => _firestore.collection('games');
  CollectionReference get _venues => _firestore.collection('venues');
  CollectionReference get _hostApplications =>
      _firestore.collection('host_applications');
  CollectionReference get _locations => _firestore.collection('locations');

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
          'role': 'user',
          'hostStatus': 'none',
          'hostAppliedAt': null,
          'hostSince': null,
          'totalScore': 0,
          'meetingsPlayed': 0,
          'wins': 0,
          'losses': 0,
          'tier': '브론즈',
          'tags': [],
        });
      } else {
        // 기존 사용자의 경우, 이름이 '게스트'이면서 displayName이 있으면 업데이트
        final data = userDoc.data() as Map<String, dynamic>;
        final currentName = data['name'] as String?;
        if ((currentName == null || currentName == '게스트') &&
            user.displayName != null &&
            user.displayName!.isNotEmpty) {
          await _users.doc(user.uid).update({'name': user.displayName});
        }
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

  // 호스트 신청
  Future<void> applyForHost() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      await _users.doc(userId).update({
        'hostStatus': 'pending',
        'hostAppliedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('호스트 신청 실패: $e');
      }
      rethrow;
    }
  }

  // 모임 생성
  Future<String> createMeeting(Meeting meeting) async {
    try {
      final docRef = await _meetings.add(meeting.toMap());

      // 호스트의 호스팅 모임 목록에 추가
      await _users.doc(meeting.hostId).update({
        'hostedMeetings': FieldValue.arrayUnion([docRef.id]),
      });

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('모임 생성 실패: $e');
      }
      rethrow;
    }
  }

  // 모임 목록 가져오기 (활성화된 모임만, 기한이 지나지 않은 모임만)
  Stream<List<Meeting>> getActiveMeetings() {
    // 1차 필터링: Firestore 쿼리 수준에서 시작 시간이 지나지 않은 모임만
    final now = DateTime.now();
    final threshold = now.subtract(
      const Duration(hours: 1),
    ); // 1시간 여유를 둠 (게임 시간 고려)

    return _meetings
        .where('isActive', isEqualTo: true)
        .where('scheduledDate', isGreaterThan: Timestamp.fromDate(threshold))
        .orderBy('scheduledDate', descending: false) // 가까운 모임부터 표시
        .snapshots()
        .asyncMap((snapshot) async {
          // 만료된 모임들의 상태를 자동으로 업데이트
          updateExpiredMeetingsStatus().catchError((e) {
            if (kDebugMode) {
              print('⚠️ 자동 상태 업데이트 중 오류: $e');
            }
          });

          List<Meeting> validMeetings = [];

          for (var doc in snapshot.docs) {
            try {
              final meeting = Meeting.fromMap(
                doc.id,
                doc.data() as Map<String, dynamic>,
              );

              // 2차 필터링: 게임 종료 시간 계산하여 정확한 필터링
              if (await _isMeetingStillActive(meeting)) {
                validMeetings.add(meeting);
              }
            } catch (e) {
              if (kDebugMode) {
                print('⚠️ 모임 데이터 파싱 오류: $e');
              }
              // 파싱 오류가 있어도 계속 진행
            }
          }

          return validMeetings;
        });
  }

  // 모임이 아직 진행 중이거나 시작 전인지 확인
  Future<bool> _isMeetingStillActive(Meeting meeting) async {
    try {
      // 🔧 1순위: status가 completed면 무조건 비활성
      if (meeting.status == 'completed') {
        if (kDebugMode) {
          print('📅 모임 ${meeting.title}: status가 completed이므로 비활성');
        }
        return false;
      }

      final now = DateTime.now();

      // 게임 정보가 있으면 정확한 종료 시간 계산
      if (meeting.gameId != null && meeting.gameId!.isNotEmpty) {
        final game = await getGameById(meeting.gameId!);
        if (game != null && game.estimatedDuration > 0) {
          final endTime = meeting.scheduledDate.add(
            Duration(minutes: game.estimatedDuration),
          );
          if (kDebugMode) {
            print(
              '📅 모임 ${meeting.title}: 시작 ${meeting.scheduledDate}, 종료 예정 $endTime, 현재 $now',
            );
          }
          return endTime.isAfter(now);
        }
      }

      // 게임 정보가 없으면 기본 3시간으로 가정
      final defaultEndTime = meeting.scheduledDate.add(
        const Duration(hours: 3),
      );
      if (kDebugMode) {
        print(
          '📅 모임 ${meeting.title}: 시작 ${meeting.scheduledDate}, 기본 종료 예정 $defaultEndTime, 현재 $now',
        );
      }
      return defaultEndTime.isAfter(now);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ 모임 활성 상태 확인 오류: $e');
      }
      // 오류 시 시작 시간만으로 판단 (보수적 접근)
      return meeting.scheduledDate.isAfter(DateTime.now());
    }
  }

  // 호스트가 만든 모임 목록 가져오기 (기한이 지나지 않은 모임만)
  Stream<List<Meeting>> getHostMeetings(String hostId) {
    // 1차 필터링: Firestore 쿼리 수준에서 기본 필터링
    final now = DateTime.now();
    final threshold = now.subtract(const Duration(hours: 1));

    return _meetings
        .where('hostId', isEqualTo: hostId)
        .where('isActive', isEqualTo: true)
        .where('scheduledDate', isGreaterThan: Timestamp.fromDate(threshold))
        .orderBy('scheduledDate', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Meeting> activeMeetings = [];

          for (var doc in snapshot.docs) {
            try {
              final meeting = Meeting.fromMap(
                doc.id,
                doc.data() as Map<String, dynamic>,
              );

              // 2차 필터링: 게임 종료 시간 계산하여 정확한 필터링
              if (await _isMeetingStillActive(meeting)) {
                activeMeetings.add(meeting);
              }
            } catch (e) {
              if (kDebugMode) {
                print('⚠️ 호스트 모임 데이터 파싱 오류: $e');
              }
            }
          }

          return activeMeetings;
        });
  }

  // 특정 모임 가져오기
  Future<Meeting?> getMeetingById(String meetingId) async {
    try {
      final doc = await _meetings.doc(meetingId).get();
      if (!doc.exists) return null;

      final rawData = doc.data() as Map<String, dynamic>;

      final meeting = Meeting.fromMap(doc.id, rawData);

      return meeting;
    } catch (e) {
      if (kDebugMode) {
        print('모임 정보 가져오기 실패: $e');
      }
      rethrow;
    }
  }

  // 모임 참여 신청
  Future<void> applyToMeeting(String meetingId) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 신청 정보 저장
      await _applications.add({
        'meetingId': meetingId,
        'userId': userId,
        'status': 'pending', // pending, approved, rejected
        'appliedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('모임 신청 실패: $e');
      }
      rethrow;
    }
  }

  // 모임 신청 상태 확인
  Future<String?> getUserApplicationStatus(String meetingId) async {
    try {
      final userId = currentUserId;
      if (userId == null) return null;

      final snapshot = await _applications
          .where('meetingId', isEqualTo: meetingId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        return data['status'] as String?;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('신청 상태 확인 실패: $e');
      }
      return null;
    }
  }

  // 모임 신청자 목록 가져오기
  Stream<List<Map<String, dynamic>>> getMeetingApplications(String meetingId) {
    return _applications
        .where('meetingId', isEqualTo: meetingId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>},
              )
              .toList(),
        );
  }

  // 신청 승인/거절
  Future<void> updateApplicationStatus(
    String applicationId,
    String status,
  ) async {
    try {
      await _applications.doc(applicationId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 승인된 경우 모임 참가자 목록에 추가
      if (status == 'approved') {
        final applicationDoc = await _applications.doc(applicationId).get();
        if (applicationDoc.exists) {
          final data = applicationDoc.data() as Map<String, dynamic>;
          final meetingId = data['meetingId'] as String;
          final userId = data['userId'] as String;

          await _meetings.doc(meetingId).update({
            'participants': FieldValue.arrayUnion([userId]),
            'currentParticipants': FieldValue.increment(1),
          });

          await _users.doc(userId).update({
            'participatedMeetings': FieldValue.arrayUnion([meetingId]),
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('신청 상태 업데이트 실패: $e');
      }
      rethrow;
    }
  }

  // 모임 수정
  Future<void> updateMeeting(
    String meetingId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _meetings.doc(meetingId).update(data);
    } catch (e) {
      if (kDebugMode) {
        print('모임 수정 실패: $e');
      }
      rethrow;
    }
  }

  // 모임 삭제 (비활성화)
  Future<void> deleteMeeting(String meetingId) async {
    try {
      await _meetings.doc(meetingId).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('모임 삭제 실패: $e');
      }
      rethrow;
    }
  }

  // 사용자의 예약 모임 목록 가져오기
  Stream<List<Map<String, dynamic>>> getUserReservations() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _applications
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['pending', 'approved'])
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> reservations = [];

          for (var doc in snapshot.docs) {
            final applicationData = doc.data() as Map<String, dynamic>;
            final meetingId = applicationData['meetingId'] as String;

            // 모임 정보 가져오기
            final meetingDoc = await _meetings.doc(meetingId).get();
            if (meetingDoc.exists) {
              final meetingData = meetingDoc.data() as Map<String, dynamic>;
              final meeting = Meeting.fromMap(meetingId, meetingData);

              // 🔧 활성화되고 진행 중인 모임만 예약 내역에 표시
              if (meeting.isActive && await _isMeetingStillActive(meeting)) {
                reservations.add({
                  'applicationId': doc.id,
                  'meeting': meeting,
                  'status': applicationData['status'],
                  'appliedAt': applicationData['appliedAt'],
                  'bookingNumber':
                      applicationData['bookingNumber'] ??
                      'BOOK-${doc.id.substring(0, 8).toUpperCase()}',
                });
              }
            }
          }

          return reservations;
        });
  }

  // 찜하기 추가
  Future<void> addToFavorites(String meetingId) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      await _favorites.doc('${userId}_$meetingId').set({
        'userId': userId,
        'meetingId': meetingId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('찜하기 추가 실패: $e');
      }
      rethrow;
    }
  }

  // 찜하기 제거
  Future<void> removeFromFavorites(String meetingId) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      await _favorites.doc('${userId}_$meetingId').delete();
    } catch (e) {
      if (kDebugMode) {
        print('찜하기 제거 실패: $e');
      }
      rethrow;
    }
  }

  // 찜하기 상태 확인
  Future<bool> isFavorite(String meetingId) async {
    try {
      final userId = currentUserId;
      if (userId == null) return false;

      final doc = await _favorites.doc('${userId}_$meetingId').get();
      return doc.exists;
    } catch (e) {
      if (kDebugMode) {
        print('찜하기 상태 확인 실패: $e');
      }
      return false;
    }
  }

  // 찜한 모임 목록 가져오기 (기한이 지나지 않은 모임만)
  Stream<List<Meeting>> getFavoriteMeetings() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _favorites
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Meeting> favoriteMeetings = [];

          for (var doc in snapshot.docs) {
            final favoriteData = doc.data() as Map<String, dynamic>;
            final meetingId = favoriteData['meetingId'] as String;

            // 모임 정보 가져오기
            final meetingDoc = await _meetings.doc(meetingId).get();
            if (meetingDoc.exists) {
              final meetingData = meetingDoc.data() as Map<String, dynamic>;
              final meeting = Meeting.fromMap(meetingId, meetingData);

              // 활성화되고 아직 진행 중인 모임만 추가
              if (meeting.isActive && await _isMeetingStillActive(meeting)) {
                favoriteMeetings.add(meeting);
              }
            }
          }

          return favoriteMeetings;
        });
  }

  // ========== 게임 관련 메서드들 ==========

  // 모든 게임 목록 가져오기
  Stream<List<Game>> getGames() {
    return _games.snapshots().map((snapshot) {
      if (kDebugMode) {
        print('🎮 게임 문서 수: ${snapshot.docs.length}');
      }

      final games = snapshot.docs.map((doc) {
        if (kDebugMode) {
          print('🎮 게임 문서 ID: ${doc.id}');
          print('🎮 게임 데이터: ${doc.data()}');
        }
        return Game.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();

      if (kDebugMode) {
        print('🎮 파싱된 게임 수: ${games.length}');
        for (final game in games) {
          print('🎮 게임: ${game.title}');
        }
      }

      // 클라이언트에서 정렬
      games.sort((a, b) => a.title.compareTo(b.title));
      return games;
    });
  }

  // 특정 게임 정보 가져오기
  Future<Game?> getGameById(String gameId) async {
    try {
      final doc = await _games.doc(gameId).get();
      if (!doc.exists) return null;

      return Game.fromMap({
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      });
    } catch (e) {
      if (kDebugMode) {
        print('게임 정보 가져오기 실패: $e');
      }
      rethrow;
    }
  }

  // 게임 기반 모임 생성
  Future<String> createGameMeeting({
    required String gameId,
    required DateTime scheduledDate,
    required String location,
    required String locationDetail,
    required String benefitDescription,
    required String? imageUrl,
    required String? additionalNotes,
    String? venueId, // venueId 파라미터 추가
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 게임 정보 가져오기
      final game = await getGameById(gameId);
      if (game == null) {
        throw Exception('게임 정보를 찾을 수 없습니다.');
      }

      // 모임 데이터 생성
      final meetingData = {
        'gameId': gameId,
        'venueId': venueId, // venueId 추가
        'title': game.title,
        'description': game.description,
        'hostId': userId,
        'scheduledDate': Timestamp.fromDate(scheduledDate),
        'location': location,
        'locationDetail': locationDetail,
        'price': game.price,
        'minParticipants': game.minParticipants,
        'maxParticipants': game.maxParticipants,
        'currentParticipants': 0,
        'participants': <String>[],
        'benefitDescription': benefitDescription,
        'imageUrl': imageUrl ?? game.imageUrl,
        'additionalNotes': additionalNotes ?? '',
        'tags': game.tags,
        'difficulty': game.difficulty,
        'rating': game.rating,
        'reviewCount': game.reviewCount,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 모임 생성
      final docRef = await _meetings.add(meetingData);

      // 호스트의 호스팅 모임 목록에 추가
      await _users.doc(userId).update({
        'hostedMeetings': FieldValue.arrayUnion([docRef.id]),
      });

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('게임 모임 생성 실패: $e');
      }
      rethrow;
    }
  }

  // ========== 참가자 관리 메서드들 ==========

  // 특정 모임의 예약(참가신청) 목록 가져오기
  Future<List<Booking>> getMeetingBookings(String meetingId) async {
    try {
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('meetingId', isEqualTo: meetingId)
          .get();

      List<Booking> bookings = [];
      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data();

        // 사용자 정보 가져오기
        final userDoc = await _users.doc(data['userId']).get();
        final userData = userDoc.data() as Map<String, dynamic>?;
        final userName = userData?['name'] ?? '알 수 없는 사용자';

        final booking = Booking(
          id: doc.id,
          userId: data['userId'] ?? '',
          meetingId: data['meetingId'] ?? '',
          bookingDate: (data['bookingDate'] as Timestamp).toDate(),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          status: _parseBookingStatus(data['status']),
          bookingNumber: data['bookingNumber'] ?? '',
          amount: (data['amount'] ?? 0).toDouble(),
          userName: userName,
          rank: data['rank'],
        );

        bookings.add(booking);
      }

      return bookings;
    } catch (e) {
      if (kDebugMode) {
        print('모임 예약 목록 가져오기 실패: $e');
      }
      rethrow;
    }
  }

  // 예약 상태 업데이트 (승인/거절)
  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('예약 상태 업데이트 실패: $e');
      }
      rethrow;
    }
  }

  // 참가자 순위 업데이트
  Future<void> updateBookingRank(String bookingId, int rank) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'rank': rank,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('참가자 순위 업데이트 실패: $e');
      }
      rethrow;
    }
  }

  // 예약 상태 파싱 헬퍼 메서드
  BookingStatus _parseBookingStatus(String? status) {
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

  // ========== 장소 정보 메서드들 ==========

  // 장소 ID로 장소 정보 가져오기
  Future<Venue?> getVenueById(String venueId) async {
    try {
      print('🏢 장소 ID로 장소 정보 찾는 중: $venueId');

      // _location 접미사 처리
      String actualVenueId = venueId;
      if (venueId.endsWith('_location')) {
        actualVenueId = venueId.replaceAll('_location', '');
        print('🏢 _location 접미사 제거: $venueId -> $actualVenueId');
      }

      // 1. venues 컬렉션에서 먼저 찾기
      final venuesDoc = await _venues.doc(actualVenueId).get();
      if (venuesDoc.exists) {
        print('🏢 venues 컬렉션에서 장소 정보 찾음');
        return Venue.fromMap(
          venuesDoc.id,
          venuesDoc.data() as Map<String, dynamic>,
        );
      }

      // 2. locations 컬렉션에서 찾기
      final locationsDoc = await _locations.doc(actualVenueId).get();
      if (locationsDoc.exists) {
        print('🏢 locations 컬렉션에서 장소 정보 찾음');
        final data = locationsDoc.data() as Map<String, dynamic>;
        return _parseVenueFromLocationData(locationsDoc.id, data);
      }

      print('🏢 장소 ID $venueId (실제: $actualVenueId) 를 찾을 수 없음');
      return null;
    } catch (e) {
      print('🚨 장소 정보 가져오기 실패: $e');
      return null;
    }
  }

  // locations 컬렉션 데이터를 Venue 객체로 변환
  Venue? _parseVenueFromLocationData(String id, Map<String, dynamic> data) {
    try {
      // 다양한 필드명 지원
      final name =
          data['cafeName'] ??
          data['businessName'] ??
          data['storeName'] ??
          data['name'] ??
          data['title'] ??
          '이름 없음';

      final address =
          data['address'] ?? data['location'] ?? data['addr'] ?? '주소 없음';

      if (name == '이름 없음' && address == '주소 없음') {
        return null; // 유효하지 않은 데이터
      }

      // 영업시간 처리 - 문자열과 리스트 모두 지원
      List<String> operatingHours = [];
      if (data['businessHours'] != null) {
        operatingHours = [data['businessHours'].toString()];
      } else if (data['operatingHours'] != null) {
        if (data['operatingHours'] is List) {
          operatingHours = List<String>.from(data['operatingHours']);
        } else {
          operatingHours = [data['operatingHours'].toString()];
        }
      }

      // 이미지 URL 처리
      List<String> imageUrls = [];
      if (data['images'] != null && data['images'] is List) {
        imageUrls = List<String>.from(data['images']);
      } else if (data['imageUrls'] != null && data['imageUrls'] is List) {
        imageUrls = List<String>.from(data['imageUrls']);
      } else if (data['imageUrl'] != null) {
        imageUrls = [data['imageUrl'].toString()];
      }

      // 메뉴 데이터 처리
      List<VenueMenu> menuList = [];
      if (data['menus'] != null && data['menus'] is List) {
        try {
          menuList = (data['menus'] as List<dynamic>)
              .map((item) => VenueMenu.fromMap(item as Map<String, dynamic>))
              .toList();
        } catch (e) {
          print('🚨 메뉴 파싱 오류: $e');
        }
      }

      return Venue(
        id: id,
        name: name,
        address: address,
        phone: data['phone']?.toString() ?? data['contact']?.toString() ?? '',
        website: data['website']?.toString(),
        instagram:
            data['instagramUrl']?.toString() ?? data['instagram']?.toString(),
        operatingHours: operatingHours,
        imageUrls: imageUrls,
        menu: menuList,
        hostId:
            data['hostId']?.toString() ??
            data['userId']?.toString() ??
            data['uid']?.toString() ??
            data['createdBy']?.toString() ??
            '',
        createdAt:
            (data['submittedAt'] as Timestamp?)?.toDate() ??
            (data['createdAt'] as Timestamp?)?.toDate() ??
            DateTime.now(),
      );
    } catch (e) {
      print('🚨 Venue 파싱 오류 ($id): $e');
      return null;
    }
  }

  // 호스트의 장소 정보 가져오기
  Future<Venue?> getVenueByHostId(String hostId) async {
    try {
      // 1. venues 컬렉션에서 먼저 찾기
      final venuesSnapshot = await _venues
          .where('hostId', isEqualTo: hostId)
          .limit(1)
          .get();

      if (venuesSnapshot.docs.isNotEmpty) {
        final doc = venuesSnapshot.docs.first;
        return Venue.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }

      // 2. locations 컬렉션에서 찾기
      return await _getVenueFromLocations(hostId);
    } catch (e) {
      if (kDebugMode) {
        print('장소 정보 가져오기 실패: $e');
      }
      rethrow;
    }
  }

  // locations 컬렉션에서 장소 정보 가져오기
  Future<Venue?> _getVenueFromLocations(String hostId) async {
    try {
      print('🏢 locations 컬렉션에서 장소 정보 찾는 중: $hostId');

      // 다양한 사용자 ID 필드로 검색
      final userIdFields = ['hostId', 'userId', 'uid', 'applicantId'];

      for (String field in userIdFields) {
        final querySnapshot = await _locations
            .where(field, isEqualTo: hostId)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final doc = querySnapshot.docs.first;
          final data = doc.data() as Map<String, dynamic>;

          print('🏢 Found location data with field "$field": ${doc.id}');
          print('🏢 Location data keys: ${data.keys.toList()}');

          // 다양한 필드명으로 장소 정보 찾기
          String? venueName;
          String? venueAddress;

          // 이름 필드 찾기
          final nameFields = [
            'cafeName',
            'businessName',
            'storeName',
            'name',
            'title',
          ];
          for (String nameField in nameFields) {
            if (data.containsKey(nameField) &&
                data[nameField] != null &&
                data[nameField].toString().isNotEmpty) {
              venueName = data[nameField].toString();
              break;
            }
          }

          // 주소 필드 찾기
          final addressFields = ['address', 'location', 'addr'];
          for (String addressField in addressFields) {
            if (data.containsKey(addressField) &&
                data[addressField] != null &&
                data[addressField].toString().isNotEmpty) {
              venueAddress = data[addressField].toString();
              break;
            }
          }

          // 이름이나 주소가 있으면 Venue 객체 생성
          if (venueName != null || venueAddress != null) {
            // 메뉴 데이터 처리
            List<VenueMenu> menuList = [];
            if (data.containsKey('menuItems') && data['menuItems'] is List) {
              try {
                menuList = (data['menuItems'] as List<dynamic>)
                    .map(
                      (item) => VenueMenu.fromMap(item as Map<String, dynamic>),
                    )
                    .toList();
                print('🍽️ 메뉴 ${menuList.length}개 파싱 완료');
              } catch (e) {
                print('🚨 Error parsing menu items: $e');
              }
            } else if (data.containsKey('menu') && data['menu'] is List) {
              try {
                menuList = (data['menu'] as List<dynamic>)
                    .map(
                      (item) => VenueMenu.fromMap(item as Map<String, dynamic>),
                    )
                    .toList();
                print('🍽️ 메뉴 ${menuList.length}개 파싱 완료 (menu 필드)');
              } catch (e) {
                print('🚨 Error parsing menu from menu field: $e');
              }
            }

            // 영업시간 처리 - 안전한 타입 체크
            List<String> operatingHours = [];
            if (data['businessHours'] != null) {
              operatingHours = [data['businessHours'].toString()];
            } else if (data['operatingHours'] != null) {
              if (data['operatingHours'] is List) {
                operatingHours = List<String>.from(data['operatingHours']);
              } else {
                operatingHours = [data['operatingHours'].toString()];
              }
            }

            // 이미지 URL 처리 - 안전한 타입 체크
            List<String> imageUrls = [];
            if (data['images'] != null && data['images'] is List) {
              imageUrls = List<String>.from(data['images']);
            } else if (data['imageUrls'] != null && data['imageUrls'] is List) {
              imageUrls = List<String>.from(data['imageUrls']);
            } else if (data['imageUrl'] != null) {
              imageUrls = [data['imageUrl'].toString()];
            }

            return Venue(
              id: doc.id,
              name: venueName ?? '이름 없음',
              address: venueAddress ?? '주소 없음',
              phone:
                  data['phone']?.toString() ??
                  data['contact']?.toString() ??
                  '',
              website: data['website']?.toString(),
              instagram:
                  data['instagramUrl']?.toString() ??
                  data['instagram']?.toString(),
              operatingHours: operatingHours,
              imageUrls: imageUrls,
              menu: menuList,
              hostId: data['createdBy']?.toString() ?? hostId,
              createdAt:
                  (data['submittedAt'] as Timestamp?)?.toDate() ??
                  (data['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
            );
          }
        }
      }

      print('🏢 locations 컬렉션에서 장소 정보를 찾을 수 없음');
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('🚨 locations에서 장소 정보 가져오기 실패: $e');
      }
      return null;
    }
  }

  // host_applications 컬렉션에서 장소 정보 가져오기 (백업용)
  Future<Venue?> _getVenueFromHostApplications(String hostId) async {
    try {
      final querySnapshot = await _hostApplications
          .where('hostId', isEqualTo: hostId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;

      // host_applications의 venue 필드에서 장소 정보 추출
      final venueData = data['venue'] as Map<String, dynamic>?;
      if (venueData == null) {
        return null;
      }

      // Venue 객체로 변환
      return Venue(
        id: doc.id,
        name: venueData['name'] ?? '',
        address: venueData['address'] ?? '',
        phone: venueData['phone'] ?? '',
        website: venueData['website'],
        instagram: venueData['instagram'],
        operatingHours: List<String>.from(venueData['operatingHours'] ?? []),
        imageUrls: List<String>.from(venueData['imageUrls'] ?? []),
        menu:
            (venueData['menu'] as List<dynamic>?)
                ?.map((item) => VenueMenu.fromMap(item))
                .toList() ??
            [],
        hostId: hostId,
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('host_applications에서 장소 정보 가져오기 실패: $e');
      }
      return null;
    }
  }

  // 호스트의 장소들 가져오기
  Future<List<Venue>> getHostVenues(String hostId) async {
    try {
      print('Getting venues for host: $hostId');

      // venues 컬렉션에서 hostId로 검색
      final venuesSnapshot = await _venues
          .where('hostId', isEqualTo: hostId)
          .get();

      List<Venue> venues = [];

      // venues 컬렉션에서 찾은 장소들 추가
      for (var doc in venuesSnapshot.docs) {
        venues.add(Venue.fromMap(doc.id, doc.data() as Map<String, dynamic>));
      }
      print('Found ${venues.length} venues in venues collection');

      // 🔍 디버깅: 모든 host_applications 문서를 확인
      final allApplicationsSnapshot = await _hostApplications.get();
      print(
        'Total host applications in collection: ${allApplicationsSnapshot.docs.length}',
      );

      for (var doc in allApplicationsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        print('Document ${doc.id} fields: ${data?.keys.toList()}');

        // 사용자 ID 관련 필드들 확인
        final userIdFields = ['hostId', 'userId', 'uid', 'applicantId', 'user'];
        for (String field in userIdFields) {
          if (data?.containsKey(field) == true) {
            print('Found user field "$field": ${data![field]}');
          }
        }

        // 현재 사용자와 일치하는지 확인
        if (data != null) {
          for (String field in userIdFields) {
            if (data[field] == hostId) {
              print('🎯 FOUND MATCH! Document ${doc.id} has $field = $hostId');
            }
          }
        }
      }

      // locations 컬렉션에서 확인 (변경된 로직)
      final locationsSnapshot = await _locations
          .where('hostId', isEqualTo: hostId)
          .get();

      print('Found ${locationsSnapshot.docs.length} locations with hostId');

      // 다른 사용자 ID 필드로도 검색
      final alternativeFields = ['userId', 'uid', 'applicantId'];
      for (String field in alternativeFields) {
        final altSnapshot = await _locations
            .where(field, isEqualTo: hostId)
            .get();
        print('Found ${altSnapshot.docs.length} locations with $field');

        // 기존 결과에 추가
        for (var doc in altSnapshot.docs) {
          locationsSnapshot.docs.add(doc);
        }
      }

      // 실제 venue 데이터 처리
      print('Processing ${locationsSnapshot.docs.length} locations');
      for (var doc in locationsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        print('Processing location: ${doc.id}');
        print('Location data: $data');

        if (data == null) continue;

        bool venueFound = false;

        // 1. 중첩된 venue 객체들 확인
        final possibleVenueFields = [
          'venue',
          'venueInfo',
          'location',
          'place',
          'store',
          'business',
        ];

        for (String field in possibleVenueFields) {
          if (data.containsKey(field) && data[field] != null) {
            print('Found venue data in field "$field": ${data[field]}');
            final venueData = data[field] as Map<String, dynamic>?;
            if (venueData != null) {
              venues.add(
                Venue(
                  id: '${doc.id}_$field',
                  name:
                      venueData['name'] ??
                      venueData['businessName'] ??
                      venueData['storeName'] ??
                      venueData['cafeName'] ??
                      'Unknown',
                  address: venueData['address'] ?? venueData['location'] ?? '',
                  phone: venueData['phone'] ?? venueData['contact'] ?? '',
                  website: venueData['website'],
                  instagram:
                      venueData['instagram'] ?? venueData['instagramUrl'],
                  operatingHours: List<String>.from(
                    venueData['operatingHours'] ??
                            venueData['hours'] ??
                            venueData['businessHours'] != null
                        ? [venueData['businessHours']]
                        : [],
                  ),
                  imageUrls: List<String>.from(
                    venueData['imageUrls'] ?? venueData['images'] ?? [],
                  ),
                  menu:
                      (venueData['menu'] ??
                              venueData['menuItems'] as List<dynamic>?)
                          ?.map((item) => VenueMenu.fromMap(item))
                          .toList() ??
                      [],
                  hostId: hostId,
                  createdAt:
                      (data['createdAt'] as Timestamp?)?.toDate() ??
                      DateTime.now(),
                ),
              );
              venueFound = true;
              break; // 찾았으면 다른 필드는 확인하지 않음
            }
          }
        }

        // 2. 직접 필드들 확인 (cafeName, address 등이 최상위 레벨에 있는 경우)
        if (!venueFound &&
            (data.containsKey('cafeName') ||
                data.containsKey('address') ||
                data.containsKey('businessName'))) {
          print('Found direct venue fields in location');

          // menuItems 처리
          List<VenueMenu> menuList = [];
          if (data.containsKey('menuItems') && data['menuItems'] is List) {
            try {
              menuList = (data['menuItems'] as List<dynamic>)
                  .map(
                    (item) => VenueMenu.fromMap(item as Map<String, dynamic>),
                  )
                  .toList();
            } catch (e) {
              print('Error parsing menu items: $e');
            }
          }

          venues.add(
            Venue(
              id: doc.id,
              name:
                  data['cafeName'] ??
                  data['businessName'] ??
                  data['storeName'] ??
                  'Unknown',
              address: data['address'] ?? '',
              phone: data['phone'] ?? data['contact'] ?? '',
              website: data['website'],
              instagram: data['instagramUrl'] ?? data['instagram'],
              operatingHours: data['businessHours'] != null
                  ? [data['businessHours']]
                  : [],
              imageUrls: List<String>.from(data['images'] ?? []),
              menu: menuList,
              hostId: hostId,
              createdAt:
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            ),
          );
          print(
            'Added venue from direct fields: ${data['cafeName'] ?? data['businessName']}',
          );
          venueFound = true;
        }
      }

      print('Found ${venues.length} total venues for host $hostId');
      return venues;
    } catch (e) {
      print('Error getting host venues: $e');
      return [];
    }
  }

  // 모든 장소 데이터 가져오기 (venues 컬렉션)
  Future<List<Venue>> getAllVenues() async {
    try {
      print('🏢 모든 venues 컬렉션 데이터 가져오는 중...');
      final venuesSnapshot = await _venues.get();

      List<Venue> venues = [];
      for (var doc in venuesSnapshot.docs) {
        try {
          final venue = Venue.fromMap(
            doc.id,
            doc.data() as Map<String, dynamic>,
          );
          venues.add(venue);
        } catch (e) {
          print('🚨 Venue 파싱 오류 (${doc.id}): $e');
        }
      }

      print('🏢 venues 컬렉션에서 ${venues.length}개 장소 로드 완료');
      return venues;
    } catch (e) {
      print('🚨 getAllVenues 오류: $e');
      return [];
    }
  }

  // locations 컬렉션에서 특정 hostId로 장소 찾기 (디버깅용)
  Future<Venue?> findVenueInLocationsDebug(String hostId) async {
    try {
      print('🏢 locations 컬렉션에서 직접 검색 시도 (hostId: $hostId)');

      // locations 컬렉션의 모든 문서를 확인
      final locationsSnapshot = await _locations.get();
      print('🏢 locations 컬렉션에 ${locationsSnapshot.docs.length}개 문서 있음');

      for (var doc in locationsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('🏢 Location 문서 ${doc.id}: ${data.keys.toList()}');
        print('🏢 전체 데이터: $data');

        // 호스트 ID와 매칭되는지 확인
        final userIdFields = [
          'hostId',
          'userId',
          'uid',
          'applicantId',
          'createdBy',
        ];
        for (String field in userIdFields) {
          print('🏢 확인 중: $field = ${data[field]}, 찾는 hostId = $hostId');
          if (data[field] == hostId) {
            print('🏢 매칭되는 location 찾음! 필드: $field, 값: ${data[field]}');

            // Venue 객체 생성
            final venueName =
                data['title'] ??
                data['cafeName'] ??
                data['businessName'] ??
                data['storeName'] ??
                data['name'] ??
                '이름 없음';
            final venueAddress = data['address'] ?? data['location'] ?? '주소 없음';

            // 메뉴 데이터 처리
            List<VenueMenu> menuList = [];
            if (data.containsKey('menus') && data['menus'] is List) {
              try {
                menuList = (data['menus'] as List<dynamic>).map((item) {
                  final menuItem = item as Map<String, dynamic>;
                  return VenueMenu(
                    name: menuItem['name']?.toString() ?? '',
                    description: menuItem['description']?.toString() ?? '',
                    price: (menuItem['price'] ?? 0).toDouble(),
                    imageUrl: menuItem['imageUrl']?.toString(),
                  );
                }).toList();
                print('🍽️ 디버그 메서드에서 메뉴 ${menuList.length}개 파싱 완료 (menus 필드)');
              } catch (e) {
                print('🚨 디버그 메서드 menus 필드 파싱 오류: $e');
                print('🚨 menus 데이터: ${data['menus']}');
              }
            } else if (data.containsKey('menuItems') &&
                data['menuItems'] is List) {
              try {
                menuList = (data['menuItems'] as List<dynamic>)
                    .map(
                      (item) => VenueMenu.fromMap(item as Map<String, dynamic>),
                    )
                    .toList();
                print('🍽️ 디버그 메서드에서 메뉴 ${menuList.length}개 파싱 완료');
              } catch (e) {
                print('🚨 디버그 메서드 메뉴 파싱 오류: $e');
              }
            } else if (data.containsKey('menu') && data['menu'] is List) {
              try {
                menuList = (data['menu'] as List<dynamic>)
                    .map(
                      (item) => VenueMenu.fromMap(item as Map<String, dynamic>),
                    )
                    .toList();
                print('🍽️ 디버그 메서드에서 메뉴 ${menuList.length}개 파싱 완료 (menu 필드)');
              } catch (e) {
                print('🚨 디버그 메서드 menu 필드 파싱 오류: $e');
              }
            }

            // 영업시간 처리 - 문자열과 리스트 모두 지원
            List<String> operatingHours = [];
            if (data['businessHours'] != null) {
              operatingHours = [data['businessHours'].toString()];
            } else if (data['operatingHours'] != null) {
              if (data['operatingHours'] is List) {
                operatingHours = List<String>.from(data['operatingHours']);
              } else {
                operatingHours = [data['operatingHours'].toString()];
              }
            }

            // 전화번호 처리 (실제 데이터 구조에 맞게)
            final phone = data['phone']?.toString() ?? '';

            // 웹사이트 처리 (실제 데이터 구조에 맞게)
            final website = data['website']?.toString() ?? '';

            // 인스타그램은 웹사이트에서 추출하거나 별도 필드 확인
            String instagram = '';
            if (website.contains('instagram')) {
              instagram = website;
            } else if (data['instagram'] != null) {
              instagram = data['instagram'].toString();
            }

            // 이미지 처리 (실제 데이터 구조 확인 필요)
            List<String> imageUrls = [];
            if (data['images'] != null && data['images'] is List) {
              imageUrls = List<String>.from(data['images']);
            } else if (data['imageUrl'] != null) {
              // 단일 이미지 URL이 있는 경우
              imageUrls = [data['imageUrl'].toString()];
            }

            print('🏢 파싱된 데이터:');
            print('  - 이름: $venueName');
            print('  - 주소: $venueAddress');
            print('  - 영업시간: $operatingHours');
            print('  - 전화번호: $phone');
            print('  - 인스타그램: $instagram');
            print('  - 이미지: ${imageUrls.length}개');
            print('  - 메뉴: ${menuList.length}개');

            // "커피흐름" 장소 특별 확인
            if (venueName.contains('커피흐름') || venueAddress.contains('커피흐름')) {
              print('🏢 ⭐ 커피흐름 장소 발견! ID: ${doc.id}');
              print('🏢 ⭐ 커피흐름 - 이름: $venueName');
              print('🏢 ⭐ 커피흐름 - 주소: $venueAddress');
              print('🏢 ⭐ 커피흐름 - hostId: $hostId');
            }

            final venue = Venue(
              id: doc.id,
              name: venueName,
              address: venueAddress,
              phone: phone,
              website: website,
              instagram: instagram,
              operatingHours: operatingHours,
              imageUrls: imageUrls,
              menu: menuList,
              hostId: hostId,
              createdAt: DateTime.now(),
            );

            print('🏢 Venue 객체 생성 완료: ${venue.name} - ${venue.address}');
            return venue;
          }
        }
      }

      print('🏢 locations 컬렉션에서 매칭되는 장소를 찾을 수 없음');
      return null;
    } catch (e) {
      print('🚨 locations 컬렉션 직접 검색 중 오류: $e');
      return null;
    }
  }

  // 모든 locations에서 장소 데이터 가져오기
  Future<List<Venue>> getAllLocationVenues() async {
    try {
      print('🏢 모든 locations 데이터에서 장소 가져오는 중...');
      final locationsSnapshot = await _locations.get();

      List<Venue> venues = [];

      for (var doc in locationsSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;

          print('🏢 Processing location: ${doc.id}');
          print('🏢 Location data keys: ${data.keys.toList()}');
          print('🏢 Location data: $data');

          // 다양한 필드명으로 장소 정보 찾기
          String? venueName;
          String? venueAddress;

          // 이름 필드 찾기
          final nameFields = [
            'cafeName',
            'businessName',
            'storeName',
            'name',
            'title',
          ];
          for (String field in nameFields) {
            if (data.containsKey(field) &&
                data[field] != null &&
                data[field].toString().isNotEmpty) {
              venueName = data[field].toString();
              print('🏢 Found name in field "$field": $venueName');
              break;
            }
          }

          // 주소 필드 찾기
          final addressFields = ['address', 'location', 'addr'];
          for (String field in addressFields) {
            if (data.containsKey(field) &&
                data[field] != null &&
                data[field].toString().isNotEmpty) {
              venueAddress = data[field].toString();
              print('🏢 Found address in field "$field": $venueAddress');
              break;
            }
          }

          // 이름이나 주소 중 하나라도 있으면 장소로 추가
          if (venueName != null || venueAddress != null) {
            final venue = Venue(
              id: '${doc.id}_location',
              name: venueName ?? '이름 없음',
              address: venueAddress ?? '주소 없음',
              phone:
                  data['phone']?.toString() ??
                  data['contact']?.toString() ??
                  '',
              website: data['website']?.toString(),
              instagram:
                  data['instagramUrl']?.toString() ??
                  data['instagram']?.toString(),
              operatingHours: data['businessHours'] != null
                  ? [data['businessHours']]
                  : (data['operatingHours'] != null &&
                        data['operatingHours'] is List)
                  ? List<String>.from(data['operatingHours'])
                  : [],
              imageUrls: data['images'] != null && data['images'] is List
                  ? List<String>.from(data['images'])
                  : (data['imageUrls'] != null && data['imageUrls'] is List)
                  ? List<String>.from(data['imageUrls'])
                  : [],
              menu: [], // 메뉴 데이터가 있다면 추후 추가
              hostId:
                  data['userId']?.toString() ??
                  data['hostId']?.toString() ??
                  '',
              createdAt:
                  (data['submittedAt'] as Timestamp?)?.toDate() ??
                  (data['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
            );
            venues.add(venue);
            print('🏢 장소 추가: ${venue.name} - ${venue.address}');
          } else {
            print('🏢 장소 정보를 찾을 수 없음 (이름/주소 없음)');
          }
        } catch (e) {
          print('🚨 Location 처리 오류 (${doc.id}): $e');
        }
      }

      print('🏢 locations에서 ${venues.length}개 장소 로드 완료');
      return venues;
    } catch (e) {
      print('🚨 getAllLocationVenues 오류: $e');
      return [];
    }
  }

  // ========== 테스트용 메서드들 ==========

  // 특정 모임에 게임 데이터 추가 (테스트용)
  Future<void> updateMeetingWithGameData(
    String meetingId,
    String gameId, {
    String? coverImageUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'gameId': gameId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (coverImageUrl != null) {
        updateData['coverImageUrl'] = coverImageUrl;
      }

      await _meetings.doc(meetingId).update(updateData);

      if (kDebugMode) {
        print('✅ 모임 업데이트 완료: $meetingId -> 게임 ID: $gameId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 모임 업데이트 실패: $e');
      }
      rethrow;
    }
  }

  // 게임 이미지 업데이트 (테스트용)
  Future<void> updateGameImages(String gameId, List<String> images) async {
    try {
      await _games.doc(gameId).update({
        'images': images,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ 게임 이미지 업데이트 완료: $gameId (${images.length}개)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 게임 이미지 업데이트 실패: $e');
      }
      rethrow;
    }
  }

  // 모임 상태 업데이트
  Future<void> updateMeetingStatus(String meetingId, String status) async {
    try {
      await _meetings.doc(meetingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ 모임 상태 업데이트 완료: $meetingId -> $status');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 모임 상태 업데이트 실패: $e');
      }
      rethrow;
    }
  }

  // 예약 상태를 대기중으로 생성
  Future<String> createBookingWithPendingStatus(
    String meetingId,
    String userId,
    String userName,
    double amount, {
    String? bookingNumber,
  }) async {
    try {
      final finalBookingNumber =
          bookingNumber ?? 'BK${DateTime.now().millisecondsSinceEpoch}';

      final booking = {
        'meetingId': meetingId,
        'userId': userId,
        'userName': userName,
        'bookingDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending', // 기본값을 대기중으로 설정
        'bookingNumber': finalBookingNumber,
        'amount': amount,
        'rank': null,
      };

      final docRef = await _firestore.collection('bookings').add(booking);

      if (kDebugMode) {
        print('✅ 대기중 예약 생성 완료: ${docRef.id}');
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 대기중 예약 생성 실패: $e');
      }
      rethrow;
    }
  }

  // 예약 승인/거절
  Future<void> updateBookingApprovalStatus(
    String bookingId,
    String status, // 'approved' 또는 'rejected'
  ) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status,
        'approvedAt': status == 'approved'
            ? FieldValue.serverTimestamp()
            : null,
        'rejectedAt': status == 'rejected'
            ? FieldValue.serverTimestamp()
            : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 승인/거절 시 모임의 참가자 수 업데이트
      if (status == 'approved' || status == 'rejected') {
        await _updateMeetingParticipantCount(bookingId);
      }

      if (kDebugMode) {
        print('✅ 예약 승인/거절 완료: $bookingId -> $status');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 예약 승인/거절 실패: $e');
      }
      rethrow;
    }
  }

  // 모임의 실제 참가자 수 업데이트 (승인된 사용자와 확정된 사용자 모두 카운트)
  Future<void> _updateMeetingParticipantCount(String bookingId) async {
    try {
      // 해당 예약의 모임 ID 가져오기
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();
      if (!bookingDoc.exists) return;

      final bookingData = bookingDoc.data() as Map<String, dynamic>;
      final meetingId = bookingData['meetingId'] as String;

      // 해당 모임의 승인된 예약 및 확정된 예약 수 계산
      final confirmedBookingsSnapshot = await _firestore
          .collection('bookings')
          .where('meetingId', isEqualTo: meetingId)
          .where('status', whereIn: ['approved', 'confirmed'])
          .get();

      final confirmedCount = confirmedBookingsSnapshot.docs.length;

      // 모임 문서의 currentParticipants 업데이트
      await _meetings.doc(meetingId).update({
        'currentParticipants': confirmedCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ 모임 참가자 수 업데이트: $meetingId -> $confirmedCount명');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 모임 참가자 수 업데이트 실패: $e');
      }
    }
  }

  // 모임 종료 시간 계산
  Future<DateTime?> getMeetingEndTime(Meeting meeting) async {
    try {
      if (meeting.gameId != null && meeting.gameId!.isNotEmpty) {
        final game = await getGameById(meeting.gameId!);
        if (game != null && game.estimatedDuration > 0) {
          return meeting.scheduledDate.add(
            Duration(minutes: game.estimatedDuration),
          );
        }
      }

      // 게임 정보가 없으면 기본 3시간으로 계산
      return meeting.scheduledDate.add(const Duration(hours: 3));
    } catch (e) {
      if (kDebugMode) {
        print('❌ 모임 종료 시간 계산 실패: $e');
      }
      // 에러 시 기본 3시간으로 계산
      return meeting.scheduledDate.add(const Duration(hours: 3));
    }
  }

  // 만료된 모임들의 상태를 자동으로 업데이트
  Future<void> updateExpiredMeetingsStatus() async {
    try {
      final now = DateTime.now();

      // recruiting 또는 ongoing 상태인 모임들 중에서 종료 시간이 지난 것들 찾기
      final snapshot = await _meetings
          .where('status', whereIn: ['recruiting', 'ongoing'])
          .where('isActive', isEqualTo: true)
          .get();

      List<Future<void>> updateTasks = [];

      for (var doc in snapshot.docs) {
        try {
          final meetingData = doc.data() as Map<String, dynamic>;
          final meeting = Meeting.fromMap(doc.id, meetingData);

          final endTime = await getMeetingEndTime(meeting);
          if (endTime != null && now.isAfter(endTime)) {
            // 종료 시간이 지났으면 상태를 completed로 업데이트
            updateTasks.add(updateMeetingStatus(doc.id, 'completed'));

            if (kDebugMode) {
              print('🔄 자동 상태 업데이트: ${meeting.title} -> completed');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ 모임 상태 확인 중 오류 (${doc.id}): $e');
          }
        }
      }

      // 모든 업데이트 작업을 병렬로 실행
      await Future.wait(updateTasks);

      if (kDebugMode) {
        print('✅ 만료된 모임 상태 업데이트 완료: ${updateTasks.length}개');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 만료된 모임 상태 업데이트 실패: $e');
      }
    }
  }

  // 특정 모임의 상태를 현재 시간 기준으로 확인 및 업데이트
  Future<String> checkAndUpdateMeetingStatus(String meetingId) async {
    try {
      final doc = await _meetings.doc(meetingId).get();
      if (!doc.exists) {
        throw Exception('모임을 찾을 수 없습니다.');
      }

      final meetingData = doc.data() as Map<String, dynamic>;
      final meeting = Meeting.fromMap(meetingId, meetingData);
      final now = DateTime.now();

      // 이미 completed 상태면 그대로 반환
      if (meeting.status == 'completed') {
        return 'completed';
      }

      // 종료 시간 계산
      final endTime = await getMeetingEndTime(meeting);
      if (endTime != null && now.isAfter(endTime)) {
        // 종료 시간이 지났으면 상태를 completed로 업데이트
        await updateMeetingStatus(meetingId, 'completed');
        return 'completed';
      }

      // 시작 시간이 지났으면 ongoing
      if (now.isAfter(meeting.scheduledDate) &&
          meeting.status == 'recruiting') {
        await updateMeetingStatus(meetingId, 'ongoing');
        return 'ongoing';
      }

      // 아직 시작 전이면 recruiting 유지
      return meeting.status;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 모임 상태 확인/업데이트 실패: $e');
      }
      rethrow;
    }
  }

  // 호스트의 완료된 모임 목록 가져오기
  Stream<List<Meeting>> getHostCompletedMeetings() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _meetings
        .where('hostId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .where('isActive', isEqualTo: true)
        .orderBy('scheduledDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    Meeting.fromMap(doc.id, doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  // 사용자의 완료된 모임 목록 가져오기 (참가한 모임)
  Stream<List<Meeting>> getUserCompletedMeetings() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['approved', 'confirmed'])
        .snapshots()
        .asyncMap((snapshot) async {
          List<Meeting> completedMeetings = [];

          for (var doc in snapshot.docs) {
            final bookingData = doc.data();
            final meetingId = bookingData['meetingId'] as String;

            try {
              final meetingDoc = await _meetings.doc(meetingId).get();
              if (meetingDoc.exists) {
                final meetingData = meetingDoc.data() as Map<String, dynamic>;
                final meeting = Meeting.fromMap(meetingId, meetingData);

                // 완료된 모임만 추가
                if (meeting.status == 'completed' && meeting.isActive) {
                  completedMeetings.add(meeting);
                }
              }
            } catch (e) {
              print('완료된 모임 로드 실패: $e');
            }
          }

          // 최신 순으로 정렬
          completedMeetings.sort(
            (a, b) => b.scheduledDate.compareTo(a.scheduledDate),
          );
          return completedMeetings;
        });
  }
}
