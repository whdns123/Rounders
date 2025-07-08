import 'package:flutter/material.dart';
import '../models/meeting.dart';
import '../config/booking_policy_config.dart';

class RefundInfoScreen extends StatelessWidget {
  final Meeting meeting;

  const RefundInfoScreen({super.key, required this.meeting});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        title: const Text(
          '환불 규정 안내',
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
            // 동적 환불 정책 표시
            _buildDynamicRefundPolicy(),

            const SizedBox(height: 24),

            // 추가 안내 사항
            _buildAdditionalInfo(),
          ],
        ),
      ),
    );
  }

  // 동적 환불 정책 위젯 생성
  Widget _buildDynamicRefundPolicy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 전액 환불 섹션
        const Text(
          '전액 환불 (100%)',
          style: TextStyle(
            color: Color(0xFFF5F5F5),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildRefundItem('결제 후 30분 이내'),
        _buildRefundItem('모임 시작 4일 전까지'),
        _buildRefundItem('호스트에 의한 모임 취소'),
        _buildRefundItem('승인 거절 또는 시스템 오류'),

        const SizedBox(height: 24),

        // 부분 환불 섹션
        const Text(
          '부분 환불',
          style: TextStyle(
            color: Color(0xFFF5F5F5),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildRefundItem('모임 시작 3일 전까지: 90% 환불'),
        _buildRefundItem('모임 시작 1일 전까지: 50% 환불'),

        const SizedBox(height: 24),

        // 환불 불가 섹션
        const Text(
          '환불 불가',
          style: TextStyle(
            color: Color(0xFFF5F5F5),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildRefundItem('모임 시작 3시간 전부터'),
        _buildRefundItem('모임 진행 중 또는 완료 후'),
      ],
    );
  }

  // 추가 안내 사항 위젯
  Widget _buildAdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚠️ 환불 처리 안내',
          style: TextStyle(
            color: Color(0xFFF5F5F5),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '• 환불 처리는 ${BookingPolicyConfig.refundProcessingDays} 소요됩니다.',
          style: const TextStyle(
            color: Color(0xFF8C8C8C),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '• 문의: ${BookingPolicyConfig.customerServicePhone} (${BookingPolicyConfig.serviceHours})',
          style: const TextStyle(
            color: Color(0xFF8C8C8C),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '• 부분 환불 시 PG사 수수료가 차감됩니다.',
          style: TextStyle(
            color: Color(0xFF8C8C8C),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRefundItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(
              '• ',
              style: TextStyle(
                color: Color(0xFFD6D6D6),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFD6D6D6),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
