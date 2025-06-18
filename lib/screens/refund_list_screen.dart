import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/refund_request.dart';
import '../services/refund_service.dart';
import '../services/auth_service.dart';

class RefundListScreen extends StatelessWidget {
  const RefundListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        title: const Text(
          '환불 내역',
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
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          final currentUser = authService.currentUser;
          if (currentUser == null) {
            return const Center(
              child: Text('로그인이 필요합니다.', style: TextStyle(color: Colors.white)),
            );
          }

          return StreamBuilder<List<RefundRequest>>(
            stream: RefundService().getUserRefundRequests(currentUser.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF6B35),
                    ),
                  ),
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

              final refunds = snapshot.data ?? [];

              if (refunds.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 64,
                        color: Color(0xFF666666),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '환불 내역이 없습니다.',
                        style: TextStyle(
                          color: Color(0xFFA0A0A0),
                          fontSize: 16,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: refunds.length,
                itemBuilder: (context, index) {
                  final refund = refunds[index];
                  return _buildRefundCard(refund);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRefundCard(RefundRequest refund) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상태 배지와 날짜
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: refund.statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: refund.statusColor),
                ),
                child: Text(
                  refund.statusText,
                  style: TextStyle(
                    color: refund.statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
              Text(
                _formatDate(refund.requestedAt),
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 12,
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 모임명
          Text(
            refund.meetingTitle,
            style: const TextStyle(
              color: Color(0xFFEAEAEA),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pretendard',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // 예약번호
          Text(
            '예약번호: ${refund.bookingNumber}',
            style: const TextStyle(
              color: Color(0xFFA0A0A0),
              fontSize: 14,
              fontFamily: 'Pretendard',
            ),
          ),
          const SizedBox(height: 4),

          // 환불 사유
          Text(
            '사유: ${refund.reasonText}',
            style: const TextStyle(
              color: Color(0xFFA0A0A0),
              fontSize: 14,
              fontFamily: 'Pretendard',
            ),
          ),
          const SizedBox(height: 8),

          // 환불 금액
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '환불 금액',
                style: TextStyle(
                  color: Color(0xFFA0A0A0),
                  fontSize: 14,
                  fontFamily: 'Pretendard',
                ),
              ),
              Text(
                '${refund.amount.toInt()}원',
                style: const TextStyle(
                  color: Color(0xFFEAEAEA),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),

          // 거절 사유 (거절된 경우에만 표시)
          if (refund.status == RefundStatus.rejected &&
              refund.rejectionReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF5350).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFEF5350).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFEF5350),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '거절 사유: ${refund.rejectionReason}',
                      style: const TextStyle(
                        color: Color(0xFFEF5350),
                        fontSize: 12,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 처리 완료 안내 (완료된 경우에만 표시)
          if (refund.status == RefundStatus.completed) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF42A5F5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF42A5F5).withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF42A5F5),
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '환불이 완료되었습니다. 영업일 기준 3~5일 내 계좌로 입금됩니다.',
                      style: TextStyle(
                        color: Color(0xFF42A5F5),
                        fontSize: 12,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
  }
}
