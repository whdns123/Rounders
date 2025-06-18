import 'package:flutter/material.dart';
import '../models/meeting.dart';

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
            // 전액 환불 섹션
            const Text(
              '전액 환불',
              style: TextStyle(
                color: Color(0xFFF5F5F5),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            _buildRefundItem('결제 후 30분 경과 전'),
            _buildRefundItem('참가 신청 후 승인이 완료되지 않은 경우'),
            _buildRefundItem('승인 후 호스트에 의해 내보내진 경우'),
            _buildRefundItem('참여 확정 모임의 진행일 기준 4일 전까지'),
            _buildRefundItem('소셜링 승인이 거절되었을 경우'),
            _buildRefundItem('호스트가 내보내기를 진행했을 경우'),
            _buildRefundItem('호스트가 소셜링을 폐강하거나 인원 미달로 자동 폐강될 경우'),
            _buildRefundItem(
              '소셜링 진행 3시간 전까지 소셜링 채팅방에 진행 여부 (모임 장소 및 시간)에 대한 공지가 없는 경우',
            ),
            _buildRefundItem('소셜링 운영 정보 (인원, 장소, 날짜 및 시간 등)에 큰 변동사항이 생긴 경우'),

            const SizedBox(height: 12),

            const Text(
              '환불은 PG사 승인 취소 기간에 따라 주말, 공휴일을 제외한 영업일 기준 최대 3~5일 소요될 수 있습니다.',
              style: TextStyle(
                color: Color(0xFF8C8C8C),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

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

            _buildRefundItem(
              '참여 확정 모임의 진행일 기준 3일 전부터 (ex. 1월 7일 토요일에 진행되는 모임의 경우 1월 4일 수요일부터 환불 불가)',
            ),
            _buildRefundItem('모임 진행 당일에 신청한 경우'),
          ],
        ),
      ),
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
