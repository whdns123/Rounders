import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reservation_model.dart';
import '../models/meeting.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'meeting_detail_web_screen.dart';
import 'applicants_screen.dart';
import 'create_meeting_screen.dart';
import 'meeting_detail_screen.dart';

enum ReservationFilter {
  all('전체'),
  upcoming('진행 예정'),
  completed('참여 완료'),
  canceled('취소됨');

  final String label;
  const ReservationFilter(this.label);
}

class ReservationListScreen extends StatefulWidget {
  const ReservationListScreen({Key? key}) : super(key: key);

  @override
  State<ReservationListScreen> createState() => _ReservationListScreenState();
}

class _ReservationListScreenState extends State<ReservationListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FirestoreService _firestoreService;
  late AuthService _authService;
  String? _currentUserId;
  bool _isLoading = true;
  List<ReservationModel> _reservations = [];
  List<Meeting> _hostedMeetings = [];
  ReservationFilter _selectedFilter = ReservationFilter.all;
  bool _isHost = false; // 호스트 여부

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _firestoreService = Provider.of<FirestoreService>(context, listen: false);
      _authService = Provider.of<AuthService>(context, listen: false);
      _currentUserId = _authService.currentUser?.uid;

      if (_currentUserId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 사용자 정보 가져오기 (호스트 여부 확인)
      final userInfo = await _firestoreService.getUserById(_currentUserId!);
      setState(() {
        _isHost = userInfo?.hostedMeetings.isNotEmpty ?? false;
      });

      // 예약 목록 가져오기
      _firestoreService
          .getReservationsByUserId(_currentUserId!)
          .listen((reservations) {
        setState(() {
          _reservations = reservations;
          _isLoading = false;
        });
      });

      // 호스트인 경우 내가 만든 모임 목록 가져오기
      if (_isHost) {
        _firestoreService.getMyHostedMeetings().listen((meetings) {
          setState(() {
            _hostedMeetings = meetings;
          });
        });
      }
    } catch (e) {
      print('데이터 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 필터링된 예약 목록 반환
  List<ReservationModel> get _filteredReservations {
    switch (_selectedFilter) {
      case ReservationFilter.upcoming:
        return _reservations
            .where((r) => !r.isPaid && r.status != 'canceled')
            .toList();
      case ReservationFilter.completed:
        return _reservations
            .where((r) => r.isPaid && r.status != 'canceled')
            .toList();
      case ReservationFilter.canceled:
        return _reservations.where((r) => r.status == 'canceled').toList();
      case ReservationFilter.all:
      default:
        return _reservations;
    }
  }

  // 예약 취소 처리
  Future<void> _cancelReservation(String reservationId) async {
    // 취소 확인 다이얼로그 표시
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('예약 취소'),
        content: const Text('정말로 예약을 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('아니오'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('예, 취소합니다'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestoreService.cancelReservation(reservationId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('예약이 취소되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('예약 취소에 실패했습니다: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('예약 내역', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4A55A2),
        foregroundColor: Colors.white,
        bottom: _isHost
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '내 예약'),
                  Tab(text: '내 모임'),
                ],
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUserId == null
              ? const Center(child: Text('로그인이 필요합니다.'))
              : _isHost
                  ? TabBarView(
                      controller: _tabController,
                      children: [
                        _buildReservationList(),
                        _buildHostedMeetingsList(),
                      ],
                    )
                  : _buildReservationList(),

      // 추가: 호스트인 경우 모임 생성 버튼 표시
      floatingActionButton: _isHost
          ? FloatingActionButton(
              onPressed: () {
                // TODO: 모임 생성 페이지로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateMeetingScreen(),
                  ),
                );
              },
              backgroundColor: const Color(0xFF4A55A2),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  // 필터 선택 위젯
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: ReservationFilter.values.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter.label),
              selected: _selectedFilter == filter,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: Colors.grey.shade200,
              selectedColor: const Color(0xFF4A55A2).withOpacity(0.2),
              checkmarkColor: const Color(0xFF4A55A2),
              labelStyle: TextStyle(
                color: _selectedFilter == filter
                    ? const Color(0xFF4A55A2)
                    : Colors.black87,
                fontWeight: _selectedFilter == filter
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 예약 목록 위젯
  Widget _buildReservationList() {
    if (_reservations.isEmpty) {
      return const Center(child: Text('예약 내역이 없습니다.'));
    }

    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredReservations.length,
            itemBuilder: (context, index) {
              final reservation = _filteredReservations[index];
              return FutureBuilder<Meeting>(
                future: _firestoreService.getMeetingById(reservation.eventId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Card(
                      child: SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return Card(
                      child: ListTile(
                        title: const Text('모임 정보를 불러올 수 없습니다.'),
                        subtitle: Text('예약 ID: ${reservation.id}'),
                      ),
                    );
                  }

                  final meeting = snapshot.data!;
                  final daysUntil =
                      meeting.scheduledDate.difference(DateTime.now()).inDays;

                  String dateLabel;
                  Color dateColor;

                  if (daysUntil == 0) {
                    dateLabel = '오늘';
                    dateColor = Colors.red;
                  } else if (daysUntil > 0) {
                    dateLabel = 'D-$daysUntil';
                    dateColor = Colors.blue;
                  } else {
                    dateLabel = '종료됨';
                    dateColor = Colors.grey;
                  }

                  // 예약 상태에 따른 색상 및 라벨 설정
                  Color statusColor;
                  String statusLabel;

                  if (reservation.status == 'canceled') {
                    statusColor = Colors.grey;
                    statusLabel = '취소됨';
                  } else if (reservation.isPaid) {
                    statusColor = Colors.green;
                    statusLabel = '결제 완료';
                  } else if (reservation.status == 'pending') {
                    statusColor = Colors.orange;
                    statusLabel = '신청됨';
                  } else if (reservation.status == 'accepted') {
                    statusColor = Colors.blue;
                    statusLabel = '승인됨';
                  } else if (reservation.status == 'rejected') {
                    statusColor = Colors.red;
                    statusLabel = '거절됨';
                  } else {
                    statusColor = Colors.grey;
                    statusLabel = '알 수 없음';
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: reservation.status == 'canceled'
                            ? Colors.grey.shade300
                            : reservation.isPaid
                                ? Colors.green.shade300
                                : Colors.blue.shade300,
                        width: 1,
                      ),
                    ),
                    // 취소된 경우 카드 색상 변경
                    color: reservation.status == 'canceled'
                        ? Colors.grey.shade100
                        : null,
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  meeting.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    // 취소된 경우 텍스트에 취소선 추가
                                    decoration: reservation.status == 'canceled'
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: reservation.status == 'canceled'
                                        ? Colors.grey
                                        : null,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: dateColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: dateColor,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  dateLabel,
                                  style: TextStyle(
                                    color: dateColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      meeting.location,
                                      style:
                                          const TextStyle(color: Colors.grey),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${meeting.scheduledDate.year}/${meeting.scheduledDate.month}/${meeting.scheduledDate.day} ${meeting.scheduledDate.hour}:${meeting.scheduledDate.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.paid,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${reservation.amount}원',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MeetingDetailScreen(
                                          meetingId: meeting.id),
                                    ),
                                  );
                                },
                                child: const Text('상세 보기'),
                              ),
                              const SizedBox(width: 8),
                              // 취소된 예약이 아닌 경우에만 취소하기 버튼 표시
                              if (reservation.status != 'canceled')
                                TextButton(
                                  onPressed: () =>
                                      _cancelReservation(reservation.id),
                                  child: const Text(
                                    '취소하기',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              // 종료된 모임이고 취소되지 않은 경우 후기 작성 버튼 표시
                              if (daysUntil < 0 &&
                                  reservation.status != 'canceled' &&
                                  reservation.review == null)
                                TextButton(
                                  onPressed: () {
                                    // TODO: 후기 작성 기능 추가
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('후기 작성 기능은 아직 준비 중입니다.')),
                                    );
                                  },
                                  child: const Text(
                                    '후기 작성',
                                    style: TextStyle(color: Colors.green),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // 내가 호스팅하는 모임 목록 위젯
  Widget _buildHostedMeetingsList() {
    if (_hostedMeetings.isEmpty) {
      return const Center(child: Text('호스팅 중인 모임이 없습니다.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _hostedMeetings.length,
      itemBuilder: (context, index) {
        final meeting = _hostedMeetings[index];
        final daysUntil =
            meeting.scheduledDate.difference(DateTime.now()).inDays;

        String dateLabel;
        Color dateColor;

        if (daysUntil == 0) {
          dateLabel = '오늘';
          dateColor = Colors.red;
        } else if (daysUntil > 0) {
          dateLabel = 'D-$daysUntil';
          dateColor = Colors.blue;
        } else {
          dateLabel = '종료됨';
          dateColor = Colors.grey;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: meeting.isCompleted
                  ? Colors.grey.shade300
                  : Colors.blue.shade300,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MeetingDetailScreen(meetingId: meeting.id),
                    ),
                  );
                },
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        meeting.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: dateColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: dateColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        dateLabel,
                        style: TextStyle(
                          color: dateColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            meeting.location,
                            style: const TextStyle(color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${meeting.scheduledDate.year}/${meeting.scheduledDate.month}/${meeting.scheduledDate.day} ${meeting.scheduledDate.hour}:${meeting.scheduledDate.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.people, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${meeting.currentParticipants}/${meeting.maxParticipants}명',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: meeting.isCompleted
                                ? Colors.grey.shade100
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            meeting.isCompleted ? '종료됨' : '진행 중',
                            style: TextStyle(
                              color: meeting.isCompleted
                                  ? Colors.grey.shade700
                                  : Colors.blue.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ApplicantsScreen(meeting: meeting),
                          ),
                        );
                      },
                      child: const Text('신청자 보기'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
