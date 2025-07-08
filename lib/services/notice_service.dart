import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notice_model.dart';

class NoticeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 공지사항 목록 조회
  Future<List<NoticeModel>> getNotices() async {
    try {
      final querySnapshot = await _firestore
          .collection('notices')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => NoticeModel.fromMap({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      throw Exception('공지사항 목록 조회 실패: $e');
    }
  }

  // 특정 공지사항 조회
  Future<NoticeModel?> getNoticeById(String noticeId) async {
    try {
      final doc = await _firestore.collection('notices').doc(noticeId).get();

      if (doc.exists) {
        return NoticeModel.fromMap({'id': doc.id, ...doc.data()!});
      }
      return null;
    } catch (e) {
      throw Exception('공지사항 조회 실패: $e');
    }
  }

  // 공지사항 생성 (관리자용)
  Future<String> createNotice(NoticeModel notice) async {
    try {
      final docRef = _firestore.collection('notices').doc();
      final noticeWithId = notice.copyWith(id: docRef.id);

      await docRef.set(noticeWithId.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('공지사항 생성 실패: $e');
    }
  }

  // 공지사항 수정 (관리자용)
  Future<void> updateNotice(NoticeModel notice) async {
    try {
      await _firestore
          .collection('notices')
          .doc(notice.id)
          .update(notice.toMap());
    } catch (e) {
      throw Exception('공지사항 수정 실패: $e');
    }
  }

  // 공지사항 삭제 (관리자용)
  Future<void> deleteNotice(String noticeId) async {
    try {
      await _firestore.collection('notices').doc(noticeId).delete();
    } catch (e) {
      throw Exception('공지사항 삭제 실패: $e');
    }
  }
}
