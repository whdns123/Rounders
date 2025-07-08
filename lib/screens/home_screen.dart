import 'package:flutter/material.dart';
import '../models/meeting.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../services/favorites_provider.dart';
import 'meeting_detail_screen.dart';
import '../services/auth_service.dart';
import 'host_application_screen.dart';
import 'host_create_meeting_screen.dart';
import 'favorites_screen.dart';
import 'booking_history_screen.dart';
import 'mypage_screen.dart';
import 'host_mypage_screen.dart';
import '../services/booking_service.dart';
import '../models/booking.dart';
import '../services/booking_cancellation_service.dart';
import '../services/iamport_refund_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../services/review_service.dart';
import '../utils/toast_utils.dart';
import '../widgets/common_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showAllBookings = false; // 예약 목록 전체 보기 상태

  @override
  void initState() {
    super.initState();
    // FavoritesProvider 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FavoritesProvider>(context, listen: false).loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Bar
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                color: const Color(0xFF111111),
                child: Row(
                  children: [
                    const Text(
                      '라운더스',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FavoritesScreen(),
                          ),
                        );
                      },
                      child: _buildIconButton(Icons.favorite_border),
                    ),
                    const SizedBox(width: 0),
                    _buildIconButton(Icons.notifications_none),
                    const SizedBox(width: 0),
                    Consumer<AuthService>(
                      builder: (context, authService, _) => GestureDetector(
                        onTap: () async {
                          // 유저 아이콘 터치 시 바로 마이페이지로 이동
                          final user = authService.currentUser;
                          if (user != null) {
                            try {
                              // Firestore에서 최신 유저 정보를 가져와 role 확인
                              final firestoreService =
                                  Provider.of<FirestoreService>(
                                    context,
                                    listen: false,
                                  );
                              final userInfo = await firestoreService
                                  .getUserById(user.uid);
                              final bool isHost = userInfo?.isHost ?? false;

                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => isHost
                                        ? const HostMypageScreen()
                                        : const MypageScreen(),
                                  ),
                                );
                              }
                            } catch (e) {
                              // 에러 발생 시 일반 마이페이지로 이동
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const MypageScreen(),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        child: _buildIconButton(Icons.person_outline),
                      ),
                    ),
                  ],
                ),
              ),

              // Header Text Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '믿을 건 오직 당신의 두뇌뿐.',
                      style: TextStyle(
                        color: Color(0xFFF5F5F5),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Pretendard',
                        height: 1.33,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '지금 예약하고 생존 게임에 합류하세요.',
                      style: TextStyle(
                        color: Color(0xFFF5F5F5),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Pretendard',
                        height: 1.33,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Card List Section - 고정 높이
              SizedBox(
                height: 359, // 피그마 원본 카드 높이
                child: StreamBuilder<List<Meeting>>(
                  stream: Provider.of<FirestoreService>(
                    context,
                  ).getActiveMeetings(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFF44336),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '오류가 발생했습니다',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => setState(() {}),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF44336),
                              ),
                              child: const Text('다시 시도'),
                            ),
                          ],
                        ),
                      );
                    }

                    final meetings = snapshot.data ?? [];

                    if (meetings.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event, size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text(
                              '현재 열려있는 모임이 없습니다',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // 가로 스크롤 카드 리스트
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: meetings.length,
                      itemBuilder: (context, index) {
                        final meeting = meetings[index];
                        return _buildMeetingCard(meeting, index);
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 36),

              // 내 예약 모임 섹션
              _buildMyReservationsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  Widget _buildMeetingCard(Meeting meeting, int index) {
    final colors = [
      Colors.blue.shade900,
      Colors.purple.shade900,
      Colors.green.shade900,
      Colors.orange.shade900,
    ];

    final cardColor = colors[index % colors.length];
    final daysUntil = meeting.scheduledDate.difference(DateTime.now()).inDays;
    final spotsLeft = meeting.maxParticipants - meeting.currentParticipants;

    return Container(
      width: 296,
      height: 357, // 피그마 원본 카드 크기
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MeetingDetailScreen(meetingId: meeting.id),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2E2E2E),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF1A1A1A)), // gray900
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이미지 섹션 - 피그마 원본 높이
              Container(
                height: 281, // 피그마 원본 이미지 높이
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    // 배경 이미지
                    Positioned.fill(child: _buildMeetingThumbnail(meeting)),

                    // 찜하기 버튼
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _FavoriteButton(meetingId: meeting.id),
                    ),

                    // D-Day와 자리 정보
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF44336),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              'D-$daysUntil',
                              style: const TextStyle(
                                color: Color(0xFFEAEAEA),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$spotsLeft자리 남았어요!',
                              style: const TextStyle(
                                color: Color(0xFFFFFFFF),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 제목
                    Positioned(
                      bottom: 48,
                      left: 16,
                      right: 16,
                      child: Text(
                        meeting.title,
                        style: const TextStyle(
                          color: Color(0xFFE5E5E5), // gray200
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Pretendard',
                          height: 1.5,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black87,
                            ),
                            Shadow(
                              offset: Offset(0, 0),
                              blurRadius: 6,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // 정보 섹션 - 피그마 원본 높이
              Container(
                height: 76, // 피그마 원본 정보 영역 높이
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 위치와 시간
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Color(0xFFD6D6D6),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${_extractCafeName(meeting.location)} • ${_formatDate(meeting.scheduledDate)}',
                            style: const TextStyle(
                              color: Color(0xFFD6D6D6),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Pretendard',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // 태그와 평점
                    Row(
                      children: [
                        // 태그
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2, // 세로 가운데 정렬을 위한 패딩 추가
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCC9C5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text(
                            '우승 상품 지급',
                            style: TextStyle(
                              color: Color(0xFFF44336),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2, // 세로 가운데 정렬을 위한 패딩 추가
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAEAEA),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text(
                            '난이도 상',
                            style: TextStyle(
                              color: Color(0xFF4B4B4B),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ),

                        const Spacer(),

                        // 평점 (호스트 리뷰)
                        _buildRatingWidget(meeting.hostId),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final weekday = ['일', '월', '화', '수', '목', '금', '토'][date.weekday % 7];
    return '${date.month}.${date.day}($weekday) ${date.hour}시';
  }

  String _extractCafeName(String location) {
    // 위치 정보에서 카페 이름만 추출 (괄호 앞부분)
    // 예: "커피홀릭 (경기 수원시 영통구 번조로149번길 169 1층 커피홀릭)" -> "커피홀릭"
    final index = location.indexOf('(');
    if (index != -1) {
      return location.substring(0, index).trim();
    }
    return location.trim();
  }

  Widget _buildRatingWidget(String hostId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ReviewService().getHostRatingStats(hostId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              const Icon(Icons.star, size: 12, color: Color(0xFFD9D9D9)),
              const SizedBox(width: 2),
              Text(
                '평가중...',
                style: const TextStyle(
                  color: Color(0xFFD6D6D6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Row(
            children: [
              const Icon(Icons.star, size: 12, color: Color(0xFFD9D9D9)),
              const SizedBox(width: 2),
              Text(
                '0.0(0)',
                style: const TextStyle(
                  color: Color(0xFFD6D6D6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          );
        }

        final stats = snapshot.data!;
        final averageRating = stats['averageRating'] as double;
        final totalReviews = stats['totalReviews'] as int;

        if (totalReviews == 0) {
          return Row(
            children: [
              const Icon(Icons.star, size: 12, color: Color(0xFFD9D9D9)),
              const SizedBox(width: 2),
              Text(
                '0.0(0)',
                style: const TextStyle(
                  color: Color(0xFFD6D6D6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            const Icon(Icons.star, size: 12, color: Color(0xFFD9D9D9)),
            const SizedBox(width: 2),
            Text(
              '${averageRating.toStringAsFixed(1)}($totalReviews)',
              style: const TextStyle(
                color: Color(0xFFD6D6D6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMyReservationsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          const Text(
            '내 예약 모임',
            style: TextStyle(
              color: Color(0xFFF5F5F5),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Pretendard',
              height: 1.33,
            ),
          ),
          const SizedBox(height: 16),

          // 예약 목록
          Consumer<AuthService>(
            builder: (context, authService, _) {
              final user = authService.currentUser;
              if (user == null) {
                return _buildEmptyReservations();
              }

              return StreamBuilder<List<Booking>>(
                stream: BookingService().getUserBookings(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 100,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFF44336),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Column(
                      children: [
                        Container(
                          height: 100,
                          alignment: Alignment.center,
                          child: Text(
                            '예약 정보를 불러올 수 없습니다\n오류: ${snapshot.error}',
                            style: const TextStyle(
                              color: Color(0xFF8C8C8C),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Pretendard',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  }

                  final bookings = snapshot.data ?? [];
                  print('Loaded bookings: ${bookings.length}'); // 디버깅용

                  // 예약 모임이 없을 때
                  if (bookings.isEmpty) {
                    return Column(children: [_buildEmptyReservations()]);
                  }

                  // 예약 모임이 있을 때
                  return _buildBookingsList(bookings);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyReservations() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '현재 예약된 모임이 없어요.',
          style: TextStyle(
            color: Color(0xFF8C8C8C),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
            height: 1.43,
          ),
        ),
        SizedBox(height: 6),
        Text(
          '마음에 드는 모임을 살펴보고 서바이벌 게임에 참여해보세요.',
          style: TextStyle(
            color: Color(0xFF8C8C8C),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
            height: 1.43,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsList(List<Booking> bookings) {
    // Figma 디자인에 따라 기본 3개만 표시하고, 더보기 시 스크롤 가능
    final displayBookings = _showAllBookings
        ? bookings
        : bookings.take(3).toList();

    return Column(
      children: [
        // 예약 카드들
        ...displayBookings.asMap().entries.map((entry) {
          final index = entry.key;
          final booking = entry.value;

          return Column(
            children: [
              _buildBookingCard(booking),
              // 구분선 (마지막 아이템이 아닐 때만)
              if (index < displayBookings.length - 1)
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  color: const Color(0xFF2E2E2E),
                ),
            ],
          );
        }).toList(),

        // 더보기 버튼 (Figma 디자인과 동일)
        if (bookings.length > 3 && !_showAllBookings) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 36,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF8C8C8C)),
              borderRadius: BorderRadius.circular(3),
            ),
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showAllBookings = true;
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF5F5F5),
                backgroundColor: Colors.transparent,
              ),
              child: const Text(
                '더보기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
          ),
        ],

        // 접기 버튼 (더보기 상태일 때)
        if (_showAllBookings && bookings.length > 3) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 36,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF8C8C8C)),
              borderRadius: BorderRadius.circular(3),
            ),
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showAllBookings = false;
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF5F5F5),
                backgroundColor: Colors.transparent,
              ),
              child: const Text(
                '접기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
          ),
        ],

        // 마이페이지 이동 버튼 (전체보기 상태에서만)
        if (_showAllBookings && bookings.isNotEmpty) ...[],
      ],
    );
  }

  // Figma 디자인에 맞는 예약 카드
  Widget _buildBookingCard(Booking booking) {
    final meeting = booking.meeting;

    // 디버깅 정보 출력
    print(
      'Building booking card: ${booking.id}, meeting: ${meeting?.title ?? 'null'}',
    );

    if (meeting == null) {
      // 모임 정보가 없는 경우
      return SizedBox(
        height: 76,
        child: Row(
          children: [
            // 모임 이미지 (Figma 디자인과 동일)
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFF2E2E2E),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF2E2E2E)),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Color(0xFF8C8C8C),
                size: 32,
              ),
            ),

            const SizedBox(width: 12),

            // 콘텐츠 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 에러 상태 태그
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E2E2E),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Text(
                      '모임 정보 없음',
                      style: TextStyle(
                        color: Color(0xFF8C8C8C),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),

                  // 에러 메시지
                  const Text(
                    '모임 정보를 불러올 수 없습니다',
                    style: TextStyle(
                      color: Color(0xFF8C8C8C),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Pretendard',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // 예약번호
                  Text(
                    '예약번호: ${booking.bookingNumber}',
                    style: const TextStyle(
                      color: Color(0xFF6E6E6E),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Pretendard',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingHistoryScreen(
              meeting: meeting,
              bookingNumber: booking.bookingNumber,
            ),
          ),
        );
      },
      child: SizedBox(
        height: 76,
        child: Row(
          children: [
            // 모임 이미지 (Figma 디자인과 동일)
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF2E2E2E)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: _buildBookingThumbnail(meeting),
              ),
            ),

            const SizedBox(width: 12),

            // 콘텐츠 영역 (Figma 디자인과 동일)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 상단 영역: 상태 태그와 취소 버튼
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 상태 태그 (모든 BookingStatus 고려)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: _getBookingStatusColor(booking.status),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          booking.statusText,
                          style: TextStyle(
                            color: _getBookingStatusTextColor(booking.status),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 모임 제목 (Figma 디자인과 동일)
                  Text(
                    meeting.title,
                    style: TextStyle(
                      color: booking.status == BookingStatus.cancelled
                          ? const Color(0xFF6E6E6E)
                          : const Color(0xFFEAEAEA),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Pretendard',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // 장소와 시간 (주소는 제거하고 장소 이름만 표시)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: booking.status == BookingStatus.cancelled
                            ? const Color(0xFF6E6E6E)
                            : const Color(0xFFD6D6D6),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '${_extractCafeName(meeting.location)} • ${_formatDateTime(booking.bookingDate)}',
                          style: TextStyle(
                            color: booking.status == BookingStatus.cancelled
                                ? const Color(0xFF6E6E6E)
                                : const Color(0xFFD6D6D6),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[dateTime.weekday - 1];
    return '${dateTime.month}.${dateTime.day}($weekday) ${dateTime.hour}시 ${dateTime.minute.toString().padLeft(2, '0')}분';
  }

  // 미팅 카드 썸네일
  Widget _buildMeetingThumbnail(Meeting meeting) {
    String? imageUrl = meeting.coverImageUrl;
    if ((imageUrl == null || imageUrl.isEmpty) &&
        meeting.imageUrls.isNotEmpty) {
      imageUrl = meeting.imageUrls.first;
    }

    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(color: Colors.transparent);
    }

    return Stack(
      children: [
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade700),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(color: Colors.grey.shade900);
          },
        ),
        // 텍스트 가독성을 위한 오버레이
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0x66000000), // #000000 40% 투명도
          ),
        ),
      ],
    );
  }

  // 예약 카드 썸네일 (기본 아이콘 포함)
  Widget _buildBookingThumbnail(Meeting meeting) {
    String? imageUrl = meeting.coverImageUrl;
    if ((imageUrl == null || imageUrl.isEmpty) &&
        meeting.imageUrls.isNotEmpty) {
      imageUrl = meeting.imageUrls.first;
    }

    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: const Color(0xFF2E2E2E),
        child: const Icon(Icons.event, color: Color(0xFF8C8C8C), size: 32),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFF2E2E2E),
        child: const Icon(Icons.event, color: Color(0xFF8C8C8C), size: 32),
      ),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: const Color(0xFF2E2E2E),
          child: const CircularProgressIndicator(
            color: Color(0xFF8C8C8C),
            strokeWidth: 2,
          ),
        );
      },
    );
  }

  // 예약 상태별 배경색 반환
  Color _getBookingStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return const Color(0xFFF44336); // 예약 확정: 빨간색
      case BookingStatus.pending:
        return const Color(0xFFFCC9C5); // 승인 대기중: 연한 빨간색
      case BookingStatus.approved:
        return const Color(0xFFF44336); // 승인됨: 빨간색
      case BookingStatus.cancelled:
        return const Color(0xFFEAEAEA); // 취소: 회색
      case BookingStatus.completed:
        return const Color(0xFFF44336); // 완료: 빨간색
      case BookingStatus.rejected:
        return const Color(0xFF9E9E9E); // 거절됨: 진한 회색
    }
  }

  // 예약 상태별 텍스트색 반환
  Color _getBookingStatusTextColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return const Color(0xFFEAEAEA); // 예약 확정: 흰색 텍스트
      case BookingStatus.pending:
        return const Color(0xFFF44336); // 승인 대기중: 빨간색 텍스트
      case BookingStatus.approved:
        return const Color(0xFFEAEAEA); // 승인됨: 흰색 텍스트
      case BookingStatus.cancelled:
        return const Color(0xFF4B4B4B); // 취소: 진한 회색 텍스트
      case BookingStatus.completed:
        return const Color(0xFFEAEAEA); // 완료: 흰색 텍스트
      case BookingStatus.rejected:
        return const Color(0xFFEAEAEA); // 거절됨: 흰색 텍스트
    }
  }
}

class _FavoriteButton extends StatefulWidget {
  final String meetingId;

  const _FavoriteButton({required this.meetingId});

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // FavoritesProvider는 홈 화면에서 이미 초기화되므로 여기서는 별도 작업 없음
  }

  Future<void> _handleTap() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final favoritesProvider = Provider.of<FavoritesProvider>(
        context,
        listen: false,
      );
      await favoritesProvider.toggleFavorite(widget.meetingId);

      if (mounted) {
        final isFavorite = favoritesProvider.isFavorite(widget.meetingId);
        ToastUtils.showSuccess(
          context,
          isFavorite ? '찜 목록에 추가되었습니다' : '찜 목록에서 제거되었습니다',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, '오류가 발생했습니다');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        if (!favoritesProvider.isLoaded) {
          return Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          );
        }

        final isFavorite = favoritesProvider.isFavorite(widget.meetingId);

        return GestureDetector(
          onTap: _isLoading ? null : _handleTap,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      key: ValueKey(isFavorite),
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? const Color(0xFFF44336)
                          : Colors.white,
                      size: 20,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
