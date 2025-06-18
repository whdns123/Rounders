import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../services/auth_service.dart';
import '../../services/booking_cancellation_service.dart';
import '../../screens/home_screen.dart';
import 'package:provider/provider.dart';

class BookingCancelStep3Screen extends StatefulWidget {
  final Booking booking;
  final String selectedReason;
  final String? customReason;

  const BookingCancelStep3Screen({
    Key? key,
    required this.booking,
    required this.selectedReason,
    this.customReason,
  }) : super(key: key);

  @override
  State<BookingCancelStep3Screen> createState() =>
      _BookingCancelStep3ScreenState();
}

class _BookingCancelStep3ScreenState extends State<BookingCancelStep3Screen> {
  final BookingCancellationService _cancellationService =
      BookingCancellationService();
  bool _isLoading = false;
  bool _cancellationCompleted = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _processCancellation();
  }

  Future<void> _processCancellation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      await _cancellationService.cancelBooking(
        bookingId: widget.booking.id,
        userId: user.uid,
        meetingId: widget.booking.meetingId,
        reason: widget.selectedReason,
        customReason: widget.customReason,
      );

      setState(() {
        _cancellationCompleted = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
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
        leading: Container(), // 뒤로가기 버튼 숨김
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
          : _errorMessage != null
          ? _buildErrorView()
          : _buildSuccessView(),
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFF44336), size: 64),
          const SizedBox(height: 16),

          const Text(
            '취소 처리 중 오류가 발생했습니다',
            style: TextStyle(
              color: Color(0xFFF5F5F5),
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: 'Pretendard',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          Text(
            _errorMessage ?? '알 수 없는 오류가 발생했습니다.',
            style: const TextStyle(
              color: Color(0xFFD6D6D6),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'Pretendard',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
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

  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 120),

          // 성공 아이콘
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFF44336),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 24),

          // 완료 메시지
          const Text(
            '취소가 완료되었습니다.',
            style: TextStyle(
              color: Color(0xFFF5F5F5),
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: 'Pretendard',
            ),
          ),
          const SizedBox(height: 16),

          // 설명 텍스트
          const Text(
            '남겨주신 사유는 호스트에게 전달되며,\n취소 내역은 마이페이지 > 예약 내역에서\n확인할 수 있습니다.',
            style: TextStyle(
              color: Color(0xFFD6D6D6),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'Pretendard',
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          // 확인 버튼
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _goToHome,
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
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _goToHome() {
    // 모든 예약 취소 관련 화면을 제거하고 홈으로 이동
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }
}
