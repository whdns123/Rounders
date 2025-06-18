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
import 'booking_cancellation/booking_cancel_step1_screen.dart';

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
                      builder: (context, authService, _) => PopupMenuButton(
                        icon: _buildIconButton(Icons.person_outline),
                        color: const Color(0xFF2E2E2E),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: const Text(
                              '마이페이지',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () async {
                              // 실제 사용자의 호스트 권한 확인
                              Future.microtask(() async {
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
                                    final bool isHost =
                                        userInfo?.isHost ?? false;

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
                                          builder: (context) =>
                                              const MypageScreen(),
                                        ),
                                      );
                                    }
                                  }
                                }
                              });
                            },
                          ),
                          const PopupMenuItem(
                            enabled: false, // 구분선 역할을 위해 비활성화
                            height: 1,
                            child: Divider(
                              color: Color(0xFF424242),
                              thickness: 1,
                            ),
                          ),
                          PopupMenuItem(
                            child: const Text(
                              '모임 만들기',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const HostCreateMeetingScreen(),
                                  ),
                                );
                              });
                            },
                          ),
                          PopupMenuItem(
                            child: const Text(
                              '샘플 게임 추가',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              WidgetsBinding.instance.addPostFrameCallback((
                                _,
                              ) async {
                                try {
                                  await Provider.of<FirestoreService>(
                                    context,
                                    listen: false,
                                  ).addSampleGames();

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('샘플 게임 데이터가 추가되었습니다!'),
                                        backgroundColor: Color(0xFF4CAF50),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('샘플 게임 추가 실패: $e'),
                                        backgroundColor: const Color(
                                          0xFFF44336,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              });
                            },
                          ),
                          PopupMenuItem(
                            child: const Text(
                              '샘플 장소 추가',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              WidgetsBinding.instance.addPostFrameCallback((
                                _,
                              ) async {
                                try {
                                  final user = authService.currentUser;
                                  if (user != null) {
                                    await Provider.of<FirestoreService>(
                                      context,
                                      listen: false,
                                    ).addSampleVenue(user.uid);

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('샘플 장소 데이터가 추가되었습니다!'),
                                          backgroundColor: Color(0xFF4CAF50),
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('샘플 장소 추가 실패: $e'),
                                        backgroundColor: const Color(
                                          0xFFF44336,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              });
                            },
                          ),
                          PopupMenuItem(
                            child: const Text(
                              '샘플 예약 추가',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              WidgetsBinding.instance.addPostFrameCallback((
                                _,
                              ) async {
                                try {
                                  final user = authService.currentUser;
                                  if (user != null) {
                                    await BookingService().addSampleBookings(
                                      user.uid,
                                    );

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('샘플 예약 데이터가 추가되었습니다!'),
                                          backgroundColor: Color(0xFF4CAF50),
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('샘플 예약 추가 실패: $e'),
                                        backgroundColor: const Color(
                                          0xFFF44336,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              });
                            },
                          ),
                          PopupMenuItem(
                            child: const Text(
                              '호스트 신청',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const HostApplicationScreen(),
                                  ),
                                );
                              });
                            },
                          ),
                          PopupMenuItem(
                            child: const Text(
                              '로그아웃',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                authService.signOut();
                              });
                            },
                          ),
                        ],
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
            border: Border.all(color: const Color(0xFF2E2E2E)),
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
                    // 그라데이션 오버레이 (가독성 확보)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              cardColor.withOpacity(0.8),
                              cardColor.withOpacity(0.3),
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                    ),

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
                          Text(
                            '$spotsLeft자리 남았어요!',
                            style: const TextStyle(
                              color: Color(0xFFC2C2C2),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Pretendard',
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
                          color: Color(0xFFD6D6D6),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Pretendard',
                          height: 1.5,
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
                            '${meeting.location} • ${_formatDate(meeting.scheduledDate)}',
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
                            vertical: 0,
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
                            vertical: 0,
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

                        // 평점
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD9D9D9),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 1),
                        Text(
                          '4.5(${meeting.currentParticipants})',
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
    );
  }

  String _formatDate(DateTime date) {
    final weekday = ['일', '월', '화', '수', '목', '금', '토'][date.weekday % 7];
    return '${date.month}.${date.day}($weekday) ${date.hour}시';
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
                        // 샘플 데이터 추가 버튼
                        GestureDetector(
                          onTap: () async {
                            try {
                              await BookingService().addSampleBookings(
                                user.uid,
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('샘플 예약 데이터가 추가되었습니다!'),
                                    backgroundColor: Color(0xFF4CAF50),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('샘플 데이터 추가 실패: $e'),
                                    backgroundColor: const Color(0xFFF44336),
                                  ),
                                );
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E2E2E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '+ 샘플 예약 데이터 추가하기',
                              style: TextStyle(
                                color: Color(0xFFF5F5F5),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  final bookings = snapshot.data ?? [];
                  print('Loaded bookings: ${bookings.length}'); // 디버깅용

                  // 예약 모임이 없을 때
                  if (bookings.isEmpty) {
                    return Column(
                      children: [
                        _buildEmptyReservations(),
                        const SizedBox(height: 16),
                        // 샘플 데이터 추가 버튼
                        GestureDetector(
                          onTap: () async {
                            try {
                              await BookingService().addSampleBookings(
                                user.uid,
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('샘플 예약 데이터가 추가되었습니다!'),
                                    backgroundColor: Color(0xFF4CAF50),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('샘플 데이터 추가: $e'),
                                    backgroundColor: const Color(0xFFF44336),
                                  ),
                                );
                              }
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E2E2E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                '+ 샘플 예약 데이터 추가하기',
                                style: TextStyle(
                                  color: Color(0xFFF5F5F5),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
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
        SizedBox(height: 20),
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
        if (_showAllBookings && bookings.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF44336),
              borderRadius: BorderRadius.circular(3),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MypageScreen()),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF5F5F5),
              ),
              child: const Text(
                '예약 내역 전체 보기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),
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
                child: Container(
                  color: const Color(0xFF2E2E2E),
                  child: const Icon(
                    Icons.event,
                    color: Color(0xFF8C8C8C),
                    size: 32,
                  ),
                ),
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
                      // 상태 태그 (Figma 디자인과 동일한 색상)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: booking.status == BookingStatus.confirmed
                              ? const Color(0xFFF44336) // 예약 확정: 빨간색
                              : booking.status == BookingStatus.cancelled
                              ? const Color(0xFFEAEAEA) // 취소: 회색
                              : const Color(0xFFFCC9C5), // 인원 모집 중: 연한 빨간색
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          booking.statusText,
                          style: TextStyle(
                            color: booking.status == BookingStatus.confirmed
                                ? const Color(0xFFEAEAEA) // 예약 확정: 흰색 텍스트
                                : booking.status == BookingStatus.cancelled
                                ? const Color(0xFF4B4B4B) // 취소: 진한 회색 텍스트
                                : const Color(0xFFF44336), // 인원 모집 중: 빨간색 텍스트
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),

                      // 취소 버튼 (취소되지 않은 예약에만 표시)
                      if (booking.status != BookingStatus.cancelled)
                        GestureDetector(
                          onTap: () => _showCancelBooking(booking),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF8C8C8C),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '취소',
                              style: TextStyle(
                                color: Color(0xFF8C8C8C),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Pretendard',
                              ),
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

                  // 위치와 시간 (Figma 디자인과 동일)
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
                          '${meeting.location} • ${_formatDateTime(booking.bookingDate)}',
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

  void _showCancelBooking(Booking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingCancelStep1Screen(booking: booking),
      ),
    );
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

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade700),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(color: Colors.grey.shade900);
      },
    );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFavorite ? '찜 목록에 추가되었습니다' : '찜 목록에서 제거되었습니다'),
            backgroundColor: const Color(0xFF2E2E2E),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('오류가 발생했습니다'),
            backgroundColor: Color(0xFFF44336),
            duration: Duration(seconds: 2),
          ),
        );
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
