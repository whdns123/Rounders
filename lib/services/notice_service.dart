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

  // 더미 데이터 생성 (개발 및 테스트용)
  Future<void> createDummyNotices() async {
    final dummyNotices = [
      NoticeModel(
        id: '',
        title: '게시판이 업데이트되었습니다.',
        content: '새로운 기능이 추가되었습니다. 확인해보세요!',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isNew: true,
      ),
      NoticeModel(
        id: '',
        title: '시스템 점검 안내',
        content: '매주 화요일 새벽 2시~4시 시스템 점검이 진행됩니다.',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        isNew: true,
      ),
      NoticeModel(
        id: '',
        title: '새로운 게임이 추가되었습니다',
        content: '흥미진진한 새 게임을 확인해보세요!',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        isNew: false,
      ),
      NoticeModel(
        id: '',
        title: '서비스 이용약관 변경 안내',
        content: '서비스 이용약관이 일부 변경되었습니다.',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        isNew: false,
      ),
      NoticeModel(
        id: '',
        title: '회원 혜택 안내',
        content: '회원 등급별 혜택이 추가되었습니다.',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        isNew: false,
      ),
    ];

    for (final notice in dummyNotices) {
      await createNotice(notice);
    }
  }
}
