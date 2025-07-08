import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meeting.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../services/booking_cancellation_service.dart';
import '../services/iamport_refund_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../config/booking_policy_config.dart';
import 'refund_policy_screen.dart';
import '../widgets/common_modal.dart';

class BookingHistoryScreen extends StatefulWidget {
  final Meeting meeting;
  final String bookingNumber;

  const BookingHistoryScreen({
    super.key,
    required this.meeting,
    required this.bookingNumber,
  });

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  Booking? _currentBooking;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBookingInfo();
  }

  Future<void> _loadBookingInfo() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      if (user == null) return;

      final bookingService = BookingService();
      final bookings = await bookingService.getUserBookings(user.uid).first;

      // bookingNumber로 해당 예약 찾기
      _currentBooking = bookings.firstWhere(
        (booking) => booking.bookingNumber == widget.bookingNumber,
        orElse: () => Booking(
          id: '',
          userId: user.uid,
          meetingId: widget.meeting.id,
          bookingDate: DateTime.now(),
          createdAt: DateTime.now(),
          status: BookingStatus.confirmed,
          bookingNumber: widget.bookingNumber,
          amount: widget.meeting.price,
          userName: '사용자',
          meeting: widget.meeting,
        ),
      );

      if (mounted) setState(() {});
    } catch (e) {
      print('예약 정보 로드 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        title: const Text(
          '예약내역',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 예약 정보
            _buildBookingInfo(),

            const SizedBox(height: 24),

            // 환불 규정
            _buildRefundPolicy(context),

            const SizedBox(height: 24),

            // 예약 모임
            _buildBookedMeeting(context),

            const SizedBox(height: 24),

            // 주문자 정보
            _buildOrdererInfo(),

            const SizedBox(height: 24),

            // 결제 정보
            _buildPaymentInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '예약번호',
              style: TextStyle(
                color: Color(0xFFEAEAEA),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              widget.bookingNumber,
              style: const TextStyle(
                color: Color(0xFFEAEAEA),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            const Text(
              '결제날짜 : ',
              style: TextStyle(
                color: Color(0xFFC2C2C2),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _formatPaymentDate(DateTime.now()),
              style: const TextStyle(
                color: Color(0xFFC2C2C2),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRefundPolicy(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RefundPolicyScreen(
              meeting: widget.meeting,
              bookingNumber: widget.bookingNumber,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFFEAEAEA), size: 20),
            SizedBox(width: 4),
            Text(
              '환불 규정 안내',
              style: TextStyle(
                color: Color(0xFFEAEAEA),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Spacer(),
            Icon(Icons.chevron_right, color: Color(0xFF8C8C8C), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBookedMeeting(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '예약 모임 1개',
              style: TextStyle(
                color: Color(0xFFEAEAEA),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFCC9C5),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                _currentBooking?.statusText ?? '승인 대기중',
                style: const TextStyle(
                  color: Color(0xFFF44336),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          '*모집 인원이 미달일 경우 자동 취소 및 전액 환불됩니다.',
          style: TextStyle(
            color: Color(0xFF8C8C8C),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        // 모임 카드
        GestureDetector(
          onTap: () {
            Navigator.pop(context); // 모임 상세페이지로 돌아가기
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF2E2E2E)),
            ),
            child: Row(
              children: [
                // 모임 이미지
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF2E2E2E)),
                    image:
                        ((widget.meeting.coverImageUrl?.isNotEmpty ?? false) ||
                            (widget.meeting.imageUrl?.isNotEmpty ?? false))
                        ? DecorationImage(
                            image: NetworkImage(
                              (widget.meeting.coverImageUrl?.isNotEmpty == true)
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
        ),

        const SizedBox(height: 12),

        // 버튼들
        Row(
          children: [
            Expanded(child: _buildCancelButton()),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _showContactDialog(context);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF8C8C8C)),
                  backgroundColor: Colors.transparent,
                  foregroundColor: const Color(0xFFF5F5F5),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                child: const Text(
                  '문의하기',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 취소 버튼 위젯 (3시간 전 제한 고려)
  Widget _buildCancelButton() {
    if (_currentBooking?.status == BookingStatus.cancelled) {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFC2C2C2)),
          backgroundColor: Colors.transparent,
          minimumSize: const Size(0, 36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        ),
        child: const Text(
          '취소됨',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFFC2C2C2),
          ),
        ),
      );
    }

    // 정책 설정을 사용한 취소 가능 여부 체크
    bool canCancel = BookingPolicyConfig.canCancelBooking(
      widget.meeting.scheduledDate,
    );

    return OutlinedButton(
      onPressed: canCancel && !_isLoading ? () => _showCancelBooking() : null,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: canCancel ? const Color(0xFF8C8C8C) : const Color(0xFFC2C2C2),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: canCancel
            ? const Color(0xFFF5F5F5)
            : const Color(0xFFC2C2C2),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF8C8C8C),
              ),
            )
          : Text(
              canCancel ? '취소하기' : '취소불가',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
    );
  }

  Future<void> _showCancelBooking() async {
    if (_currentBooking == null) return;

    // 취소 가능 여부 먼저 확인
    final cancellationService = BookingCancellationService();
    final policy = await cancellationService.checkCancellationPolicy(
      _currentBooking!.id,
    );

    if (!policy['canCancel']) {
      // 취소 불가능한 경우
      _showCancellationNotPossibleDialog(policy['reason'] ?? '취소할 수 없습니다.');
      return;
    }

    // 취소 가능한 경우 확인 다이얼로그 표시
    await _showCancellationConfirmDialog();
  }

  void _showCancellationNotPossibleDialog(String reason) {
    ModalUtils.showInfoModal(
      context: context,
      title: '예약 취소 불가',
      description: reason,
      buttonText: '확인',
    );
  }

  Future<void> _showCancellationConfirmDialog() async {
    final meetingInfo =
        '\n\n모임: ${widget.meeting.title}\n예약번호: ${widget.bookingNumber}\n\n• 결제된 금액은 자동으로 환불 처리됩니다.\n• 취소된 예약은 되돌릴 수 없습니다.\n• 호스트에게 취소 알림이 전송됩니다.';

    final confirmed = await ModalUtils.showConfirmModal(
      context: context,
      title: '예약 취소',
      description: '정말로 예약을 취소하시겠습니까?$meetingInfo',
      confirmText: '취소하기',
      cancelText: '아니오',
      isDestructive: true,
    );

    if (confirmed == true) {
      _processCancellation();
    }
  }

  Future<void> _processCancellation() async {
    if (_currentBooking == null) return;

    setState(() {
      _isLoading = true;
    });

    // 로딩 모달 표시
    ModalUtils.showLoadingModal(context: context, message: '예약을 취소하는 중입니다...');

    try {
      final cancellationService = BookingCancellationService();
      final iamportRefundService = IamportRefundService();
      final notificationService = NotificationService();
      final authService = Provider.of<AuthService>(context, listen: false);

      final user = authService.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 1. 예약 취소 처리
      await cancellationService.cancelBooking(
        bookingId: _currentBooking!.id,
        userId: user.uid,
        meetingId: _currentBooking!.meetingId,
        reason: '사용자 요청에 의한 취소',
        customReason: null,
      );

      // 2. 결제 정보가 있다면 환불 처리
      bool refundProcessed = false;
      if (_currentBooking!.amount > 0) {
        try {
          final refundResult = await iamportRefundService.processRefund(
            merchantUid: _currentBooking!.bookingNumber,
            reason: '사용자 요청에 의한 예약 취소',
          );

          if (refundResult['success']) {
            refundProcessed = true;
            print('✅ 환불 완료: ${refundResult['refundAmount']}원');
          } else {
            print('❌ 환불 실패: ${refundResult['message']}');
          }
        } catch (e) {
          print('❌ 환불 처리 중 오류: $e');
        }
      }

      // 3. 호스트에게 알림 전송
      try {
        await notificationService.notifyHostOfCancellation(
          hostId: widget.meeting.hostId,
          meetingId: _currentBooking!.meetingId,
          meetingTitle: widget.meeting.title,
          userName: _currentBooking!.userName,
          bookingNumber: _currentBooking!.bookingNumber,
        );
      } catch (e) {
        print('❌ 호스트 알림 전송 실패: $e');
      }

      // 4. 사용자에게 취소 완료 알림 전송
      try {
        await notificationService.notifyUserOfCancellationComplete(
          userId: user.uid,
          meetingTitle: widget.meeting.title,
          bookingNumber: widget.bookingNumber,
          refundProcessed: refundProcessed,
        );
      } catch (e) {
        print('❌ 사용자 알림 전송 실패: $e');
      }

      // 예약 상태 업데이트
      setState(() {
        _currentBooking = _currentBooking!.copyWith(
          status: BookingStatus.cancelled,
        );
      });

      // 로딩 다이얼로그 닫기
      if (mounted) Navigator.of(context).pop();

      // 성공 메시지 표시
      if (mounted) {
        final message = refundProcessed
            ? '예약이 취소되었습니다.\n환불이 완료되었습니다.'
            : '예약이 취소되었습니다.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // 로딩 다이얼로그 닫기
      if (mounted) Navigator.of(context).pop();

      // 에러 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('예약 취소에 실패했습니다: $e'),
            backgroundColor: const Color(0xFFF44336),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildOrdererInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '주문자 정보',
          style: TextStyle(
            color: Color(0xFFEAEAEA),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoRow('이름', _currentBooking?.userName ?? '홍길동'),
        const SizedBox(height: 4),
        _buildInfoRow('연락처', '01012345678'),
        const SizedBox(height: 4),
        _buildInfoRow('이메일', 'name@mail.com'),
      ],
    );
  }

  Widget _buildPaymentInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '결제 정보',
          style: TextStyle(
            color: Color(0xFFEAEAEA),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoRow('결제방법', '신용카드'),
        const SizedBox(height: 4),
        _buildInfoRow(
          '총 결제 금액',
          '${widget.meeting.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFC2C2C2),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFEAEAEA),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showContactDialog(BuildContext context) {
    ModalUtils.showInfoModal(
      context: context,
      title: '문의하기',
      description: '고객센터로 연결됩니다.\n전화: 1588-0000',
      buttonText: '확인',
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.month}.${date.day}($weekday) ${date.hour}시 ${date.minute.toString().padLeft(2, '0')}분';
  }

  String _formatPaymentDate(DateTime date) {
    final amPm = date.hour >= 12 ? '오후' : '오전';
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} $amPm ${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
