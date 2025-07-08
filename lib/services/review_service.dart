import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';
import 'firestore_service.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // 리뷰 작성
  Future<String> createReview(ReviewModel review) async {
    try {
      final docRef = _firestore.collection('reviews').doc();
      final reviewWithId = review.copyWith(id: docRef.id);

      await docRef.set(reviewWithId.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('리뷰 작성 실패: $e');
    }
  }

  // 특정 모임의 리뷰 목록 조회
  Future<List<ReviewModel>> getReviewsByMeeting(String meetingId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('meetingId', isEqualTo: meetingId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('리뷰 목록 조회 실패: $e');
    }
  }

  // 사용자의 리뷰 목록 조회
  Future<List<ReviewModel>> getReviewsByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('내 리뷰 목록 조회 실패: $e');
    }
  }

  // 특정 게임의 리뷰 목록 조회
  Future<List<ReviewModel>> getReviewsByGame(String gameId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('gameId', isEqualTo: gameId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('게임 리뷰 목록 조회 실패: $e');
    }
  }

  // 호스트별 리뷰 목록 조회
  Future<List<ReviewModel>> getReviewsByHost(String hostId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('hostId', isEqualTo: hostId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('호스트 리뷰 목록 조회 실패: $e');
    }
  }

  // 호스트의 별점 통계 조회
  Future<Map<String, dynamic>> getHostRatingStats(String hostId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('hostId', isEqualTo: hostId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalReviews': 0,
          'ratingCounts': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      final reviews = querySnapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data()))
          .toList();

      final ratingCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      double totalRating = 0;

      for (final review in reviews) {
        ratingCounts[review.rating] = (ratingCounts[review.rating] ?? 0) + 1;
        totalRating += review.rating;
      }

      final averageRating = totalRating / reviews.length;

      return {
        'averageRating': averageRating,
        'totalReviews': reviews.length,
        'ratingCounts': ratingCounts,
        'reviews': reviews,
      };
    } catch (e) {
      throw Exception('호스트 별점 통계 조회 실패: $e');
    }
  }

  // 사용자가 참여한 완료된 모임 중 리뷰 작성 가능한 목록 조회 (수정됨)
  Future<List<Map<String, dynamic>>> getReviewableMeetings(
    String userId,
  ) async {
    try {
      // 사용자의 모든 예약 목록 (완료된 것과 승인된 것 모두)
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['completed', 'approved'])
          .get();

      if (bookingsSnapshot.docs.isEmpty) return [];

      final allMeetingIds = bookingsSnapshot.docs
          .map((doc) => doc.data()['meetingId'] as String)
          .toSet()
          .toList();

      // 이미 리뷰 작성한 모임 목록
      final writtenReviews = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .get();

      final reviewedMeetingIds = writtenReviews.docs
          .map((doc) => doc.data()['meetingId'] as String)
          .toSet();

      // 모임 정보 확인하여 완료되고 리뷰 작성 가능한 모임들만 수집
      final List<Map<String, dynamic>> reviewableMeetings = [];

      for (String meetingId in allMeetingIds) {
        // 이미 리뷰 작성한 모임은 건너뛰기
        if (reviewedMeetingIds.contains(meetingId)) {
          continue;
        }

        final meetingDoc = await _firestore
            .collection('meetings')
            .doc(meetingId)
            .get();
        if (meetingDoc.exists) {
          final data = meetingDoc.data()!;
          final hasResults = data['hasResults'] ?? false;
          final isCompleted = data['isCompleted'] ?? false;
          final scheduledDate = (data['scheduledDate'] as Timestamp?)?.toDate();
          final title = data['title'] ?? '';

          // 결과가 있거나, 완료 표시되어 있거나, 예정된 날짜가 지난 경우
          if (hasResults ||
              isCompleted ||
              (scheduledDate != null &&
                  scheduledDate.isBefore(DateTime.now()))) {
            // venue 정보 가져오기
            String locationName = '';
            final venueId = data['venueId'];
            if (venueId != null && venueId.isNotEmpty) {
              try {
                final venue = await _firestoreService.getVenueById(venueId);
                locationName = venue?.name ?? data['location'] ?? '';
              } catch (e) {
                locationName = data['location'] ?? '';
              }
            } else {
              locationName = data['location'] ?? '';
            }

            reviewableMeetings.add({
              'id': meetingDoc.id,
              'title': title,
              'location': locationName,
              'date': scheduledDate ?? DateTime.now(),
              'imageUrl': data['coverImageUrl'] ?? data['imageUrl'] ?? '',
              'participants': data['participants'] ?? [],
              'hostId': data['hostId'] ?? '',
              'hostName': data['hostName'] ?? '',
            });
          }
        }
      }

      return reviewableMeetings;
    } catch (e) {
      throw Exception('리뷰 작성 가능한 모임 조회 실패: $e');
    }
  }

  // 리뷰 이미지 URL 저장 (향후 Firebase Storage 연동 시 사용)
  Future<List<String>> saveReviewImageUrls(List<String> imageUrls) async {
    try {
      // 현재는 단순히 URL 리스트를 반환
      // 향후 Firebase Storage 연동 시 실제 업로드 로직 추가
      return imageUrls;
    } catch (e) {
      throw Exception('이미지 URL 저장 실패: $e');
    }
  }

  // 도움이 돼요 투표
  Future<void> toggleHelpfulVote(String reviewId, String userId) async {
    try {
      final docRef = _firestore.collection('reviews').doc(reviewId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) throw Exception('리뷰를 찾을 수 없습니다.');

        final data = doc.data()!;
        final helpfulVotes = List<String>.from(data['helpfulVotes'] ?? []);

        if (helpfulVotes.contains(userId)) {
          helpfulVotes.remove(userId);
        } else {
          helpfulVotes.add(userId);
        }

        transaction.update(docRef, {'helpfulVotes': helpfulVotes});
      });
    } catch (e) {
      throw Exception('투표 처리 실패: $e');
    }
  }

  // 모임의 별점 통계 조회
  Future<Map<String, dynamic>> getRatingStats(String meetingId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('meetingId', isEqualTo: meetingId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalReviews': 0,
          'ratingCounts': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      final reviews = querySnapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data()))
          .toList();

      final ratingCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      double totalRating = 0;

      for (final review in reviews) {
        ratingCounts[review.rating] = (ratingCounts[review.rating] ?? 0) + 1;
        totalRating += review.rating;
      }

      final averageRating = totalRating / reviews.length;

      return {
        'averageRating': averageRating,
        'totalReviews': reviews.length,
        'ratingCounts': ratingCounts,
        'reviews': reviews,
      };
    } catch (e) {
      throw Exception('별점 통계 조회 실패: $e');
    }
  }

  // 리뷰 삭제
  Future<void> deleteReview(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).delete();
    } catch (e) {
      throw Exception('리뷰 삭제 실패: $e');
    }
  }

  // 베스트 리뷰 조회 (도움이 돼요 순)
  Future<List<ReviewModel>> getBestReviews(String meetingId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('meetingId', isEqualTo: meetingId)
          .get();

      final reviews = querySnapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data()))
          .toList();

      // 도움이 돼요 개수 순으로 정렬
      reviews.sort(
        (a, b) => b.helpfulVotes.length.compareTo(a.helpfulVotes.length),
      );

      return reviews;
    } catch (e) {
      throw Exception('베스트 리뷰 조회 실패: $e');
    }
  }

  // 사진 리뷰만 조회
  Future<List<ReviewModel>> getPhotoReviews(String meetingId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('meetingId', isEqualTo: meetingId)
          .orderBy('createdAt', descending: true)
          .get();

      final reviews = querySnapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data()))
          .where((review) => review.images.isNotEmpty)
          .toList();

      return reviews;
    } catch (e) {
      throw Exception('사진 리뷰 조회 실패: $e');
    }
  }
}
