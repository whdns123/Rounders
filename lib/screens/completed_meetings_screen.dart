import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meeting.dart';
import '../models/booking.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'meeting_detail_screen.dart';
import 'review_write_screen.dart';
import 'meeting_participants_screen.dart';

class CompletedMeetingsScreen extends StatefulWidget {
  const CompletedMeetingsScreen({super.key});

  @override
  State<CompletedMeetingsScreen> createState() =>
      _CompletedMeetingsScreenState();
}

class _CompletedMeetingsScreenState extends State<CompletedMeetingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '완료된 모임',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFF44336),
          labelColor: const Color(0xFFF44336),
          unselectedLabelColor: const Color(0xFF8C8C8C),
          tabs: const [
            Tab(text: '주최한 모임'),
            Tab(text: '참가한 모임'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildHostedMeetings(), _buildParticipatedMeetings()],
      ),
    );
  }

  Widget _buildHostedMeetings() {
    return StreamBuilder<List<Meeting>>(
      stream: _firestoreService.getHostCompletedMeetings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFF44336)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              '완료된 모임이 없습니다.',
              style: TextStyle(color: Color(0xFF8C8C8C), fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final meeting = snapshot.data![index];
            return _buildHostMeetingCard(meeting);
          },
        );
      },
    );
  }

  Widget _buildParticipatedMeetings() {
    return StreamBuilder<List<Meeting>>(
      stream: _firestoreService.getUserCompletedMeetings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFF44336)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              '참가한 완료된 모임이 없습니다.',
              style: TextStyle(color: Color(0xFF8C8C8C), fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final meeting = snapshot.data![index];
            return _buildParticipantMeetingCard(meeting);
          },
        );
      },
    );
  }

  Widget _buildHostMeetingCard(Meeting meeting) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 모임 정보
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        meeting.title,
                        style: const TextStyle(
                          color: Color(0xFFEAEAEA),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF44336),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '완료',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatDateTime(meeting.scheduledDate)} • ${meeting.location}',
                  style: const TextStyle(
                    color: Color(0xFF8C8C8C),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '참가자: ${meeting.currentParticipants}명',
                  style: const TextStyle(
                    color: Color(0xFF8C8C8C),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // 액션 버튼들
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF2E2E2E),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MeetingParticipantsScreen(meeting: meeting),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF8C8C8C)),
                      foregroundColor: const Color(0xFFF5F5F5),
                    ),
                    child: const Text('결과 관리'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MeetingDetailScreen(
                            meetingId: meeting.id,
                            isPreview: false,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF44336),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('상세보기'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantMeetingCard(Meeting meeting) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;

    return FutureBuilder<Booking?>(
      future: _getUserBookingForMeeting(meeting.id, userId),
      builder: (context, bookingSnapshot) {
        final booking = bookingSnapshot.data;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // 모임 정보
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            meeting.title,
                            style: const TextStyle(
                              color: Color(0xFFEAEAEA),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (booking?.rank != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getRankColor(booking!.rank!),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${booking.rank}등',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatDateTime(meeting.scheduledDate)} • ${meeting.location}',
                      style: const TextStyle(
                        color: Color(0xFF8C8C8C),
                        fontSize: 14,
                      ),
                    ),
                    if (booking?.rank != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '내 순위: ${booking!.rank}등 / ${meeting.currentParticipants}명',
                        style: const TextStyle(
                          color: Color(0xFFF44336),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 액션 버튼들
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF2E2E2E),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    if (meeting.hasResults) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // 리뷰 작성 화면으로 이동
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReviewWriteScreen(
                                  meetingId: meeting.id,
                                  meetingTitle: meeting.title,
                                  meetingLocation: meeting.location,
                                  meetingDate: meeting.scheduledDate,
                                  meetingImage:
                                      meeting.coverImageUrl ??
                                      meeting.imageUrl ??
                                      '',
                                  participantCount: meeting.currentParticipants,
                                  hostId: meeting.hostId,
                                  hostName: meeting.hostName ?? '',
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFF44336)),
                            foregroundColor: const Color(0xFFF44336),
                          ),
                          child: const Text('리뷰 작성'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MeetingDetailScreen(
                                meetingId: meeting.id,
                                isPreview: false,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF44336),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('상세보기'),
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
  }

  Future<Booking?> _getUserBookingForMeeting(
    String meetingId,
    String? userId,
  ) async {
    if (userId == null) return null;

    try {
      final bookings = await _firestoreService.getMeetingBookings(meetingId);
      return bookings.firstWhere(
        (booking) => booking.userId == userId,
        orElse: () => throw Exception('Booking not found'),
      );
    } catch (e) {
      return null;
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // 금색
      case 2:
        return const Color(0xFFC0C0C0); // 은색
      case 3:
        return const Color(0xFFCD7F32); // 동색
      default:
        return const Color(0xFF8C8C8C); // 회색
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[dateTime.weekday - 1];
    return '${dateTime.month}.${dateTime.day}($weekday) ${dateTime.hour}시 ${dateTime.minute.toString().padLeft(2, '0')}분';
  }
}
