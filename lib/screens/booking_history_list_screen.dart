import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
import '../services/booking_cancellation_service.dart';
import '../services/iamport_refund_service.dart';
import '../services/notification_service.dart';
import '../widgets/common_modal.dart';

class BookingHistoryListScreen extends StatelessWidget {
  const BookingHistoryListScreen({super.key});

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
          '예약 내역',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, _) {
          final user = authService.currentUser;
          if (user == null) {
            return const Center(
              child: Text('로그인이 필요합니다.', style: TextStyle(color: Colors.white)),
            );
          }

          return StreamBuilder<List<Booking>>(
            stream: BookingService().getUserBookings(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFF44336)),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    '오류가 발생했습니다: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }

              final bookings = snapshot.data ?? [];

              if (bookings.isEmpty) {
                return _buildEmptyState();
              }

              return _buildBookingList(context, bookings);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Color(0xFF8C8C8C)),
          SizedBox(height: 16),
          Text(
            '예약 내역이 없습니다.',
            style: TextStyle(
              color: Color(0xFF8C8C8C),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingList(BuildContext context, List<Booking> bookings) {
    // 날짜별로 그룹화
    Map<String, List<Booking>> groupedBookings = {};
    for (var booking in bookings) {
      String dateKey = DateFormat('yyyy.MM.dd').format(booking.createdAt);
      if (groupedBookings[dateKey] == null) {
        groupedBookings[dateKey] = [];
      }
      groupedBookings[dateKey]!.add(booking);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: groupedBookings.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...entry.value.asMap().entries.map((bookingEntry) {
                int index = bookingEntry.key;
                Booking booking = bookingEntry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (index == 0) _buildDateHeader(entry.key),
                    _buildBookingCard(booking),
                    if (booking.status != BookingStatus.cancelled)
                      _buildActionButtons(context, booking),
                    if (index < entry.value.length - 1 ||
                        groupedBookings.entries.last.key != entry.key)
                      _buildDivider(),
                    const SizedBox(height: 32),
                  ],
                );
              }).toList(),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        date,
        style: const TextStyle(
          color: Color(0xFFEAEAEA),
          fontSize: 14,
          fontWeight: FontWeight.w700,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final meeting = booking.meeting;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // 모임 이미지
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E2E),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF2E2E2E)),
            ),
            child: Stack(
              children: [
                // 이미지 표시
                if ((meeting?.coverImageUrl?.isNotEmpty ?? false) ||
                    (meeting?.imageUrl?.isNotEmpty ?? false))
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      (meeting!.coverImageUrl?.isNotEmpty == true)
                          ? meeting.coverImageUrl!
                          : meeting.imageUrl!,
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('🖼️ 이미지 로딩 실패: $error');
                        return _buildPlaceholderImage();
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E2E2E),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFF44336),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  _buildPlaceholderImage(),
                // 취소된 경우 반투명 오버레이
                if (booking.status == BookingStatus.cancelled)
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 컨텐츠
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상태 태그
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: booking.statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    booking.statusText,
                    style: TextStyle(
                      color: booking.statusTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 모임 제목
                Text(
                  meeting?.title ?? '모임 정보를 불러올 수 없습니다',
                  style: TextStyle(
                    color: booking.status == BookingStatus.cancelled
                        ? const Color(0xFF6E6E6E)
                        : const Color(0xFFEAEAEA),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Pretendard',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // 위치와 시간
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: booking.status == BookingStatus.cancelled
                          ? const Color(0xFF6E6E6E)
                          : const Color(0xFFD6D6D6),
                    ),
                    Expanded(
                      child: Text(
                        '${meeting?.location ?? '위치 정보 없음'} • ${_formatDateTime(booking.bookingDate)}',
                        style: TextStyle(
                          color: booking.status == BookingStatus.cancelled
                              ? const Color(0xFF6E6E6E)
                              : const Color(0xFFD6D6D6),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.image, color: Color(0xFF8C8C8C), size: 32),
    );
  }

  Widget _buildActionButtons(BuildContext context, Booking booking) {
    return Row(
      children: [
        // 취소하기 버튼
        Expanded(
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF8C8C8C)),
              borderRadius: BorderRadius.circular(3),
            ),
            child: ElevatedButton(
              onPressed: () {
                _showCancelDialog(context, booking);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              child: const Text(
                '취소하기',
                style: TextStyle(
                  color: Color(0xFFF5F5F5),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 문의하기 버튼
        Expanded(
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF8C8C8C)),
              borderRadius: BorderRadius.circular(3),
            ),
            child: ElevatedButton(
              onPressed: () {
                _showInquiryDialog(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              child: const Text(
                '문의하기',
                style: TextStyle(
                  color: Color(0xFFF5F5F5),
                  fontSize: 12,
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

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: const Color(0xFF2E2E2E),
      margin: const EdgeInsets.only(top: 32),
    );
  }

  Future<void> _showCancelDialog(BuildContext context, Booking booking) async {
    // 취소 가능 여부 먼저 확인
    final cancellationService = BookingCancellationService();
    final policy = await cancellationService.checkCancellationPolicy(
      booking.id,
    );

    if (!policy['canCancel']) {
      // 취소 불가능한 경우
      _showCancellationNotPossibleDialog(
        context,
        policy['reason'] ?? '취소할 수 없습니다.',
      );
      return;
    }

    // 취소 가능한 경우 확인 다이얼로그 표시
    await _showCancellationConfirmDialog(context, booking);
  }

  void _showCancellationNotPossibleDialog(BuildContext context, String reason) {
    ModalUtils.showInfoModal(
      context: context,
      title: '예약 취소 불가',
      description: reason,
      buttonText: '확인',
    );
  }

  Future<void> _showCancellationConfirmDialog(
    BuildContext context,
    Booking booking,
  ) async {
    final meetingInfo = booking.meeting != null
        ? '\n\n모임: ${booking.meeting!.title}\n예약번호: ${booking.bookingNumber}\n\n• 결제된 금액은 자동으로 환불 처리됩니다.\n• 취소된 예약은 되돌릴 수 없습니다.\n• 호스트에게 취소 알림이 전송됩니다.'
        : '\n\n• 결제된 금액은 자동으로 환불 처리됩니다.\n• 취소된 예약은 되돌릴 수 없습니다.\n• 호스트에게 취소 알림이 전송됩니다.';

    final confirmed = await ModalUtils.showConfirmModal(
      context: context,
      title: '예약 취소',
      description: '정말로 예약을 취소하시겠습니까?$meetingInfo',
      confirmText: '취소하기',
      cancelText: '돌아가기',
      isDestructive: true,
    );

    if (confirmed == true) {
      _processCancellation(context, booking);
    }
  }

  Future<void> _processCancellation(
    BuildContext context,
    Booking booking,
  ) async {
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
        bookingId: booking.id,
        userId: user.uid,
        meetingId: booking.meetingId,
        reason: '사용자 요청에 의한 취소',
        customReason: null,
      );

      // 2. 결제 정보가 있다면 환불 처리
      bool refundProcessed = false;
      if (booking.amount > 0) {
        try {
          final refundResult = await iamportRefundService.processRefund(
            merchantUid: booking.bookingNumber,
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
      if (booking.meeting != null) {
        try {
          await notificationService.notifyHostOfCancellation(
            hostId: booking.meeting!.hostId,
            meetingId: booking.meetingId,
            meetingTitle: booking.meeting!.title,
            userName: booking.userName,
            bookingNumber: booking.bookingNumber,
          );
        } catch (e) {
          print('❌ 호스트 알림 전송 실패: $e');
        }
      }

      // 4. 사용자에게 취소 완료 알림 전송
      try {
        await notificationService.notifyUserOfCancellationComplete(
          userId: user.uid,
          meetingTitle: booking.meeting?.title ?? '모임',
          bookingNumber: booking.bookingNumber,
          refundProcessed: refundProcessed,
        );
      } catch (e) {
        print('❌ 사용자 알림 전송 실패: $e');
      }

      // 로딩 다이얼로그 닫기
      if (context.mounted) Navigator.of(context).pop();

      // 성공 메시지 표시
      if (context.mounted) {
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
      if (context.mounted) Navigator.of(context).pop();

      // 에러 메시지 표시
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('예약 취소에 실패했습니다: $e'),
            backgroundColor: const Color(0xFFF44336),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showInquiryDialog(BuildContext context) {
    ModalUtils.showInfoModal(
      context: context,
      title: '문의하기',
      description: '고객센터로 연결됩니다.\n전화: 1588-0000',
      buttonText: '확인',
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('M.d(E) HH시 mm분', 'ko_KR').format(dateTime);
  }
}
