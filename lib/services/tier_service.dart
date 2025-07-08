import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class TierService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 게임 결과에 따른 사용자 티어 점수 업데이트
  Future<void> updateUserTierScore(String userId, int rank) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(
          _firestore.collection('users').doc(userId),
        );

        if (!userDoc.exists) {
          throw Exception('사용자를 찾을 수 없습니다.');
        }

        final userData = userDoc.data()!;
        final currentUser = UserModel.fromMap(userId, userData);

        // 순위에 따른 점수 증가
        final updatedUser = currentUser.addTierScore(rank);

        // Firestore에 업데이트
        transaction.update(_firestore.collection('users').doc(userId), {
          'tierScore': updatedUser.tierScore,
          'tier': updatedUser.tier,
        });
      });
    } catch (e) {
      throw Exception('티어 점수 업데이트 실패: $e');
    }
  }

  /// 여러 사용자의 티어 점수를 한번에 업데이트 (게임 종료 시)
  Future<void> updateMultipleUserTierScores(
    Map<String, int> userRankings,
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {
        for (final entry in userRankings.entries) {
          final userId = entry.key;
          final rank = entry.value;

          final userDoc = await transaction.get(
            _firestore.collection('users').doc(userId),
          );

          if (userDoc.exists) {
            final userData = userDoc.data()!;
            final currentUser = UserModel.fromMap(userId, userData);
            final updatedUser = currentUser.addTierScore(rank);

            transaction.update(_firestore.collection('users').doc(userId), {
              'tierScore': updatedUser.tierScore,
              'tier': updatedUser.tier,
            });
          }
        }
      });
    } catch (e) {
      throw Exception('다중 사용자 티어 점수 업데이트 실패: $e');
    }
  }

  /// 사용자의 현재 티어 정보 조회
  Future<Map<String, dynamic>> getUserTierInfo(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw Exception('사용자를 찾을 수 없습니다.');
      }

      final userData = userDoc.data()!;
      final user = UserModel.fromMap(userId, userData);

      return {
        'tier': user.tier,
        'tierDisplayName': user.tierDisplayName,
        'tierScore': user.tierScore,
        'pointsToNextTier': user.pointsToNextTier,
        'tierIconPath': user.tierIconPath,
      };
    } catch (e) {
      throw Exception('티어 정보 조회 실패: $e');
    }
  }

  /// 티어별 사용자 순위 조회
  Future<List<Map<String, dynamic>>> getTierRankings({int limit = 50}) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('tierScore', descending: true)
          .orderBy('tier', descending: false) // 같은 점수일 때 티어로 정렬
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        final user = UserModel.fromMap(doc.id, data);

        return {
          'userId': doc.id,
          'name': user.name,
          'tier': user.tier,
          'tierDisplayName': user.tierDisplayName,
          'tierScore': user.tierScore,
          'tierIconPath': user.tierIconPath,
        };
      }).toList();
    } catch (e) {
      throw Exception('티어 순위 조회 실패: $e');
    }
  }

  /// 특정 티어의 사용자 수 조회
  Future<Map<String, int>> getTierDistribution() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();

      final distribution = <String, int>{
        'clover': 0,
        'diamond': 0,
        'heart': 0,
        'spade': 0,
      };

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final tier = data['tier'] ?? 'clover';
        distribution[tier] = (distribution[tier] ?? 0) + 1;
      }

      return distribution;
    } catch (e) {
      throw Exception('티어 분포 조회 실패: $e');
    }
  }
}
