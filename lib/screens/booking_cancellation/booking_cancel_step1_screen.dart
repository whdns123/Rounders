/*
⚠️ 이 파일은 더 이상 사용되지 않습니다.
홈 화면의 통합 취소 기능으로 대체되었습니다.
(lib/screens/home_screen.dart의 _showCancelBooking 메서드 참조)
*/

import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../models/meeting.dart';
import '../../services/auth_service.dart';
import '../../services/booking_cancellation_service.dart';
import 'booking_cancel_step2_screen.dart';
import 'package:provider/provider.dart';

class BookingCancelStep1Screen extends StatefulWidget {
  final Booking booking;

  const BookingCancelStep1Screen({Key? key, required this.booking})
    : super(key: key);

  @override
  State<BookingCancelStep1Screen> createState() =>
      _BookingCancelStep1ScreenState();
}

class _BookingCancelStep1ScreenState extends State<BookingCancelStep1Screen> {
  final BookingCancellationService _cancellationService =
      BookingCancellationService();
  bool _isLoading = false;
  Map<String, dynamic>? _cancellationPolicy;

  @override
  void initState() {
    super.initState();
    _checkCancellationPolicy();
  }

  Future<void> _checkCancellationPolicy() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final policy = await _cancellationService.checkCancellationPolicy(
        widget.booking.id,
      );
      setState(() {
        _cancellationPolicy = policy;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('취소 정책 확인 중 오류가 발생했습니다: $e'),
            backgroundColor: const Color(0xFFF44336),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}.${dateTime.day}(${_getWeekday(dateTime)}) ${dateTime.hour}시 ${dateTime.minute.toString().padLeft(2, '0')}분';
  }

  String _getWeekday(DateTime dateTime) {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    return weekdays[dateTime.weekday % 7];
  }

  String _formatPrice(double price) {
    return '${price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';
  }

  @override
  Widget build(BuildContext context) {
    final meeting = widget.booking.meeting;
    final user = Provider.of<AuthService>(context, listen: false).currentUser;

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
          '예약취소',
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
          : _cancellationPolicy != null && !_cancellationPolicy!['canCancel']
          ? _buildCannotCancelView()
          : _buildCancelView(),
    );
  }

  Widget _buildCannotCancelView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '취소 불가',
            style: TextStyle(
              color: Color(0xFFEAEAEA),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Pretendard',
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E2E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _cancellationPolicy!['reason'] ?? '취소할 수 없습니다.',
              style: const TextStyle(
                color: Color(0xFFD6D6D6),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF44336),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                '확인',
                style: TextStyle(
                  color: Color(0xFFF5F5F5),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelView() {
    final meeting = widget.booking.meeting;
    final user = Provider.of<AuthService>(context, listen: false).currentUser;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 예약 모임 섹션
                _buildBookingSection(),
                const SizedBox(height: 24),

                // 주문자 정보 섹션
                _buildUserInfoSection(user),
                const SizedBox(height: 24),

                // 결제 정보 섹션
                _buildPaymentInfoSection(),
              ],
            ),
          ),
        ),

        // 하단 버튼
        Container(
          color: const Color(0xFF111111),
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _proceedToNextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF44336),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                '다음',
                style: TextStyle(
                  color: Color(0xFFF5F5F5),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingSection() {
    final meeting = widget.booking.meeting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더
        Row(
          children: [
            const Text(
              '예약 모임 1개',
              style: TextStyle(
                color: Color(0xFFEAEAEA),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Pretendard',
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: widget.booking.status == BookingStatus.confirmed
                    ? const Color(0xFFFCC9C5)
                    : const Color(0xFFFCC9C5),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                widget.booking.statusText,
                style: TextStyle(
                  color: widget.booking.status == BookingStatus.confirmed
                      ? const Color(0xFFF44336)
                      : const Color(0xFFF44336),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 모임 카드
        if (meeting != null) _buildMeetingCard(meeting),
      ],
    );
  }

  Widget _buildMeetingCard(Meeting meeting) {
    return SizedBox(
      height: 76,
      child: Row(
        children: [
          // 모임 이미지
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E2E),
              borderRadius: BorderRadius.circular(4),
              image:
                  ((meeting.coverImageUrl?.isNotEmpty ?? false) ||
                      (meeting.imageUrl?.isNotEmpty ?? false))
                  ? DecorationImage(
                      image: NetworkImage(
                        (meeting.coverImageUrl?.isNotEmpty == true)
                            ? meeting.coverImageUrl!
                            : meeting.imageUrl!,
                      ),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child:
                !((meeting.coverImageUrl?.isNotEmpty ?? false) ||
                    (meeting.imageUrl?.isNotEmpty ?? false))
                ? const Icon(Icons.image, color: Color(0xFF8C8C8C), size: 32)
                : null,
          ),
          const SizedBox(width: 12),

          // 모임 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 모임 제목
                Text(
                  meeting.title,
                  style: const TextStyle(
                    color: Color(0xFFEAEAEA),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Pretendard',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // 위치 및 시간
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFFD6D6D6),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${meeting.location} • ${_formatDateTime(meeting.scheduledDate)}',
                        style: const TextStyle(
                          color: Color(0xFFD6D6D6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Pretendard',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // 가격
                Row(
                  children: [
                    const Icon(
                      Icons.attach_money,
                      color: Color(0xFFD6D6D6),
                      size: 16,
                    ),
                    Text(
                      _formatPrice(meeting.price.toDouble()),
                      style: const TextStyle(
                        color: Color(0xFFD6D6D6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection(user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '주문자 정보',
          style: TextStyle(
            color: Color(0xFFEAEAEA),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(height: 8),

        // 이름
        _buildInfoRow('이름', user?.displayName ?? '홍길동'),
        const SizedBox(height: 4),

        // 연락처
        _buildInfoRow('연락처', user?.phoneNumber ?? '01012345678'),
        const SizedBox(height: 4),

        // 이메일
        _buildInfoRow('이메일', user?.email ?? 'name@mail.com'),
      ],
    );
  }

  Widget _buildPaymentInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '결제 정보',
          style: TextStyle(
            color: Color(0xFFEAEAEA),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(height: 8),

        // 결제방법
        _buildInfoRow('결제방법', '신용카드'),
        const SizedBox(height: 4),

        // 총 결제 금액
        _buildInfoRow('총 결제 금액', _formatPrice(widget.booking.amount)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFC2C2C2),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFEAEAEA),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'Pretendard',
          ),
        ),
      ],
    );
  }

  void _proceedToNextStep() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingCancelStep2Screen(booking: widget.booking),
      ),
    );
  }
}
