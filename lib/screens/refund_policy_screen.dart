import 'package:flutter/material.dart';
import '../models/meeting.dart';

class RefundPolicyScreen extends StatelessWidget {
  final Meeting meeting;
  final String? bookingNumber;

  const RefundPolicyScreen({
    super.key,
    required this.meeting,
    this.bookingNumber,
  });

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

            // 환불 규정 (확장된 상태)
            _buildExpandedRefundPolicy(),

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
              bookingNumber ?? '임시 예약번호',
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

  Widget _buildExpandedRefundPolicy() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
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
              Icon(Icons.keyboard_arrow_up, color: Color(0xFF8C8C8C), size: 24),
            ],
          ),

          const SizedBox(height: 20),

          // 환불 규정 내용
          Container(
            padding: const EdgeInsets.all(16),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 전액 환불
                Text(
                  '전액 환불',
                  style: TextStyle(
                    color: Color(0xFFF5F5F5),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '''결제 후 30분 경과 전
참가 신청 후 승인이 완료되지 않은 경우
승인 후 호스트에 의해 내보내진 경우
참여 확정 모임의 진행일 기준 4일 전까지
소셜링 승인이 거절되었을 경우
호스트가 내보내기를 진행했을 경우
호스트가 소셜링을 폐강하거나 인원 미달로 자동 폐강될 경우
소셜링 진행 3시간 전까지 소셜링 채팅방에 진행 여부 (모임 장소 및 시간)에 대한 공지가 없는 경우
소셜링 운영 정보 (인원, 장소, 날짜 및 시간 등)에 큰 변동사항이 생긴 경우''',
                  style: TextStyle(
                    color: Color(0xFFD6D6D6),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '환불은 PG사 승인 취소 기간에 따라 주말, 공휴일을 제외한 영업일 기준 최대 3~5일 소요될 수 있습니다.',
                  style: TextStyle(
                    color: Color(0xFF8C8C8C),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),

                SizedBox(height: 24),

                // 환불 불가
                Text(
                  '환불 불가',
                  style: TextStyle(
                    color: Color(0xFFF5F5F5),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '''참여 확정 모임의 진행일 기준 3일 전부터 (ex. 1월 7일 토요일에 진행되는 모임의 경우 1월 4일 수요일부터 환불 불가)
모임 진행 당일에 신청한 경우''',
                  style: TextStyle(
                    color: Color(0xFFD6D6D6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
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
              child: const Text(
                '승인 대기중',
                style: TextStyle(
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
            Navigator.pop(context); // 이전 페이지로
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
        ),

        const SizedBox(height: 12),

        // 버튼들
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _showCancelDialog(context);
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
                  '취소하기',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
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
        _buildInfoRow('이름', '홍길동'),
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
          '${meeting.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
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

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        title: const Text('예약 취소', style: TextStyle(color: Colors.white)),
        content: const Text(
          '정말로 예약을 취소하시겠습니까?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('예약이 취소되었습니다.')));
            },
            child: const Text('예'),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        title: const Text('문의하기', style: TextStyle(color: Colors.white)),
        content: const Text(
          '고객센터로 연결됩니다.\n전화: 1588-0000',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
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

  String _formatPaymentDate(DateTime date) {
    final amPm = date.hour >= 12 ? '오후' : '오전';
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} $amPm ${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
