import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meeting.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'booking_history_screen.dart';

class BookingCompleteScreen extends StatefulWidget {
  final Meeting meeting;
  final String bookingNumber;
  final double paymentAmount;
  final String userName;

  const BookingCompleteScreen({
    super.key,
    required this.meeting,
    required this.bookingNumber,
    required this.paymentAmount,
    required this.userName,
  });

  @override
  State<BookingCompleteScreen> createState() => _BookingCompleteScreenState();
}

class _BookingCompleteScreenState extends State<BookingCompleteScreen> {
  bool _bookingCreated = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _createBookingRecord();
  }

  // 실제 Firestore에 예약 기록 생성
  Future<void> _createBookingRecord() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;

      if (user != null) {
        // FirestoreService의 승인 대기 상태 예약 생성 메서드 사용
        final firestoreService = FirestoreService();

        // Firestore에 승인 대기 상태로 예약 생성
        await firestoreService.createBookingWithPendingStatus(
          widget.meeting.id,
          user.uid,
          widget.userName,
          widget.paymentAmount,
          bookingNumber: widget.bookingNumber,
        );

        if (mounted) {
          setState(() {
            _bookingCreated = true;
          });
        }

        print('✅ 예약 기록이 Firestore에 저장되었습니다 (승인 대기): ${widget.bookingNumber}');
      }
    } catch (e) {
      print('❌ 예약 기록 저장 실패: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 뒤로가기를 누르면 홈으로 이동
        Navigator.of(context).popUntil((route) => route.isFirst);
        return false; // 기본 뒤로가기 동작 막기
      },
      child: Scaffold(
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
                                      ((widget
                                                  .meeting
                                                  .coverImageUrl
                                                  ?.isNotEmpty ??
                                              false) ||
                                          (widget
                                                  .meeting
                                                  .imageUrl
                                                  ?.isNotEmpty ??
                                              false))
                                      ? DecorationImage(
                                          image: NetworkImage(
                                            (widget
                                                        .meeting
                                                        .coverImageUrl
                                                        ?.isNotEmpty ==
                                                    true)
                                                ? widget.meeting.coverImageUrl!
                                                : widget.meeting.imageUrl!,
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
                                      widget.meeting.title,
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
                                            '${widget.meeting.location} • ${_formatDate(widget.meeting.scheduledDate)}',
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
                                          '${widget.meeting.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
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
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
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
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingHistoryScreen(
                              meeting: widget.meeting,
                              bookingNumber: widget.bookingNumber,
                            ),
                          ),
                          (route) =>
                              route.isFirst, // 홈 페이지(첫 번째 페이지)까지만 남기고 모든 페이지 제거
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
      ), // WillPopScope 닫기
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.month}.${date.day}($weekday) ${date.hour}시 ${date.minute.toString().padLeft(2, '0')}분';
  }
}
