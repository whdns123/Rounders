import 'package:flutter/material.dart';
import '../models/meeting.dart';
import 'shop_screen.dart';
import 'reservation_list_screen.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import 'meeting_detail_screen.dart';
import 'mypage_screen.dart';
import 'lounge_screen.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  // 현재 선택된 모임 카드 인덱스
  int _currentCardIndex = 0;
  late PageController _pageController;
  bool _isCreatingMeeting = false;
  bool _isLoading = true;
  List<Meeting> _meetings = [];
  bool _isHost = false;

  @override
  void initState() {
    super.initState();
    // 페이지 컨트롤러 초기화 (viewportFraction을 조정하여 여러 카드가 보이게 함)
    _pageController =
        PageController(initialPage: _currentCardIndex, viewportFraction: 0.85);

    // 실제 모임 데이터 로드
    _loadMeetings();

    // 호스트 여부 확인
    _checkIsHost();
  }

  // Firebase에서 모임 데이터 로드
  Future<void> _loadMeetings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);

      // 비동기로 직접 데이터를 가져와서 처리
      firestoreService.getActiveMeetings().listen((meetings) {
        if (mounted) {
          setState(() {
            _meetings = meetings;
            _isLoading = false;
          });
        }
      }, onError: (error) {
        if (mounted) {
          setState(() {
            print('모임 데이터 로드 오류: $error');
            _isLoading = false;
            // 오류 발생 시 빈 리스트 사용
            _meetings = [];
          });
        }
      });
    } catch (e) {
      print('모임 데이터 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // 오류 발생 시 빈 리스트 사용
          _meetings = [];
        });
      }
    }
  }

  // 호스트 여부 확인
  Future<void> _checkIsHost() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);

      if (authService.currentUser != null) {
        final hostStatus = await firestoreService
            .getHostApplicationStatus(authService.currentUser!.uid);

        if (mounted) {
          setState(() {
            _isHost = hostStatus['isHost'] ?? false;
          });
        }
      }
    } catch (e) {
      print('호스트 상태 확인 실패: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 테스트 모임 생성
  Future<void> _createTestMeeting() async {
    if (_isCreatingMeeting) return;

    setState(() {
      _isCreatingMeeting = true;
    });

    try {
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);

      final meetingId = await firestoreService.createTestMeeting();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모임이 성공적으로 생성되었습니다!')),
        );

        // 모임 데이터 새로고침
        await _loadMeetings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('모임 생성 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingMeeting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Firebase에서 가져온 실제 모임 데이터만 사용
    final displayMeetings = _meetings;

    // 화면 목록
    final List<Widget> screens = [
      // 홈 화면
      SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(height: 8),
                    ),
                    // 인사말 헤더
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Roundus',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // "내 모임 보기" 버튼 (알림 아이콘에서 변경)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.groups, size: 20),
                            label: const Text('내 모임 보기'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ReservationListScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A55A2),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 섹션 제목
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '오늘의 라운더스 모임',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 모임이 없는 경우 표시할 메시지
                    if (displayMeetings.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(Icons.event_busy,
                                  size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                '현재 예정된 모임이 없습니다.\n+ 버튼을 눌러 모임을 만들어보세요!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      // 3D 캐러셀 스타일 모임 카드 슬라이더
                      SizedBox(
                        height: 460,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: displayMeetings.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentCardIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            // 각 모임 카드에 변환 효과 적용 (AnimatedBuilder 대신 직접 리스너 사용)
                            return AnimatedBuilder(
                              animation: _pageController,
                              builder: (context, child) {
                                double value = 1.0;

                                // 페이지 컨트롤러에서 현재 페이지 위치 계산
                                if (_pageController.position.haveDimensions) {
                                  value = _pageController.page! - index;
                                  // 변환 값 범위 조정 (-1 ~ 1)
                                  value = (1 - (value.abs() * 0.5))
                                      .clamp(0.85, 1.0);
                                }

                                // 3D 변환 효과 적용
                                return Transform.scale(
                                  scale: value,
                                  child: Transform(
                                    transform: Matrix4.identity()
                                      ..setEntry(3, 2, 0.001) // 3D 효과를 위한 원근 변환
                                      ..rotateY(value - 1 != 0.0
                                          ? (1 - value) * 0.3
                                          : 0.0), // 회전 효과
                                    alignment: value - 1 != 0.0
                                        ? value > 1
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft
                                        : Alignment.center,
                                    child: Opacity(
                                      opacity: value,
                                      child: child,
                                    ),
                                  ),
                                );
                              },
                              child: CarouselMeetingCard(
                                  meeting: displayMeetings[index]),
                            );
                          },
                        ),
                      ),

                    // 하단 여백
                    const SizedBox(height: 20),

                    // 페이지 인디케이터 (모임이 있을 경우에만 표시)
                    if (displayMeetings.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            displayMeetings.length,
                            (index) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentCardIndex == index
                                    ? Colors.indigo
                                    : Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),

      // 숍 화면
      const ShopScreen(),

      // 라운지(커뮤니티) 화면
      const LoungeScreen(),

      // 마이페이지 화면
      const MyPageScreen(),
    ];

    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.notifications_none,
                    color: Color(0xFF4A55A2)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('알림 기능은 아직 준비 중입니다.')),
                  );
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: Color(0xFF4A55A2)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('검색 기능은 아직 준비 중입니다.')),
                    );
                  },
                ),
              ],
            )
          : null,
      body: screens[_selectedIndex],
      // 호스트인 경우에만 모임 생성 버튼 표시
      floatingActionButton: (_selectedIndex == 0 && _isHost)
          ? FloatingActionButton(
              onPressed: _isCreatingMeeting ? null : _createTestMeeting,
              backgroundColor: Colors.indigo,
              shape: const CircleBorder(),
              tooltip: '모임 생성하기',
              child: _isCreatingMeeting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed, // 4개 이상의 아이템을 위해 필요
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: '숍',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum),
            label: '라운지',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '마이페이지',
          ),
        ],
      ),
    );
  }
}

