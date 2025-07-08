import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/meeting.dart';
import '../models/game.dart';
import '../models/venue.dart';
import '../models/booking.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/favorites_provider.dart';
import '../services/booking_service.dart';
import '../services/review_service.dart';
import 'booking_payment_screen.dart';
import 'review_list_screen.dart';
import 'host_review_list_screen.dart';
import 'meeting_participants_screen.dart';
import 'host_create_meeting_screen.dart';
import 'favorites_screen.dart';
import '../widgets/common_modal.dart';

class MeetingDetailScreen extends StatefulWidget {
  final String meetingId;
  final bool isPreview;
  final Meeting? previewMeeting;
  final Game? previewGame;
  final Venue? previewVenue;

  const MeetingDetailScreen({
    Key? key,
    required this.meetingId,
    this.isPreview = false,
    this.previewMeeting,
    this.previewGame,
    this.previewVenue,
  }) : super(key: key);

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  final bool _isApplying = false;
  Meeting? _meeting;
  Game? _game;
  Venue? _venue;
  bool _hasApplied = false;
  Booking? _userBooking; // 사용자의 예약 정보
  bool _isCheckingStatus = false; // 상태 확인 중
  late TabController _tabController;
  bool _showAllMenus = false; // 메뉴 더보기 상태
  late FirestoreService _firestoreService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // 탭 변경 시 UI 업데이트
    });

    if (widget.isPreview) {
      _loadPreviewData();
    } else {
      _loadMeetingDetails();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadPreviewData() {
    setState(() {
      _isLoading = true;
    });

    // 미리보기 데이터 설정
    setState(() {
      _meeting = widget.previewMeeting;
      _game = widget.previewGame;
      _venue = widget.previewVenue;
      _hasApplied = false; // 미리보기에서는 신청 상태 없음
      _userBooking = null;
      _isLoading = false;
    });
  }

  Future<void> _loadMeetingDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final firestoreService = Provider.of<FirestoreService>(
        context,
        listen: false,
      );
      var meeting = await firestoreService.getMeetingById(widget.meetingId);

      if (meeting != null) {
        print('📋 Meeting 데이터 로드 완료:');
        print('📋 ID: ${meeting.id}');
        print('📋 Title: ${meeting.title}');
        print('📋 benefitDescription: ${meeting.benefitDescription}');
        print('📋 gameId: ${meeting.gameId}');

        // 모임 상태 자동 확인 및 업데이트
        try {
          final updatedStatus = await firestoreService
              .checkAndUpdateMeetingStatus(meeting.id);
          if (updatedStatus != meeting.status) {
            print('🔄 모임 상태 자동 업데이트: ${meeting.status} -> $updatedStatus');
            // 업데이트된 모임 정보 다시 가져오기
            final updatedMeeting = await firestoreService.getMeetingById(
              widget.meetingId,
            );
            if (updatedMeeting != null) {
              meeting = updatedMeeting;
              print('📋 업데이트된 모임 정보 적용 완료: ${meeting.status}');
            }
          }
        } catch (e) {
          print('⚠️ 모임 상태 자동 업데이트 중 오류: $e');
        }

        // meeting이 null이 아님을 재확인
        if (meeting == null) return;

        setState(() {
          _meeting = meeting;
        });

        // 게임 정보 로드
        if (meeting.gameId != null) {
          print('🎮 게임 정보 로드 시작: ${meeting.gameId}');
          final game = await firestoreService.getGameById(meeting.gameId!);
          if (game != null) {
            print('🎮 게임 정보 로드 성공: ${game.title}');
            print('🎮 게임 이미지 개수: ${game.images.length}');
            print('🎮 게임 이미지 목록: ${game.images}');
          } else {
            print('🎮 게임 정보 로드 실패: 게임을 찾을 수 없음');
          }
          setState(() {
            _game = game;
          });
        } else {
          print('🎮 gameId가 없어서 게임 정보를 로드하지 않음');
        }

        // 장소 정보 로드
        print('🏢 장소 정보 로드 시작');
        print('🏢 Meeting ID: ${meeting.id}');
        print('🏢 Meeting venueId: ${meeting.venueId}');
        print('🏢 Meeting hostId: ${meeting.hostId}');
        print('🏢 Meeting location: ${meeting.location}');
        print(
          '🏢 Meeting createdAt: ${meeting.toString().contains('createdAt')}',
        );

        Venue? venue;

        // 1. venueId가 있으면 그것으로 찾기
        if (meeting.venueId != null && meeting.venueId!.isNotEmpty) {
          print('🏢 venueId로 장소 찾는 중: ${meeting.venueId}');
          venue = await firestoreService.getVenueById(meeting.venueId!);
          if (venue != null) {
            print('🏢 venueId로 장소 찾음: ${venue.name}');
          } else {
            print('🏢 venueId로 장소를 찾을 수 없음');
          }
        }

        // 2. venueId로 찾지 못했으면 hostId로 찾기
        if (venue == null) {
          print('🏢 hostId로 장소 찾는 중: ${meeting.hostId}');
          venue = await firestoreService.getVenueByHostId(meeting.hostId);
          if (venue != null) {
            print('🏢 hostId로 장소 찾음: ${venue.name}');
          } else {
            print('🏢 hostId로도 장소를 찾을 수 없음');
          }
        }

        // 3. 여전히 찾지 못했으면 locations 컬렉션에서 직접 검색
        venue ??= await firestoreService.findVenueInLocationsDebug(
          meeting.hostId,
        );

        // 4. 그래도 찾지 못했으면 기본 장소 정보 생성 (meeting.location 사용)
        if (venue == null && meeting.location.isNotEmpty) {
          print('🏢 기본 장소 정보 생성: ${meeting.location}');
          venue = Venue(
            id: 'default_${meeting.id}',
            name: meeting.location.contains('(')
                ? meeting.location.split('(')[0].trim()
                : meeting.location,
            address:
                meeting.location.contains('(') && meeting.location.contains(')')
                ? meeting.location.split('(')[1].split(')')[0]
                : meeting.location,
            phone: '',
            operatingHours: [],
            imageUrls: [],
            menu: [],
            hostId: meeting.hostId,
            createdAt: DateTime.now(),
          );
          print('🏢 기본 장소 정보 생성 완료: ${venue.name}');
        }

        setState(() {
          _venue = venue;
        });

        if (venue != null) {
          print('🏢 최종 장소 정보 설정 완료: ${venue.name}');
          print('🏢 주소: ${venue.address}');
          print('🏢 영업시간: ${venue.operatingHours}');
          print('🏢 전화번호: ${venue.phone}');
          print('🏢 인스타그램: ${venue.instagram}');
          print('🏢 메뉴 개수: ${venue.menu.length}');
          print('🏢 이미지 개수: ${venue.imageUrls.length}');
        } else {
          print('🏢 장소 정보를 찾을 수 없음');
        }

        // 사용자가 이미 신청했는지 확인
        await _checkApplicationStatus();
      }
    } catch (e) {
      print('모임 정보 로드 실패: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkApplicationStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(
      context,
      listen: false,
    );
    final bookingService = BookingService();

    if (authService.currentUser == null || _meeting == null) return;

    setState(() {
      _isCheckingStatus = true;
    });

    try {
      final userId = authService.currentUser!.uid;

      // 1. 예약 상태 확인 (bookings 컬렉션)
      final userBooking = await bookingService.getUserBookingForMeeting(
        userId,
        _meeting!.id,
      );

      // 2. 신청 상태 확인 (applications 컬렉션)
      final applicationStatus = await firestoreService.getUserApplicationStatus(
        _meeting!.id,
      );

      setState(() {
        _userBooking = userBooking;
        _hasApplied = applicationStatus != null || userBooking != null;
      });

      print('📋 예약/신청 상태 확인 완료:');
      print('  - 예약 상태: ${userBooking?.statusText ?? "없음"}');
      print('  - 신청 상태: ${applicationStatus ?? "없음"}');

      // 거절된 예약이 있는 경우 특별 처리
      if (userBooking?.status == BookingStatus.rejected) {
        print('  - ⚠️ 예약이 거절되었습니다');
      }
    } catch (e) {
      print('❌ 신청/예약 상태 확인 실패: $e');
    } finally {
      setState(() {
        _isCheckingStatus = false;
      });
    }
  }

  Future<void> _applyToMeeting() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }

    if (_meeting == null) return;

    // 예약 및 결제 페이지로 이동
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookingPaymentScreen(meeting: _meeting!),
      ),
    );
  }

  // 예약 취소 함수
  Future<void> _cancelBooking() async {
    if (_userBooking == null) return;

    // 확인 다이얼로그 표시
    final shouldCancel = await ModalUtils.showConfirmModal(
      context: context,
      title: '예약 취소',
      description: '정말로 예약을 취소하시겠습니까?\n취소된 예약은 되돌릴 수 없습니다.',
      confirmText: '취소하기',
      cancelText: '아니요',
      isDestructive: true,
    );

    if (shouldCancel != true) return;

    try {
      setState(() {
        _isCheckingStatus = true;
      });

      final bookingService = BookingService();
      await bookingService.cancelBooking(_userBooking!.id);

      // 상태 새로고침
      await _checkApplicationStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('예약이 취소되었습니다.'),
            backgroundColor: Color(0xFF2E2E2E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('예약 취소에 실패했습니다: $e'),
            backgroundColor: const Color(0xFFF44336),
          ),
        );
      }
    } finally {
      setState(() {
        _isCheckingStatus = false;
      });
    }
  }

  void _navigateToReviews() {
    if (_meeting != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => HostReviewListScreen(
            hostId: _meeting!.hostId,
            hostName: _meeting!.hostName,
          ),
        ),
      );
    }
  }

  void _navigateToParticipantManagement() {
    if (_meeting != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MeetingParticipantsScreen(meeting: _meeting!),
        ),
      );
    }
  }

  void _navigateToEditMeeting() {
    if (_meeting != null && _game != null && _venue != null) {
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (context) => HostCreateMeetingScreen(
                isEditMode: true,
                meetingToEdit: _meeting!,
                gameToEdit: _game!,
                venueToEdit: _venue!,
              ),
            ),
          )
          .then((result) {
            // 수정 완료 후 돌아왔을 때 데이터 새로고침
            if (result == true) {
              _loadMeetingDetails();
            }
          });
    }
  }

  void _showMeetingManagementDialog() {
    if (_meeting == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2E2E2E), // 피그마: #2e2e2e
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들 바 (피그마 디자인과 정확히 일치)
            Container(
              margin: const EdgeInsets.only(top: 14),
              width: 80, // 피그마: 80px
              height: 6, // 피그마: 6px
              decoration: BoxDecoration(
                color: const Color(0xFF8C8C8C), // 피그마: #8c8c8c
                borderRadius: BorderRadius.circular(16), // 피그마: 16px
              ),
            ),

            const SizedBox(height: 24),

            // 헤더 영역 (제목 + 부제목)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 24), // 좌우 24px 마진
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  Text(
                    '모임 관리',
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF), // 피그마: #ffffff
                      fontSize: 20,
                      fontWeight: FontWeight.w700, // Bold
                      fontFamily: 'Pretendard',
                      height: 1.4, // 28px lineHeight / 20px fontSize
                    ),
                  ),

                  const SizedBox(height: 6),

                  // 부제목
                  Text(
                    '모임 : ${_meeting!.title}',
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      color: Color(0xFFA0A0A0), // 피그마: #a0a0a0
                      fontSize: 14,
                      fontWeight: FontWeight.w600, // SemiBold
                      fontFamily: 'Pretendard',
                      height: 1.43, // 20px lineHeight / 14px fontSize
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 옵션 리스트
            Column(
              children: [
                _buildBottomSheetOption(
                  icon: Icons.edit,
                  title: '모임 수정',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToEditMeeting();
                  },
                ),

                const SizedBox(height: 14), // 프레임 간 간격

                _buildBottomSheetOption(
                  icon: Icons.stop_circle,
                  title: '모임 종료',
                  onTap: () async {
                    Navigator.pop(context);
                    await _showEndMeetingConfirmDialog();
                  },
                ),

                const SizedBox(height: 14), // 프레임 간 간격

                _buildBottomSheetOption(
                  icon: Icons.delete,
                  title: '모임 삭제',
                  onTap: () async {
                    Navigator.pop(context);
                    await _showDeleteMeetingConfirmDialog();
                  },
                  isDestructive: true,
                ),
              ],
            ),

            // 하단 여백 (Safe Area)
            SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24), // 좌우 24px 마진
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8), // 피그마: 8px
        child: Container(
          width: double.infinity, // 전체 너비 사용
          height: 52, // 피그마: 52px 높이
          decoration: BoxDecoration(
            color: const Color(0xFF3C3C3C), // 피그마: #3c3c3c
            borderRadius: BorderRadius.circular(8), // 피그마: 8px
          ),
          child: Row(
            children: [
              // 아이콘 영역 (44x44) - 정확한 위치
              Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: isDestructive
                      ? const Color(0xFFF44336)
                      : const Color(0xFFF5F5F5), // 피그마: #f5f5f5
                  size: 24,
                ),
              ),

              // 텍스트 - 아이콘 바로 옆에서 시작
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 16),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isDestructive
                          ? const Color(0xFFF44336)
                          : const Color(0xFFF5F5F5), // 피그마: #f5f5f5
                      fontSize: 16,
                      fontWeight: FontWeight.w700, // Bold
                      fontFamily: 'Pretendard',
                      height: 1.5, // 24px lineHeight / 16px fontSize
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEndMeetingConfirmDialog() async {
    final confirmed = await ModalUtils.showConfirmModal(
      context: context,
      title: '모임 종료',
      description: '모임을 종료하시겠습니까?\n종료된 모임은 더 이상 신청을 받지 않습니다.',
      confirmText: '종료',
      cancelText: '취소',
      isDestructive: true,
    );

    if (confirmed == true) {
      _endMeeting();
    }
  }

  Future<void> _showDeleteMeetingConfirmDialog() async {
    final confirmed = await ModalUtils.showConfirmModal(
      context: context,
      title: '모임 삭제',
      description: '정말로 모임을 삭제하시겠습니까?\n삭제된 모임은 복구할 수 없습니다.',
      confirmText: '삭제',
      cancelText: '취소',
      isDestructive: true,
    );

    if (confirmed == true) {
      _deleteMeeting();
    }
  }

  Future<void> _endMeeting() async {
    try {
      await _firestoreService.updateMeetingStatus(
        widget.meetingId,
        'completed',
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('모임이 종료되었습니다.')));
        _loadMeetingDetails(); // 상태 새로고침
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('모임 종료에 실패했습니다: $e')));
      }
    }
  }

  Future<void> _deleteMeeting() async {
    try {
      await _firestoreService.deleteMeeting(widget.meetingId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('모임이 삭제되었습니다.')));
        Navigator.of(context).pop(); // 이전 화면으로 돌아가기
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('모임 삭제에 실패했습니다: $e')));
      }
    }
  }

  bool get _isHost {
    final authService = Provider.of<AuthService>(context, listen: false);
    return authService.currentUser?.uid == _meeting?.hostId;
  }

  // 테스트용: 현재 모임에 게임 데이터 적용
  Future<void> _applyTestGameData() async {
    try {
      // 샘플 게임 중 첫 번째 게임 사용
      const testGameId = 'game_1';
      const testCoverImageUrl =
          'https://search.pstatic.net/common/?src=https%3A%2F%2Fldb-phinf.pstatic.net%2F20250525_52%2F1748125958192TNHTx_JPEG%2F9359E72A-5968-4D72-AF7A-D13ECCF2FE1F.jpeg';

      await _firestoreService.updateMeetingWithGameData(
        widget.meetingId,
        testGameId,
        coverImageUrl: testCoverImageUrl,
      );

      // 모임 정보 다시 로드
      _loadMeetingDetails();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('게임 데이터가 적용되었습니다!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('게임 데이터 적용 실패: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: _isLoading ? _buildLoadingBody() : _buildMainBody(),
    );
  }

  Widget _buildLoadingBody() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFFF44336)),
    );
  }

  Widget _buildMainBody() {
    if (_meeting == null) {
      return const Center(
        child: Text(
          '모임 정보를 불러올 수 없습니다.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Stack(
      children: [
        // Main Scrollable Content
        Column(
          children: [
            // Status Bar + Top Bar
            _buildTopSection(),
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Hero Image
                    _buildHeroImage(),
                    // Content Section
                    _buildContentSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Fixed Bottom Buttons
        Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomButtons()),
      ],
    );
  }

  Widget _buildTopSection() {
    return Container(
      color: const Color(0xFF111111),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              // Back Button
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              // Title
              Expanded(
                child: Text(
                  widget.isPreview ? '미리 보기' : '모임 상세',
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Favorites List Button (미리보기 모드에서는 숨김)
              if (!widget.isPreview)
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FavoritesScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.favorite_border,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    // 우선순위: 호스트가 업로드한 표지 이미지 -> 기존 imageUrl -> 게임 이미지 -> 기본 이미지
    String? imageUrl;
    if (_meeting?.coverImageUrl?.isNotEmpty == true) {
      imageUrl = _meeting!.coverImageUrl;
      print(
        '🖼️ Hero 이미지: (호스트 설정) coverImageUrl 사용 - ${_meeting!.coverImageUrl}',
      );
    } else if (_game?.imageUrl.isNotEmpty == true) {
      imageUrl = _game!.imageUrl;
      print('🖼️ Hero 이미지: 게임 imageUrl 사용 - ${_game!.imageUrl}');
    } else {
      // 테스트용 기본 이미지
      imageUrl =
          'https://search.pstatic.net/common/?src=https%3A%2F%2Fldb-phinf.pstatic.net%2F20250525_52%2F1748125958192TNHTx_JPEG%2F9359E72A-5968-4D72-AF7A-D13ECCF2FE1F.jpeg';
      print('🖼️ Hero 이미지: 기본 테스트 이미지 사용');
    }

    if (imageUrl == null || imageUrl.isEmpty) {
      // 이미지 URL이 없으면 빈 컨테이너 반환
      return const SizedBox.shrink();
    }

    return Hero(
      tag: 'meeting-image-${_meeting?.id ?? ''}',
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        height: 220,
        color: Colors.black.withOpacity(0.3),
        colorBlendMode: BlendMode.darken,
        placeholder: (context, url) => Container(
          height: 220,
          color: Colors.grey[300],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) {
          print("🖼️ Hero 이미지 로드 실패: $url, 오류: $error");
          return Container(
            height: 220,
            color: Colors.grey[300],
            child: const Icon(Icons.error, color: Colors.red),
          );
        },
      ),
    );
  }

  Widget _buildContentSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          // Header Section
          _buildHeaderSection(),
          const SizedBox(height: 24),
          // Tab Bar + Game Detail
          _buildTabSection(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    final formattedDate = DateFormat(
      'M.d(E) HH시 mm분',
      'ko_KR',
    ).format(_meeting!.scheduledDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            _game?.title ?? _meeting!.title,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFFF5F5F5),
            ),
          ),
          const SizedBox(height: 16),
          // Location & Time
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Color(0xFFD6D6D6),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  '${_meeting!.location} • $formattedDate',
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: Color(0xFFD6D6D6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Tags & Rating
          Row(
            children: [
              // Tags
              Expanded(
                child: Wrap(
                  spacing: 6,
                  children: [
                    if (_game?.tags != null)
                      ..._game!.tags.map((tag) => _buildTag(tag, true)),
                    _buildTag(_game?.difficulty ?? '난이도 정보 없음', false),
                  ],
                ),
              ),
              // Rating - 항상 표시 (피그마 디자인과 동일)
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _navigateToReviews(),
                child: _buildHostRatingWidget(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, bool isHighlight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      decoration: BoxDecoration(
        color: isHighlight ? const Color(0xFFFCC9C5) : const Color(0xFFEAEAEA),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w500,
          fontSize: 12,
          color: isHighlight
              ? const Color(0xFFF44336)
              : const Color(0xFF4B4B4B),
        ),
      ),
    );
  }

  Widget _buildTabSection() {
    return Column(
      children: [
        // Tab Bar
        SizedBox(
          height: 56,
          child: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFFF44336),
            indicatorWeight: 4,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: const Color(0xFFEAEAEA),
            unselectedLabelColor: const Color(0xFF8C8C8C),
            labelStyle: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: '모임 정보'),
              Tab(text: '장소 정보'),
            ],
          ),
        ),
        // Tab Content - 높이 제한 제거하고 직접 내용 표시
        _tabController.index == 0
            ? _buildGameDetailContent()
            : _buildLocationContent(),
      ],
    );
  }

  Widget _buildGameDetailContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Game Subtitle Card
          if (_game?.subtitle.isNotEmpty == true) _buildGameSubtitleCard(),
          if (_game?.subtitle.isNotEmpty == true) const SizedBox(height: 16),

          // Game Intro Card
          if (_game != null) _buildGameIntroCard(),
          if (_game != null) const SizedBox(height: 16),

          // Time Table Card - 게임 규칙이 없어도 자동 생성 타임테이블 표시
          if (_game != null) _buildTimeTableCard(),
          if (_game != null) const SizedBox(height: 16),

          // Benefits Card - 게임이 있으면 항상 표시 (기본 메시지 포함)
          if (_game != null) _buildBenefitsCard(),
          if (_game != null) const SizedBox(height: 16),

          // Target Audience Card - 피그마 디자인 적용
          if (_game?.targetAudience.isNotEmpty == true)
            _buildTargetAudienceCard(),
          if (_game?.targetAudience.isNotEmpty == true)
            const SizedBox(height: 16),

          // Meeting Info Card - 피그마 디자인 적용
          _buildMeetingInfoCard(),

          // 하단 여백 (버튼 공간)
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildLocationContent() {
    if (_venue == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text(
            '장소 정보를 불러올 수 없습니다.',
            style: TextStyle(color: Color(0xFF8C8C8C), fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: [
        // 장소 이미지 갤러리
        _buildVenueImageGallery(),

        // 장소 정보 카드
        _buildVenueInfoCard(),

        // 메뉴 섹션 (항상 표시)
        _buildMenuSection(),

        // 하단 여백 (버튼 공간)
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildVenueImageGallery() {
    // 기본 이미지 URL들 (실제 이미지가 없을 때 사용)
    final defaultImages = [
      'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=400',
      'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=400',
      'https://images.unsplash.com/photo-1559925393-8be0ec4767c8?w=400',
      'https://images.unsplash.com/photo-1521017432531-fbd92d768814?w=400',
      'https://images.unsplash.com/photo-1445116572660-236099ec97a0?w=400',
    ];

    final images = _venue?.imageUrls.isNotEmpty == true
        ? _venue!.imageUrls
        : defaultImages;

    return SizedBox(
      height: 172,
      width: double.infinity,
      child: Row(
        children: [
          // 메인 이미지 (왼쪽)
          Expanded(
            flex: 2,
            child: Container(
              height: 172,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(images[0]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // 작은 이미지들 (오른쪽)
          SizedBox(
            width: 180, // 90 * 2
            child: Column(
              children: [
                // 상단 2개 이미지
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF2E2E2E),
                              width: 1,
                            ),
                            image: DecorationImage(
                              image: NetworkImage(
                                images.length > 1 ? images[1] : images[0],
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF2E2E2E),
                              width: 1,
                            ),
                            image: DecorationImage(
                              image: NetworkImage(
                                images.length > 2 ? images[2] : images[0],
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 하단 2개 이미지
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF2E2E2E),
                              width: 1,
                            ),
                            image: DecorationImage(
                              image: NetworkImage(
                                images.length > 3 ? images[3] : images[0],
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF2E2E2E),
                              width: 1,
                            ),
                            image: DecorationImage(
                              image: NetworkImage(
                                images.length > 4 ? images[4] : images[0],
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallImage(int index) {
    if (index >= _venue!.imageUrls.length) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2E2E2E),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF2E2E2E)),
        ),
        child: const Icon(Icons.image, color: Color(0xFF666666), size: 24),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          _venue!.imageUrls[index],
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFF2E2E2E),
            child: const Icon(Icons.image, color: Color(0xFF666666), size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildVenueInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 장소 이름 헤더
          Text(
            _venue!.name,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFFEAEAEA),
            ),
          ),
          const SizedBox(height: 16),

          // 영업 정보 섹션
          Column(
            children: [
              // 주소
              _buildInfoRow(Icons.location_on_outlined, _venue!.address),
              const SizedBox(height: 8),

              // 영업시간
              if (_venue!.operatingHours.isNotEmpty)
                _buildInfoRow(Icons.access_time, _venue!.operatingHours.first),
              if (_venue!.operatingHours.isNotEmpty) const SizedBox(height: 8),

              // 전화번호
              if (_venue!.phone.isNotEmpty)
                _buildInfoRow(Icons.phone, _venue!.phone),
              if (_venue!.phone.isNotEmpty) const SizedBox(height: 8),

              // 웹사이트 링크
              if (_venue!.website != null && _venue!.website!.isNotEmpty)
                _buildLinkRow(Icons.link, _venue!.website!),
              if (_venue!.website != null && _venue!.website!.isNotEmpty)
                const SizedBox(height: 8),

              // 인스타그램 링크
              if (_venue!.instagram != null && _venue!.instagram!.isNotEmpty)
                _buildLinkRow(Icons.link, _venue!.instagram!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return SizedBox(
      height: 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: const Color(0xFF8C8C8C)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFFEAEAEA),
                height: 1.43, // 20/14 = 1.43 (lineHeight/fontSize)
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkRow(IconData icon, String url) {
    return SizedBox(
      height: 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: const Color(0xFF8C8C8C)),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _launchURL(url),
              child: Text(
                url,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Color(0xFF4A9EFF), // 파란색 링크 색상
                  height: 1.43,
                  decoration: TextDecoration.underline, // 밑줄 추가
                  decorationColor: Color(0xFF4A9EFF),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('링크를 열 수 없습니다.')));
        }
      }
    } catch (e) {
      print('URL 실행 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('링크를 열 수 없습니다.')));
      }
    }
  }

  Widget _buildMenuSection() {
    final menuList = _venue?.menu ?? [];
    final displayMenus = _showAllMenus ? menuList : menuList.take(3).toList();
    final hasMoreMenus = menuList.length > 3;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 메뉴 헤더
          const Text(
            '메뉴',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFFEAEAEA),
            ),
          ),
          const SizedBox(height: 16),

          // 메뉴 리스트
          if (menuList.isEmpty)
            const Center(
              child: Text(
                '메뉴 정보가 없습니다.',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Color(0xFF8C8C8C),
                ),
              ),
            )
          else
            ...displayMenus.map((menu) => _buildMenuItem(menu)).toList(),

          // 더보기 버튼 (메뉴가 있고 3개 초과 시에만 표시)
          if (menuList.isNotEmpty && hasMoreMenus && !_showAllMenus)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _showAllMenus = true;
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF2E2E2E),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '더보기',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Color(0xFFEAEAEA),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFFEAEAEA),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

          // 접기 버튼 (메뉴가 있고 모든 메뉴 표시 중일 때)
          if (menuList.isNotEmpty && hasMoreMenus && _showAllMenus)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _showAllMenus = false;
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF2E2E2E),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '접기',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Color(0xFFEAEAEA),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_up,
                      color: Color(0xFFEAEAEA),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(VenueMenu menu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // 메뉴 이미지
          Container(
            width: 90,
            height: 86,
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E2E),
              borderRadius: BorderRadius.circular(4),
            ),
            child: menu.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      menu.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.restaurant_menu,
                        color: Color(0xFF666666),
                        size: 32,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.restaurant_menu,
                    color: Color(0xFF666666),
                    size: 32,
                  ),
          ),
          const SizedBox(width: 12),

          // 메뉴 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 메뉴 이름
                Text(
                  menu.name,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFFEAEAEA),
                  ),
                ),
                const SizedBox(height: 6),

                // 메뉴 설명
                Text(
                  menu.description,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Color(0xFFC2C2C2),
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // 가격
                Text(
                  '${NumberFormat('#,###').format(menu.price.toInt())}원',
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Color(0xFFEAEAEA),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameSubtitleCard() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 서브타이틀
          Text(
            _game!.subtitle,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFFEAEAEA),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // 첫 번째 게임 이미지 (153px 높이)
          _buildSingleGameImage(index: 0, height: 153),
        ],
      ),
    );
  }

  Widget _buildGameIntroCard() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            '게임 소개',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFFEAEAEA),
            ),
          ),
          const SizedBox(height: 12),
          // Prologue
          if (_game?.prologue.isNotEmpty == true) ...[
            const Text(
              'Prologue',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF6E6E6E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _game!.prologue,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFFD6D6D6),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 게임 소개 이미지 (218px)
          _buildSingleGameImage(index: 1),
          const SizedBox(height: 12),

          // Description
          if (_game?.description.isNotEmpty == true)
            Text(
              _game!.description,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFFD6D6D6),
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeTableCard() {
    // 모임 시작 시간을 기반으로 동적 타임테이블 생성
    final timeTableItems = _generateTimeTable();

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Time Table',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF6E6E6E),
            ),
          ),
          const SizedBox(height: 12),
          // Time Table Items
          ...timeTableItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return Padding(
              padding: EdgeInsets.only(
                bottom: index < timeTableItems.length - 1 ? 16 : 0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Time
                  SizedBox(
                    width: 48,
                    child: Text(
                      item['time']!,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: Color(0xFFD6D6D6),
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Timeline Dot
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC2C2C2),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Activity
                  Expanded(
                    child: Text(
                      item['activity']!,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: Color(0xFFD6D6D6),
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 12),
          // Notice
          const Text(
            '*게임 결과에 따라 일정이 상이해질 수 있습니다.',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: Color(0xFF8C8C8C),
            ),
          ),
          const SizedBox(height: 16),
          // 실제 게임 진행 이미지
          _buildSingleGameImage(index: 2),
          const SizedBox(height: 6),
          const Text(
            '실제 게임 진행 모습',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: Color(0xFF8C8C8C),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 모임 시작 시간 기반 타임테이블 자동 생성
  List<Map<String, String>> _generateTimeTable() {
    if (_meeting == null) return [];

    final startTime = _meeting!.scheduledDate;
    final timeFormat = DateFormat('HH:mm');

    // 게임 타입에 따른 타임테이블 생성
    List<Map<String, String>> timeTable;

    final gameTitle = _game?.title.toLowerCase() ?? '';

    if (gameTitle.contains('마피아') || gameTitle.contains('심리전')) {
      // 마피아 게임 타임테이블
      timeTable = [
        {'time': timeFormat.format(startTime), 'activity': '게임 룰 설명 및 역할 배정'},
        {
          'time': timeFormat.format(startTime.add(const Duration(minutes: 20))),
          'activity': '1라운드 시작 (낮 토론)',
        },
        {
          'time': timeFormat.format(
            startTime.add(const Duration(hours: 1, minutes: 30)),
          ),
          'activity': '파이널 라운드 및 승부 결정',
        },
        {
          'time': timeFormat.format(startTime.add(const Duration(hours: 2))),
          'activity': '게임 결과 발표 및 마무리',
        },
      ];
    } else if (gameTitle.contains('방탈출') || gameTitle.contains('탈출')) {
      // 방탈출 게임 타임테이블
      timeTable = [
        {'time': timeFormat.format(startTime), 'activity': '게임 브리핑 및 팀 구성'},
        {
          'time': timeFormat.format(startTime.add(const Duration(minutes: 15))),
          'activity': '방탈출 게임 시작',
        },
        {
          'time': timeFormat.format(
            startTime.add(const Duration(hours: 1, minutes: 15)),
          ),
          'activity': '게임 종료 및 결과 확인',
        },
        {
          'time': timeFormat.format(
            startTime.add(const Duration(hours: 1, minutes: 30)),
          ),
          'activity': '소감 공유 및 마무리',
        },
      ];
    } else {
      // 기본 타임테이블 (두뇌 게임, 전략 게임 등)
      timeTable = [
        {'time': timeFormat.format(startTime), 'activity': '룰 영상 시청 및 아이스브레이킹'},
        {
          'time': timeFormat.format(startTime.add(const Duration(minutes: 30))),
          'activity': '메인 매치',
        },
        {
          'time': timeFormat.format(
            startTime.add(const Duration(hours: 2, minutes: 30)),
          ),
          'activity': '우승자 발표 또는 데스매치',
        },
      ];
    }

    print('🕐 동적 타임테이블 생성 (${_game?.title ?? "기본"}):');
    for (var item in timeTable) {
      print('  ${item['time']} - ${item['activity']}');
    }

    return timeTable;
  }

  Widget _buildBenefitsCard() {
    // 호스트가 입력한 베테핏과 게임 기본 베테핏을 모두 수집
    List<String> allBenefits = [];

    print('🎁 베테핏 카드 빌드 시작');
    print('🎁 Meeting benefitDescription: ${_meeting?.benefitDescription}');
    print('🎁 Meeting description: ${_meeting?.description}');
    print('🎁 Game description: ${_game?.description}');
    print('🎁 Game benefits: ${_game?.benefits}');

    // 1. 호스트가 입력한 베테핏 (benefitDescription 우선)
    if (_meeting?.benefitDescription?.isNotEmpty == true) {
      allBenefits.add(_meeting!.benefitDescription!);
      print(
        '🎁 호스트 베테핏(benefitDescription) 추가: ${_meeting!.benefitDescription}',
      );
    }
    // 2. description 필드에서 베테핏 확인 (게임 기본 description과 다르면 호스트 입력으로 간주)
    else if (_meeting?.description.isNotEmpty == true &&
        _game?.description != null &&
        _meeting!.description != _game!.description) {
      allBenefits.add(_meeting!.description);
      print('🎁 호스트 베테핏(description) 추가: ${_meeting!.description}');
    }

    // 3. 게임의 기본 베테핏들
    if (_game?.benefits.isNotEmpty == true) {
      allBenefits.addAll(_game!.benefits);
      print('🎁 게임 베테핏 추가: ${_game!.benefits}');
    }

    print('🎁 전체 베테핏 목록: $allBenefits');

    // 베테핏이 하나도 없으면 기본 메시지 표시
    if (allBenefits.isEmpty) {
      print('🎁 베테핏이 없어서 기본 메시지 사용');
      allBenefits.add('게임 플레이를 통한 즐거운 시간과 새로운 인연을 만나보세요!');
    }

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            '참여 혜택',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFFEAEAEA),
            ),
          ),
          const SizedBox(height: 8),
          // Benefits Image (배경 위 텍스트)
          Stack(
            children: [
              _buildSingleGameImage(index: 3), // 참여혜택 배경 이미지
              Container(
                width: double.infinity,
                height: 218,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  gradient: LinearGradient(
                    colors: [Color(0x99000000), Color(0x00000000)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      allBenefits.first,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFFEAEAEA),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Additional Benefits
          if (allBenefits.length > 1)
            Text(
              allBenefits.skip(1).join(' • '),
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: Color(0xFF8C8C8C),
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTargetAudienceCard() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            '추천 대상',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFFEAEAEA),
            ),
          ),
          const SizedBox(height: 8),
          // Target Audience List
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _game!.targetAudience
                  .map(
                    (target) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 7),
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD6D6D6),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              target,
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Color(0xFFD6D6D6),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingInfoCard() {
    final formattedDate = DateFormat(
      'yy.MM.dd(E) a h:mm',
      'ko_KR',
    ).format(_meeting!.scheduledDate);

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            '안내사항',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFFEAEAEA),
            ),
          ),
          const SizedBox(height: 8),
          // Meeting Info Items
          Container(
            child: Column(
              children: [
                _buildInfoItemWithIcon(
                  _buildPriceIcon(),
                  '${NumberFormat('#,###').format(_game?.price ?? 0)}원',
                ),
                const SizedBox(height: 6),
                _buildInfoItemWithIcon(_buildInfoIcon(), '모임 취소 시 자동 전액 환불'),
                const SizedBox(height: 6),
                _buildInfoItemWithIcon(
                  _buildPeopleIcon(),
                  '최소 ${_game?.minParticipants ?? _meeting!.maxParticipants}명 ~ 최대 ${_game?.maxParticipants ?? _meeting!.maxParticipants}명',
                  textColor: const Color(0xFFC2C2C2),
                ),
                const SizedBox(height: 6),
                _buildInfoItemWithIcon(_buildCalendarIcon(), formattedDate),
                const SizedBox(height: 6),
                _buildInfoItemWithIcon(
                  _buildLocationIcon(),
                  _meeting!.location,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItemWithIcon(
    Widget icon,
    String text, {
    Color textColor = const Color(0xFFD6D6D6),
  }) {
    return Row(
      children: [
        SizedBox(width: 24, height: 24, child: icon),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: textColor,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // 커스텀 아이콘들 (피그마 디자인에 맞춤)
  Widget _buildPriceIcon() {
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: Color(0xFF8C8C8C),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          '₩',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoIcon() {
    return const Icon(Icons.info_outline, size: 20, color: Color(0xFF8C8C8C));
  }

  Widget _buildPeopleIcon() {
    return const Icon(Icons.people_outline, size: 20, color: Color(0xFF8C8C8C));
  }

  Widget _buildCalendarIcon() {
    return const Icon(
      Icons.calendar_month_outlined,
      size: 20,
      color: Color(0xFF8C8C8C),
    );
  }

  Widget _buildLocationIcon() {
    return const Icon(
      Icons.location_on_outlined,
      size: 20,
      color: Color(0xFF8C8C8C),
    );
  }

  /// index번째 게임 이미지를 단일 컨테이너로 표현 (fallback 포함)
  Widget _buildSingleGameImage({required int index, double height = 218}) {
    print("🖼️ _buildSingleGameImage 호출 - index: $index");
    print("🖼️ _game 상태: ${_game != null ? 'exists' : 'null'}");

    if (_game != null) {
      print("🖼️ 게임 제목: ${_game!.title}");
      print("🖼️ 게임 imageUrl: ${_game!.imageUrl}");
      print("🖼️ 게임 images 배열 길이: ${_game!.images.length}");
      print("🖼️ 게임 images 배열: ${_game!.images}");
    }

    String? imageUrl;

    // 실제 Firestore 필드명에 맞게 이미지 선택
    if (index == 0) {
      // 대표 게임 이미지 (imageUrl 또는 gameImage)
      if (_game?.imageUrl.isNotEmpty == true) {
        imageUrl = _game!.imageUrl;
        print("🖼️ index 0: imageUrl 사용 - $imageUrl");
      }
    } else if (index == 1) {
      // 게임 소개 이미지 (gameImage 또는 meetingPlayImage)
      // Firestore에서 실제 필드를 직접 확인해야 함
      if (_game?.images != null && _game!.images.length > 1) {
        imageUrl = _game!.images[1];
        print("🖼️ index 1: gameImage 계열 사용 - $imageUrl");
      }
    } else if (index == 2) {
      // 시간표 이미지 (roundersPlayImage 또는 meetingPlayImage)
      if (_game?.images != null && _game!.images.length > 2) {
        imageUrl = _game!.images[2];
        print("🖼️ index 2: 시간표 이미지 사용 - $imageUrl");
      }
    } else if (index == 3) {
      // 베테핏 배경 이미지 (benefitImage) ⭐
      if (_game?.images != null && _game!.images.length > 3) {
        imageUrl = _game!.images[3];
        print("🖼️ index 3: benefitImage 사용 - $imageUrl");
      }
    }

    // 배열에서 찾지 못하면 일반적인 방법으로 시도
    if ((imageUrl == null || imageUrl.isEmpty) &&
        _game?.images != null &&
        _game!.images.length > index) {
      imageUrl = _game!.images[index];
      print("🖼️ index $index: images[$index] 폴백 사용 - $imageUrl");
    }

    if (imageUrl == null || imageUrl.isEmpty) {
      print("🖼️ index $index: placeholder 사용 (imageUrl이 null이거나 비어있음)");
      return _buildPlaceholderImage(height: height);
    }

    print("🖼️ index $index: CachedNetworkImage 생성 - $imageUrl");

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: height,
      placeholder: (context, url) {
        print("🖼️ 이미지 로딩 중: $url");
        return Container(
          height: height,
          color: Colors.grey[300],
          child: const Center(child: CircularProgressIndicator()),
        );
      },
      errorWidget: (context, url, error) {
        print("🖼️ 싱글 게임 이미지 로드 실패: $url, 오류: $error");
        return _buildPlaceholderImage(height: height);
      },
    );
  }

  Widget _buildPlaceholderImage({double height = 218}) {
    return Container(
      height: height,
      color: const Color(0xFF333333),
      child: const Center(
        child: Icon(Icons.image, size: 80, color: Color(0xFF666666)),
      ),
    );
  }

  Widget _buildBottomButtons() {
    // 미리보기 모드에서는 특별한 하단 UI 표시
    if (widget.isPreview) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF111111),
        child: SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E2E),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: Text(
                '📋 미리보기 모드',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFFA0A0A0),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;

    // 1. 자신의 모임인지 확인
    final isOwnMeeting =
        currentUserId != null && currentUserId == _meeting?.hostId;

    // 🔍 디버그 정보 출력
    print('🔍 버튼 로직 디버그:');
    print('  - currentUserId: $currentUserId');
    print('  - meeting.hostId: ${_meeting?.hostId}');
    print('  - isOwnMeeting: $isOwnMeeting');
    print('  - _hasApplied: $_hasApplied');
    print('  - meeting.status: ${_meeting?.status}');

    // 예약 상태에 따른 버튼 표시 결정
    final hasBooking =
        _userBooking != null &&
        _userBooking!.status != BookingStatus.cancelled &&
        _userBooking!.status != BookingStatus.rejected; // 거절된 예약은 '예약 없음'으로 처리
    final isBookingConfirmed =
        hasBooking &&
        (_userBooking!.status == BookingStatus.confirmed ||
            _userBooking!.status == BookingStatus.approved);

    // 거절된 예약이 있는지 확인
    final isBookingRejected = _userBooking?.status == BookingStatus.rejected;
    // 대기 중인 예약이 있는지 확인
    final isBookingPending = _userBooking?.status == BookingStatus.pending;

    print('  - hasBooking: $hasBooking');
    print('  - isBookingConfirmed: $isBookingConfirmed');
    print('  - isBookingRejected: $isBookingRejected');
    print('  - isBookingPending: $isBookingPending');

    // 🚨 호스트가 자신의 모임에 신청한 경우 방지
    if (isOwnMeeting && (_hasApplied || hasBooking)) {
      print('⚠️ 호스트가 자신의 모임에 신청한 상태 감지됨. 신청 데이터 정리가 필요할 수 있습니다.');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF111111),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 호스트용 관리 버튼들
            if (isOwnMeeting) ...[
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToParticipantManagement(),
                        icon: const Icon(Icons.people, size: 20),
                        label: const Text('참가자 관리'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E2E2E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => _showMeetingManagementDialog(),
                        icon: const Icon(Icons.settings, size: 20),
                        label: const Text('모임 관리'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF44336),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ]
            // ⚠️ 호스트가 아닌 일반 사용자만 버튼 표시
            else if (!isOwnMeeting) ...[
              Row(
                children: [
                  // 왼쪽 버튼 (예약 완료 시 예약 취소, 아니면 찜하기)
                  Container(
                    width: isBookingConfirmed && _meeting?.status != 'completed'
                        ? 120
                        : 111,
                    height: 52,
                    child: isBookingConfirmed && _meeting?.status != 'completed'
                        // 예약 완료 상태일 때 예약 취소 버튼
                        ? ElevatedButton(
                            onPressed: _isCheckingStatus
                                ? null
                                : _cancelBooking,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: const Color(0xFFF44336),
                              side: const BorderSide(color: Color(0xFFF44336)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 12,
                              ),
                            ),
                            child: _isCheckingStatus
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFF44336),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    '예약 취소',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                          )
                        // 예약 완료가 아닐 때 찜하기 버튼
                        : Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF8C8C8C),
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Consumer<FavoritesProvider>(
                              builder: (context, favoritesProvider, child) {
                                final isFavorite = favoritesProvider.isFavorite(
                                  widget.meetingId,
                                );
                                return TextButton.icon(
                                  onPressed: () => favoritesProvider
                                      .toggleFavorite(widget.meetingId),
                                  icon: Icon(
                                    isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: const Color(0xFFF5F5F5),
                                    size: 24,
                                  ),
                                  label: const Text(
                                    '찜하기',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                      color: Color(0xFFF5F5F5),
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  // Main Action Button (오른쪽)
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isCheckingStatus
                            ? null
                            : (_meeting?.status == 'completed'
                                  ? null // 🔧 모임 종료 시 비활성화
                                  : (isBookingConfirmed
                                        ? null // 예약 완료 시 비활성화
                                        : (isBookingPending
                                              ? null // 승인 대기 중일 때 비활성화
                                              : _applyToMeeting))), // 미신청 또는 거절된 상태에서 신청 가능
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              (_meeting?.status == 'completed' ||
                                  isBookingConfirmed ||
                                  isBookingPending)
                              ? const Color(0xFFC2C2C2)
                              : const Color(0xFFF44336),
                          foregroundColor:
                              (_meeting?.status == 'completed' ||
                                  isBookingConfirmed ||
                                  isBookingPending)
                              ? const Color(0xFF111111)
                              : const Color(0xFFF5F5F5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                        ),
                        child: _isCheckingStatus
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _meeting?.status == 'completed'
                                    ? '모임 종료'
                                    : (isBookingConfirmed
                                          ? '예약 완료'
                                          : (isBookingPending
                                                ? '승인 대기중'
                                                : (isBookingRejected
                                                      ? '다시 신청하기'
                                                      : '참가 신청하기'))),
                                style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHostRatingWidget() {
    if (_meeting == null) {
      return Row(
        children: [
          const Icon(Icons.star, size: 10, color: Color(0xFFD6D6D6)),
          const SizedBox(width: 1),
          const Text(
            '0.0(0)',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Color(0xFFD6D6D6),
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.chevron_right, size: 12, color: Color(0xFFD6D6D6)),
        ],
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: ReviewService().getHostRatingStats(_meeting!.hostId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              const Icon(Icons.star, size: 10, color: Color(0xFFD6D6D6)),
              const SizedBox(width: 1),
              const Text(
                '평가중...',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: Color(0xFFD6D6D6),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right,
                size: 12,
                color: Color(0xFFD6D6D6),
              ),
            ],
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Row(
            children: [
              const Icon(Icons.star, size: 10, color: Color(0xFFD6D6D6)),
              const SizedBox(width: 1),
              const Text(
                '0.0(0)',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: Color(0xFFD6D6D6),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right,
                size: 12,
                color: Color(0xFFD6D6D6),
              ),
            ],
          );
        }

        final stats = snapshot.data!;
        final averageRating = stats['averageRating'] as double;
        final totalReviews = stats['totalReviews'] as int;

        return Row(
          children: [
            const Icon(Icons.star, size: 10, color: Color(0xFFD6D6D6)),
            const SizedBox(width: 1),
            Text(
              '${averageRating.toStringAsFixed(1)}($totalReviews)',
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Color(0xFFD6D6D6),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right, size: 12, color: Color(0xFFD6D6D6)),
          ],
        );
      },
    );
  }
}
