import 'package:flutter/material.dart';
import '../models/meeting.dart';
import '../models/booking.dart';
import '../services/firestore_service.dart';

class MeetingParticipantsScreen extends StatefulWidget {
  final Meeting meeting;

  const MeetingParticipantsScreen({super.key, required this.meeting});

  @override
  State<MeetingParticipantsScreen> createState() =>
      _MeetingParticipantsScreenState();
}

class _MeetingParticipantsScreenState extends State<MeetingParticipantsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Booking> _bookings = [];
  bool _isLoading = true;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.meeting.status == 'completed';
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      final bookings = await _firestoreService.getMeetingBookings(
        widget.meeting.id,
      );
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading bookings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    try {
      await _firestoreService.updateBookingStatus(bookingId, status);
      await _loadBookings(); // 목록 새로고침

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'approved' ? '참가를 승인했습니다.' : '참가를 거절했습니다.'),
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateParticipantRank(String bookingId, int rank) async {
    try {
      await _firestoreService.updateBookingRank(bookingId, rank);
      await _loadBookings(); // 목록 새로고침

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('순위가 업데이트되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showRankDialog(Booking booking) {
    int selectedRank = booking.rank ?? 1;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        title: Text(
          '${booking.userName}님의 순위',
          style: const TextStyle(color: Colors.white),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '순위를 선택해주세요',
                style: TextStyle(color: Color(0xFFA0A0A0)),
              ),
              const SizedBox(height: 16),
              DropdownButton<int>(
                value: selectedRank,
                dropdownColor: const Color(0xFF2E2E2E),
                style: const TextStyle(color: Colors.white),
                items: List.generate(
                  _bookings
                      .where((b) => b.status == BookingStatus.approved)
                      .length,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1}등'),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      selectedRank = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Color(0xFFA0A0A0))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateParticipantRank(booking.id, selectedRank);
            },
            child: const Text('확인', style: TextStyle(color: Color(0xFFFF6B35))),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 순위 또는 상태 표시
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E2E2E),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _isCompleted
                          ? '${booking.rank ?? '-'}'
                          : booking.status == BookingStatus.approved
                          ? '✓'
                          : booking.status == BookingStatus.rejected
                          ? '✗'
                          : '?',
                      style: const TextStyle(
                        color: Color(0xFFEAEAEA),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 프로필 이미지 (더미)
                Container(
                  width: 56,
                  height: 68,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF2E2E2E),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),

                // 사용자 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.userName,
                        style: const TextStyle(
                          color: Color(0xFFEAEAEA),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Text(
                            'LV.1',
                            style: TextStyle(
                              color: Color(0xFFA0A0A0),
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Clover',
                            style: TextStyle(
                              color: Color(0xFFA0A0A0),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '카카오톡 연동 계정',
                        style: TextStyle(
                          color: Color(0xFFA0A0A0),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // 액션 버튼
                if (_isCompleted)
                  // 순위 지정 버튼
                  GestureDetector(
                    onTap: () => _showRankDialog(booking),
                    child: Container(
                      width: 75,
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF8C8C8C)),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Center(
                        child: Text(
                          '순위',
                          style: TextStyle(
                            color: Color(0xFFF5F5F5),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                else if (booking.status == BookingStatus.pending)
                  // 승인/거절 버튼
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            _updateBookingStatus(booking.id, 'approved'),
                        child: Container(
                          width: 60,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Center(
                            child: Text(
                              '승인',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () =>
                            _updateBookingStatus(booking.id, 'rejected'),
                        child: Container(
                          width: 60,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF44336),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Center(
                            child: Text(
                              '거절',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  // 이미 처리된 상태 표시
                  Container(
                    width: 75,
                    height: 32,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: booking.status == BookingStatus.approved
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFF44336),
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Center(
                      child: Text(
                        booking.status == BookingStatus.approved
                            ? '승인됨'
                            : '거절됨',
                        style: TextStyle(
                          color: booking.status == BookingStatus.approved
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFF44336),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: const Color(0xFF2E2E2E),
          ),
        ],
      ),
    );
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isCompleted ? '기록 관리' : '참가자 관리',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
            )
          : _bookings.isEmpty
          ? const Center(
              child: Text(
                '참가 신청자가 없습니다.',
                style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: _bookings.length,
              itemBuilder: (context, index) {
                final booking = _bookings[index];
                return _buildParticipantCard(booking);
              },
            ),
    );
  }
}