class CarouselMeetingCard extends StatelessWidget {
  final Meeting meeting;

  const CarouselMeetingCard({super.key, required this.meeting});

  @override
  Widget build(BuildContext context) {
    String imageUrl = '';

    // 이미지 결정 로직 - 실제 모임 이미지만 사용
    if (meeting.imageUrls.isNotEmpty) {
      // Firebase URL 사용
      imageUrl = meeting.imageUrls[0];
    } else if (meeting.imageUrl != null && meeting.imageUrl!.isNotEmpty) {
      // 기존 이미지 URL 사용
      imageUrl = meeting.imageUrl!;
    }

    // 날짜 형식 지정
    String dateText = '내일 오후 6시';
    // 날짜 표시 형식 개선
    try {
      final now = DateTime.now();
      final meetingDate = meeting.scheduledDate;

      // 오늘인 경우
      if (meetingDate.year == now.year &&
          meetingDate.month == now.month &&
          meetingDate.day == now.day) {
        dateText =
            '오늘 ${meetingDate.hour > 12 ? '오후 ${meetingDate.hour - 12}' : '오전 ${meetingDate.hour}'}시';
      }
      // 내일인 경우
      else if (meetingDate.difference(now).inDays == 1) {
        dateText =
            '내일 ${meetingDate.hour > 12 ? '오후 ${meetingDate.hour - 12}' : '오전 ${meetingDate.hour}'}시';
      }
      // 그 외
      else {
        dateText =
            '${meetingDate.month}월 ${meetingDate.day}일 ${meetingDate.hour > 12 ? '오후 ${meetingDate.hour - 12}' : '오전 ${meetingDate.hour}'}시';
      }
    } catch (e) {
      // 날짜 파싱 실패 시 기본값 사용
      dateText = '예정된 모임';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Card(
        elevation: 8,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    MeetingDetailScreen(meetingId: meeting.id),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 이미지
              Stack(
                children: [
                  // 이미지 표시 (Asset 또는 Network URL)
                  imageUrl.isNotEmpty
                      ? (imageUrl.startsWith('assets/') 
                          ? Image.asset(
                              imageUrl,
                              width: double.infinity,
                              height: 270,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Asset 이미지 로드 실패 시 대체 이미지 표시
                                return Container(
                                  width: double.infinity,
                                  height: 270,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            )
                          : Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: 270,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Network 이미지 로드 실패 시 대체 이미지 표시
                                return Container(
                                  width: double.infinity,
                                  height: 270,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ))
                      : Container(
                          width: double.infinity,
                          height: 270,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                  // 이미지 위에 그라데이션 효과
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 제목을 이미지 위에 표시
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Text(
                      meeting.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 3,
                            color: Color.fromARGB(180, 0, 0, 0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 설명
                    Text(
                      meeting.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    // 위치 및 날짜 정보
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.indigo),
                        const SizedBox(width: 4),
                        Text(
                          meeting.location,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Spacer(),
                        const Icon(Icons.calendar_today,
                            size: 16, color: Colors.indigo),
                        const SizedBox(width: 4),
                        Text(
                          dateText,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 참가자 및 가격 정보
                    Row(
                      children: [
                        const Icon(Icons.people,
                            size: 16, color: Colors.indigo),
                        const SizedBox(width: 4),
                        Text(
                          '${meeting.currentParticipants}/${meeting.maxParticipants}명',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${meeting.price}원',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade700,
                            ),
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
}

// 다른 카드 클래스들은 필요 시 사용하거나 삭제할 수 있습니다.
