import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'booking_cancellation/booking_cancel_step1_screen.dart';

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
            child:
                ((meeting?.coverImageUrl?.isNotEmpty ?? false) ||
                    (meeting?.imageUrl?.isNotEmpty ?? false))
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      (meeting!.coverImageUrl?.isNotEmpty == true)
                          ? meeting.coverImageUrl!
                          : meeting.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage();
                      },
                    ),
                  )
                : _buildPlaceholderImage(),
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
                _showInquiryDialog();
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

  void _showCancelDialog(BuildContext context, Booking booking) {
    // 예약 취소 첫 번째 단계 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingCancelStep1Screen(booking: booking),
      ),
    );
  }

  void _showInquiryDialog() {
    // TODO: 문의하기 다이얼로그 구현
    print('문의하기');
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('M.d(E) HH시 mm분', 'ko_KR').format(dateTime);
  }
}
