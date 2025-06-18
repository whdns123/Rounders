import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/booking.dart';
import '../models/meeting.dart';
import '../models/refund_request.dart';
import '../services/refund_service.dart';
import '../services/auth_service.dart';

class RefundRequestScreen extends StatefulWidget {
  final Booking booking;
  final Meeting meeting;

  const RefundRequestScreen({
    super.key,
    required this.booking,
    required this.meeting,
  });

  @override
  State<RefundRequestScreen> createState() => _RefundRequestScreenState();
}

class _RefundRequestScreenState extends State<RefundRequestScreen> {
  final RefundService _refundService = RefundService();
  RefundReason _selectedReason = RefundReason.beforeDeadline;
  final TextEditingController _detailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        title: const Text(
          '환불 요청',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
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

            // 환불 사유 선택
            _buildRefundReasonSection(),

            const SizedBox(height: 24),

            // 상세 사유 입력
            _buildDetailReasonSection(),

            const SizedBox(height: 24),

            // 환불 정책 안내
            _buildRefundPolicyInfo(),

            const SizedBox(height: 32),

            // 환불 요청 버튼
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '환불 예약 정보',
            style: TextStyle(
              color: Color(0xFFEAEAEA),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pretendard',
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('모임명', widget.meeting.title),
          const SizedBox(height: 8),
          _buildInfoRow('예약번호', widget.booking.bookingNumber),
          const SizedBox(height: 8),
          _buildInfoRow('결제금액', '${widget.booking.amount.toInt()}원'),
          const SizedBox(height: 8),
          _buildInfoRow('모임일시', _formatDateTime(widget.meeting.scheduledDate)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFA0A0A0),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFFEAEAEA),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRefundReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '환불 사유 선택',
          style: TextStyle(
            color: Color(0xFFEAEAEA),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(height: 16),
        ...RefundReason.values.map((reason) => _buildReasonRadioTile(reason)),
      ],
    );
  }

  Widget _buildReasonRadioTile(RefundReason reason) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _selectedReason == reason
              ? const Color(0xFFFF6B35)
              : const Color(0xFF2A2A2A),
          width: 1,
        ),
      ),
      child: RadioListTile<RefundReason>(
        value: reason,
        groupValue: _selectedReason,
        onChanged: (RefundReason? value) {
          setState(() {
            _selectedReason = value!;
          });
        },
        title: Text(
          _getReasonText(reason),
          style: const TextStyle(
            color: Color(0xFFEAEAEA),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Pretendard',
          ),
        ),
        activeColor: const Color(0xFFFF6B35),
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFFF6B35);
          }
          return const Color(0xFF666666);
        }),
      ),
    );
  }

  Widget _buildDetailReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '상세 사유 (선택사항)',
          style: TextStyle(
            color: Color(0xFFEAEAEA),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: TextField(
            controller: _detailController,
            maxLines: 4,
            style: const TextStyle(
              color: Color(0xFFEAEAEA),
              fontSize: 14,
              fontFamily: 'Pretendard',
            ),
            decoration: const InputDecoration(
              hintText: '환불 사유를 자세히 입력해주세요',
              hintStyle: TextStyle(
                color: Color(0xFF666666),
                fontSize: 14,
                fontFamily: 'Pretendard',
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRefundPolicyInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFFF6B35), size: 20),
              SizedBox(width: 8),
              Text(
                '환불 정책 안내',
                style: TextStyle(
                  color: Color(0xFFEAEAEA),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '• 환불은 PG사 승인 취소 기간에 따라 영업일 기준 최대 3~5일 소요됩니다.\n'
            '• 모임 진행일 기준 3일 전까지만 환불 가능합니다.\n'
            '• 호스트에 의한 모임 취소 시 자동으로 전액 환불됩니다.\n'
            '• 허위 사유로 환불 요청 시 서비스 이용이 제한될 수 있습니다.',
            style: TextStyle(
              color: Color(0xFFA0A0A0),
              fontSize: 12,
              height: 1.5,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitRefundRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B35),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : const Text(
                '환불 요청하기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pretendard',
                ),
              ),
      ),
    );
  }

  String _getReasonText(RefundReason reason) {
    switch (reason) {
      case RefundReason.meetingCancellation:
        return '모임 취소로 인한 환불';
      case RefundReason.hostKickout:
        return '호스트에 의한 내보내기';
      case RefundReason.beforeDeadline:
        return '환불 가능 기간 내 개인 사정';
      case RefundReason.systemError:
        return '시스템 오류';
      case RefundReason.paymentError:
        return '결제 오류';
      case RefundReason.other:
        return '기타';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submitRefundRequest() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 환불 가능 여부 다시 확인
      final canRefund = await _refundService.canRequestRefund(
        widget.booking,
        widget.meeting,
      );
      if (!canRefund) {
        throw Exception('현재 환불 요청이 불가능합니다.');
      }

      // 환불 요청 생성
      await _refundService.createRefundRequest(
        bookingId: widget.booking.id,
        userId: currentUser.uid,
        meetingId: widget.meeting.id,
        amount: widget.booking.amount,
        reason: _selectedReason,
        reasonDetail: _detailController.text.trim().isEmpty
            ? null
            : _detailController.text.trim(),
        bookingNumber: widget.booking.bookingNumber,
        userName: widget.booking.userName,
        meetingTitle: widget.meeting.title,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('환불 요청이 완료되었습니다. 검토 후 처리해드리겠습니다.'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        Navigator.pop(context, true); // 성공 시 true 반환
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('환불 요청 실패: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF5350),
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
}
