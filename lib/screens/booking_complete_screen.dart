import 'package:flutter/material.dart';
import '../models/meeting.dart';
import 'booking_history_screen.dart';

class BookingCompleteScreen extends StatelessWidget {
  final Meeting meeting;
  final String bookingNumber;

  const BookingCompleteScreen({
    super.key,
    required this.meeting,
    required this.bookingNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        title: const Text(
          '예약완료',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // 체크 아이콘
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1DDE6B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 완료 메시지
                  const Column(
                    children: [
                      Text(
                        '예약이 완료되었습니다.',
                        style: TextStyle(
                          color: Color(0xFFF5F5F5),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '아직 모임 확정 전이며, 확정 시 알림으로 안내드릴게요.',
                        style: TextStyle(
                          color: Color(0xFFF5F5F5),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  // 예약내역 요약
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 구분선
                      Container(
                        width: double.infinity,
                        height: 8,
                        color: const Color(0xFF2E2E2E),
                      ),

                      const SizedBox(height: 16),

                      // 모임 카드
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            // 모임 이미지
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFF2E2E2E),
                                ),
                                image:
                                    ((meeting.coverImageUrl?.isNotEmpty ??
                                            false) ||
                                        (meeting.imageUrl?.isNotEmpty ?? false))
                                    ? DecorationImage(
                                        image: NetworkImage(
                                          (meeting.coverImageUrl?.isNotEmpty ==
                                                  true)
                                              ? meeting.coverImageUrl!
                                              : meeting.imageUrl!,
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: const Color(0xFF2E2E2E),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // 모임 정보
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    meeting.title,
                                    style: const TextStyle(
                                      color: Color(0xFFEAEAEA),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  const SizedBox(height: 16),

                                  // 위치 및 시간
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        color: Color(0xFFD6D6D6),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 2),
                                      Expanded(
                                        child: Text(
                                          '${meeting.location} • ${_formatDate(meeting.scheduledDate)}',
                                          style: const TextStyle(
                                            color: Color(0xFFD6D6D6),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 2),

                                  // 가격
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.payments_outlined,
                                        color: Color(0xFF8C8C8C),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${meeting.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                                        style: const TextStyle(
                                          color: Color(0xFFD6D6D6),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 환불 안내
                      const Text(
                        '*모집 인원이 미달일 경우 자동 취소 및 전액 환불됩니다.',
                        style: TextStyle(
                          color: Color(0xFF8C8C8C),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 하단 버튼들
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF111111),
            child: Row(
              children: [
                // 홈으로 가기 버튼
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF8C8C8C)),
                      backgroundColor: Colors.transparent,
                      foregroundColor: const Color(0xFFF5F5F5),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      '홈으로 가기',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // 예약내역 보기 버튼
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingHistoryScreen(
                            meeting: meeting,
                            bookingNumber: bookingNumber,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF44336),
                      foregroundColor: const Color(0xFFF5F5F5),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      '예약내역 보기',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.month}.${date.day}($weekday) ${date.hour}시 ${date.minute.toString().padLeft(2, '0')}분';
  }
}
