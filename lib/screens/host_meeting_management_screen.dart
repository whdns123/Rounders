import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/meeting.dart';
import 'host_create_meeting_screen.dart';
import 'meeting_participants_screen.dart';

class HostMeetingManagementScreen extends StatefulWidget {
  const HostMeetingManagementScreen({super.key});

  @override
  State<HostMeetingManagementScreen> createState() =>
      _HostMeetingManagementScreenState();
}

class _HostMeetingManagementScreenState
    extends State<HostMeetingManagementScreen> {
  late FirestoreService _firestoreService;
  late AuthService _authService;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
    _currentUserId = _authService.currentUser?.uid;
  }

  // 주차별로 모임을 그룹화하는 함수
  Map<String, List<Meeting>> _groupMeetingsByWeek(List<Meeting> meetings) {
    Map<String, List<Meeting>> groupedMeetings = {};

    for (Meeting meeting in meetings) {
      DateTime meetingDate = meeting.scheduledDate;
      String weekKey = _getWeekKey(meetingDate);

      if (!groupedMeetings.containsKey(weekKey)) {
        groupedMeetings[weekKey] = [];
      }
      groupedMeetings[weekKey]!.add(meeting);
    }

    // 날짜순으로 정렬
    for (String key in groupedMeetings.keys) {
      groupedMeetings[key]!.sort(
        (a, b) => a.scheduledDate.compareTo(b.scheduledDate),
      );
    }

    return groupedMeetings;
  }

  // 주차 키 생성 (예: "6월 둘째주")
  String _getWeekKey(DateTime date) {
    int month = date.month;
    int weekOfMonth = ((date.day - 1) ~/ 7) + 1;

    String monthName = '$month월';
    String weekName = '';

    switch (weekOfMonth) {
      case 1:
        weekName = '첫째주';
        break;
      case 2:
        weekName = '둘째주';
        break;
      case 3:
        weekName = '셋째주';
        break;
      case 4:
        weekName = '넷째주';
        break;
      default:
        weekName = '다섯째주';
        break;
    }

    return '$monthName $weekName';
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
          '관리 모임',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 메인 콘텐츠
          _buildMainContent(),
          // 플러스 버튼 (하단 고정)
          Positioned(right: 16, bottom: 16, child: _buildCreateMeetingButton()),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_currentUserId == null) {
      return const Center(
        child: Text('로그인이 필요합니다.', style: TextStyle(color: Colors.white)),
      );
    }

    return StreamBuilder<List<Meeting>>(
      stream: _firestoreService.getHostMeetings(_currentUserId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFF44336)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              '모임을 불러오는 중 오류가 발생했습니다: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        final meetings = snapshot.data ?? [];

        if (meetings.isEmpty) {
          return _buildEmptyState();
        }

        final groupedMeetings = _groupMeetingsByWeek(meetings);

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80), // 플러스 버튼 공간 확보
          child: Column(
            children: groupedMeetings.entries.map((entry) {
              return _buildWeekSection(entry.key, entry.value);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            '아직 만든 모임이 없습니다',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 번째 모임을 만들어보세요!',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSection(String weekTitle, List<Meeting> meetings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 주차 제목
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            weekTitle,
            style: const TextStyle(
              color: Color(0xFFEAEAEA),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Pretendard',
            ),
          ),
        ),

        // 모임 리스트
        ...meetings.map((meeting) => _buildMeetingItem(meeting)).toList(),

        // 구분선
        Container(height: 8, color: const Color(0xFF2E2E2E)),
      ],
    );
  }

  Widget _buildMeetingItem(Meeting meeting) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${meeting.scheduledDate.year}.${meeting.scheduledDate.month.toString().padLeft(2, '0')}.${meeting.scheduledDate.day.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Color(0xFFC2C2C2),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'Pretendard',
              ),
            ),
          ),

          // 모임 카드
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      MeetingParticipantsScreen(meeting: meeting),
                ),
              );
            },
            child: SizedBox(
              height: 76,
              child: Row(
                children: [
                  // 모임 이미지
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E2E2E),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF2E2E2E)),
                    ),
                    child:
                        ((meeting.coverImageUrl?.isNotEmpty ?? false) ||
                            (meeting.imageUrl?.isNotEmpty ?? false))
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              (meeting.coverImageUrl?.isNotEmpty == true)
                                  ? meeting.coverImageUrl!
                                  : meeting.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultImage();
                              },
                            ),
                          )
                        : _buildDefaultImage(),
                  ),

                  const SizedBox(width: 8),

                  // 모임 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 제목
                        Text(
                          meeting.title,
                          style: const TextStyle(
                            color: Color(0xFFEAEAEA),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Pretendard',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 8),

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
                                '${meeting.location} • ${_formatDateTime(meeting.scheduledDate)}',
                                style: const TextStyle(
                                  color: Color(0xFFD6D6D6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Pretendard',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 2),

                        // 참여 인원
                        Row(
                          children: [
                            const Icon(
                              Icons.people_outline,
                              color: Color(0xFFD6D6D6),
                              size: 16,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${meeting.currentParticipants}명 참여',
                              style: const TextStyle(
                                color: Color(0xFFD6D6D6),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Pretendard',
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
        ],
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.event, color: Color(0xFF8C8C8C), size: 32),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[dateTime.weekday - 1];
    final hour = dateTime.hour;
    final minute = dateTime.minute;

    return '${dateTime.month}.${dateTime.day}($weekday) $hour시 ${minute.toString().padLeft(2, '0')}분';
  }

  Widget _buildCreateMeetingButton() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF44336),
        borderRadius: BorderRadius.circular(4),
      ),
      child: IconButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HostCreateMeetingScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add, color: Color(0xFFF5F5F5), size: 24),
      ),
    );
  }
}
