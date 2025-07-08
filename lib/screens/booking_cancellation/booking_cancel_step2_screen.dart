/*
⚠️ 이 파일은 더 이상 사용되지 않습니다.
홈 화면의 통합 취소 기능으로 대체되었습니다.
(lib/screens/home_screen.dart의 _showCancelBooking 메서드 참조)
*/

import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../models/booking_cancellation.dart';
import 'booking_cancel_step3_screen.dart';

class BookingCancelStep2Screen extends StatefulWidget {
  final Booking booking;

  const BookingCancelStep2Screen({Key? key, required this.booking})
    : super(key: key);

  @override
  State<BookingCancelStep2Screen> createState() =>
      _BookingCancelStep2ScreenState();
}

class _BookingCancelStep2ScreenState extends State<BookingCancelStep2Screen> {
  String? _selectedReason;
  final TextEditingController _customReasonController = TextEditingController();
  bool _isCustomReasonSelected = false;

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 취소 안내
                  _buildCancellationNotice(),
                  const SizedBox(height: 24),

                  // 취소 사유 선택
                  _buildReasonSelection(),
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
                onPressed: _canProceed() ? _proceedToNextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canProceed()
                      ? const Color(0xFFF44336)
                      : const Color(0xFFC2C2C2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Text(
                  '다음',
                  style: TextStyle(
                    color: _canProceed()
                        ? const Color(0xFFF5F5F5)
                        : const Color(0xFF8C8C8C),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationNotice() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목
        Text(
          '취소 안내',
          style: TextStyle(
            color: Color(0xFFEAEAEA),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
        SizedBox(height: 16),

        // 안내 내용
        Text(
          '지금 취소하실 경우, 아래와 같은 사항이 적용됩니다:',
          style: TextStyle(
            color: Color(0xFFD6D6D6),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
            height: 1.5,
          ),
        ),
        SizedBox(height: 8),

        Text(
          '예시 텍스트: 모임 시작 1시간 전 이후 취소 시, 일정 기간 재예약이 제한될 수 있습니다.',
          style: TextStyle(
            color: Color(0xFFD6D6D6),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
            height: 1.5,
          ),
        ),
        SizedBox(height: 8),

        Text(
          '입력하신 취소 사유는 호스트에게 전달됩니다.',
          style: TextStyle(
            color: Color(0xFFD6D6D6),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildReasonSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목
        const Text(
          '취소 사유 선택',
          style: TextStyle(
            color: Color(0xFFEAEAEA),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(height: 16),

        // 사유 옵션들
        Column(
          children: [
            ...BookingCancellation.cancellationReasons.map((reason) {
              final isSelected = _selectedReason == reason;
              final isCustomOption = reason == '기타(직접입력)';

              return Column(
                children: [
                  _buildReasonOption(reason, isSelected, isCustomOption),
                  const SizedBox(height: 8),

                  // 기타 선택 시 텍스트 필드 표시
                  if (isCustomOption && isSelected) _buildCustomReasonField(),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildReasonOption(
    String reason,
    bool isSelected,
    bool isCustomOption,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedReason = reason;
          _isCustomReasonSelected = isCustomOption;
          if (!isCustomOption) {
            _customReasonController.clear();
          }
        });
      },
      child: SizedBox(
        height: 24,
        child: Row(
          children: [
            // 라디오 버튼
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFF44336)
                      : const Color(0xFF8C8C8C),
                  width: 2,
                ),
                color: isSelected
                    ? const Color(0xFFF44336)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.circle,
                        color: Color(0xFFF5F5F5),
                        size: 8,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),

            // 사유 텍스트
            Text(
              reason,
              style: const TextStyle(
                color: Color(0xFFEAEAEA),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomReasonField() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: _customReasonController,
        style: const TextStyle(
          color: Color(0xFFEAEAEA),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Pretendard',
        ),
        decoration: InputDecoration(
          hintText: '취소 사유를 직접 입력해주세요',
          hintStyle: const TextStyle(
            color: Color(0xFFA0A0A0),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
          filled: true,
          fillColor: const Color(0xFF3C3C3C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        maxLines: 3,
        onChanged: (value) {
          setState(() {}); // 버튼 상태 업데이트
        },
      ),
    );
  }

  bool _canProceed() {
    if (_selectedReason == null) return false;

    if (_isCustomReasonSelected) {
      return _customReasonController.text.trim().isNotEmpty;
    }

    return true;
  }

  void _proceedToNextStep() {
    final customReason = _isCustomReasonSelected
        ? _customReasonController.text.trim()
        : null;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingCancelStep3Screen(
          booking: widget.booking,
          selectedReason: _selectedReason!,
          customReason: customReason,
        ),
      ),
    );
  }
}
