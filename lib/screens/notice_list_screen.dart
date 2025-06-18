import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notice_model.dart';
import '../services/notice_service.dart';
import 'notice_detail_screen.dart';

class NoticeListScreen extends StatefulWidget {
  const NoticeListScreen({super.key});

  @override
  State<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends State<NoticeListScreen> {
  final NoticeService _noticeService = NoticeService();
  List<NoticeModel> _notices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final notices = await _noticeService.getNotices();

      // 데이터가 없으면 더미 데이터 생성
      if (notices.isEmpty) {
        await _noticeService.createDummyNotices();
        final newNotices = await _noticeService.getNotices();
        setState(() {
          _notices = newNotices;
        });
      } else {
        setState(() {
          _notices = notices;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('공지사항을 불러오는데 실패했습니다: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '공지사항',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF44336)),
            )
          : _notices.isEmpty
          ? const Center(
              child: Text(
                '공지사항이 없습니다.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Pretendard',
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _notices.length,
              itemBuilder: (context, index) {
                final notice = _notices[index];
                return _buildNoticeItem(notice, index == _notices.length - 1);
              },
            ),
    );
  }

  Widget _buildNoticeItem(NoticeModel notice, bool isLast) {
    return GestureDetector(
      onTap: () => _navigateToNoticeDetail(notice),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Row(
              children: [
                // 왼쪽 콘텐츠
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목 + NEW 태그
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notice.title,
                              style: const TextStyle(
                                color: Color(0xFFF5F5F5),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                          ),
                          if (notice.isNew) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFCC9C5),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Color(0xFFF44336),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Pretendard',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      // 날짜
                      Text(
                        DateFormat('yyyy.MM.dd').format(notice.createdAt),
                        style: const TextStyle(
                          color: Color(0xFF8C8C8C),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                ),
                // 오른쪽 화살표
                const SizedBox(width: 16),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF8C8C8C),
                  size: 16,
                ),
              ],
            ),
            // 구분선 (마지막 아이템이 아닐 때만)
            if (!isLast) ...[
              const SizedBox(height: 20),
              Container(height: 1, color: const Color(0xFF2E2E2E)),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToNoticeDetail(NoticeModel notice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoticeDetailScreen(notice: notice),
      ),
    );
  }
}
