import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meeting.dart';
import '../models/reservation_model.dart';
import '../services/firestore_service.dart';

class ApplicantsScreen extends StatefulWidget {
  final Meeting meeting;

  const ApplicantsScreen({Key? key, required this.meeting}) : super(key: key);

  @override
  State<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen> {
  late FirestoreService _firestoreService;
  bool _isLoading = true;
  List<ReservationModel> _reservations = [];
  bool _isEventCompleted = false;

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _loadData();

    // 이벤트가 종료되었는지 확인
    _isEventCompleted = widget.meeting.isCompleted ||
        widget.meeting.scheduledDate.isBefore(DateTime.now());
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 이벤트의 예약 목록 가져오기
      _firestoreService
          .getReservationsByEventId(widget.meeting.id)
          .listen((reservations) {
        setState(() {
          _reservations = reservations;
          _isLoading = false;
        });
      });
    } catch (e) {
      print('데이터 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 참가자 상태 변경 (승인/거절)
  Future<void> _updateApplicantStatus(
      ReservationModel reservation, String newStatus) async {
    try {
      await _firestoreService.updateReservationStatus(
          reservation.id, newStatus);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('신청자 상태가 업데이트되었습니다: ${reservation.userName}'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('상태 업데이트에 실패했습니다: $e')),
      );
    }
  }

  // 출석 상태 변경
  Future<void> _updateAttendance(
      ReservationModel reservation, bool attended) async {
    try {
      await _firestoreService.updateReservationAttendance(
          reservation.id, attended);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('출석 상태가 업데이트되었습니다: ${reservation.userName}'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('출석 상태 업데이트에 실패했습니다: $e')),
      );
    }
  }

  // 등수 및 점수 업데이트
  Future<void> _updateResult(ReservationModel reservation,
      {int? rank, int? score}) async {
    try {
      await _firestoreService.updateReservationResult(reservation.id,
          rank: rank, score: score);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('결과가 업데이트되었습니다: ${reservation.userName}'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('결과 업데이트에 실패했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('신청자 관리', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4A55A2),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reservations.isEmpty
              ? const Center(child: Text('신청자가 없습니다.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reservations.length,
                  itemBuilder: (context, index) {
                    final reservation = _reservations[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _getStatusColor(reservation.status).shade300,
                          width: 1,
                        ),
                      ),
                      child: ExpansionTile(
                        title: Text(
                          reservation.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${reservation.userGender} · ${reservation.userAgeGroup} · ${reservation.userPhone}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(reservation.status)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _getStatusLabel(reservation.status),
                                    style: TextStyle(
                                      color:
                                          _getStatusColor(reservation.status),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (reservation.attended)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      '출석',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                if (reservation.rank != null)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${reservation.rank}등',
                                      style: const TextStyle(
                                        color: Colors.amber,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 상태 변경 섹션
                                const Text(
                                  '신청 상태',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildStatusButton(
                                      context,
                                      '승인',
                                      Colors.blue,
                                      reservation.status == 'accepted',
                                      () => _updateApplicantStatus(
                                          reservation, 'accepted'),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildStatusButton(
                                      context,
                                      '거절',
                                      Colors.red,
                                      reservation.status == 'rejected',
                                      () => _updateApplicantStatus(
                                          reservation, 'rejected'),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 8),

                                // 출석 체크 섹션 (모임이 종료된 경우만 표시)
                                if (_isEventCompleted) ...[
                                  const Text(
                                    '출석 여부',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _buildStatusButton(
                                        context,
                                        '출석',
                                        Colors.green,
                                        reservation.attended,
                                        () => _updateAttendance(
                                            reservation, true),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildStatusButton(
                                        context,
                                        '불참',
                                        Colors.grey,
                                        !reservation.attended,
                                        () => _updateAttendance(
                                            reservation, false),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 8),

                                  // 등수 및 점수 섹션
                                  const Text(
                                    '결과',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<int>(
                                          decoration: const InputDecoration(
                                            labelText: '등수',
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8),
                                          ),
                                          value: reservation.rank,
                                          items: [
                                            const DropdownMenuItem<int>(
                                              value: null,
                                              child: Text('선택 안함'),
                                            ),
                                            ...List.generate(
                                              widget.meeting.maxParticipants,
                                              (i) => DropdownMenuItem<int>(
                                                value: i + 1,
                                                child: Text('${i + 1}등'),
                                              ),
                                            ),
                                          ],
                                          onChanged: (value) => _updateResult(
                                              reservation,
                                              rank: value),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: DropdownButtonFormField<int>(
                                          decoration: const InputDecoration(
                                            labelText: '점수',
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8),
                                          ),
                                          value: reservation.score,
                                          items: [
                                            const DropdownMenuItem<int>(
                                              value: null,
                                              child: Text('선택 안함'),
                                            ),
                                            ...List.generate(
                                              5,
                                              (i) => DropdownMenuItem<int>(
                                                value: i + 1,
                                                child: Text('${i + 1}점'),
                                              ),
                                            ),
                                          ],
                                          onChanged: (value) => _updateResult(
                                              reservation,
                                              score: value),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  // 상태 버튼 위젯
  Widget _buildStatusButton(BuildContext context, String label, Color color,
      bool isSelected, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(label),
    );
  }

  // 상태에 따른 색상 반환
  MaterialColor _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'canceled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // 상태에 따른 라벨 반환
  String _getStatusLabel(String status) {
    switch (status) {
      case 'accepted':
        return '승인됨';
      case 'pending':
        return '대기 중';
      case 'rejected':
        return '거절됨';
      case 'canceled':
        return '취소됨';
      default:
        return '알 수 없음';
    }
  }
}
