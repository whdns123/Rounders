import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/meeting.dart';
import '../models/game.dart';
import '../models/venue.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/favorites_provider.dart';
import 'booking_payment_screen.dart';
import 'review_list_screen.dart';

class MeetingDetailScreen extends StatefulWidget {
  final String meetingId;

  const MeetingDetailScreen({Key? key, required this.meetingId})
    : super(key: key);

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
    _loadMeetingDetails();
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

  Future<void> _loadMeetingDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final firestoreService = Provider.of<FirestoreService>(
        context,
        listen: false,
      );
      final meeting = await firestoreService.getMeetingById(widget.meetingId);

      if (meeting != null) {
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

    if (authService.currentUser == null || _meeting == null) return;

    try {
      final applicationStatus = await firestoreService.getUserApplicationStatus(
        _meeting!.id,
      );
      setState(() {
        _hasApplied = applicationStatus != null; // 신청 상태가 있으면 신청한 것으로 처리
      });
    } catch (e) {
      print('신청 상태 확인 실패: $e');
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

  void _navigateToReviews() {
    if (_game != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ReviewListScreen(gameId: _game!.id),
        ),
      );
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
              const Expanded(
                child: Text(
                  '모임 상세',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Test Button (Debug용)
              if (_meeting?.gameId == null)
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    onPressed: _applyTestGameData,
                    icon: const Icon(
                      Icons.bug_report,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ),
                ),

              // Favorite Button
              SizedBox(
                width: 44,
                height: 44,
                child: Consumer<FavoritesProvider>(
                  builder: (context, favoritesProvider, child) {
                    final isFavorite = favoritesProvider.isFavorite(
                      widget.meetingId,
                    );
                    return IconButton(
                      onPressed: () =>
                          favoritesProvider.toggleFavorite(widget.meetingId),
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite
                            ? const Color(0xFFF44336)
                            : Colors.white,
                        size: 24,
                      ),
                    );
                  },
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
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 10, color: Color(0xFFD6D6D6)),
                    const SizedBox(width: 1),
                    Text(
                      '${_game?.rating ?? 4.5}(${_game?.reviewCount ?? 20})',
                      style: const TextStyle(
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
                ),
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

          // Time Table Card
          if (_game?.timeTable.isNotEmpty == true) _buildTimeTableCard(),
          if (_game?.timeTable.isNotEmpty == true) const SizedBox(height: 16),

          // Benefits Card
          if (_game?.benefits.isNotEmpty == true) _buildBenefitsCard(),
          if (_game?.benefits.isNotEmpty == true) const SizedBox(height: 16),

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
    return Container(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time
                  SizedBox(
                    width: 36,
                    child: Text(
                      item['time']!,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: Color(0xFFD6D6D6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Timeline Dot
                  Container(
                    margin: const EdgeInsets.only(top: 7),
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
              _buildSingleGameImage(index: 3),
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
                      _game!.benefits.first,
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
          if (_game!.benefits.length > 1)
            Text(
              _game!.benefits.skip(1).join(' '),
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

    if (index == 0) {
      // 대표 게임 이미지의 경우 imageUrl을 우선 사용
      if (_game?.imageUrl.isNotEmpty == true) {
        imageUrl = _game!.imageUrl;
        print("🖼️ index 0: imageUrl 사용 - $imageUrl");
      } else if (_game?.images != null && _game!.images.isNotEmpty) {
        imageUrl = _game!.images[0];
        print("🖼️ index 0: images[0] 사용 - $imageUrl");
      }
    } else if (_game?.images != null && _game!.images.length > index) {
      imageUrl = _game!.images[index];
      print("🖼️ index $index: images[$index] 사용 - $imageUrl");
    } else {
      print(
        "🖼️ index $index: 사용할 이미지 없음 (images 길이: ${_game?.images.length ?? 0})",
      );
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
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF111111),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Favorite Button
            Container(
              width: 111,
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF8C8C8C)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Consumer<FavoritesProvider>(
                builder: (context, favoritesProvider, child) {
                  final isFavorite = favoritesProvider.isFavorite(
                    widget.meetingId,
                  );
                  return TextButton.icon(
                    onPressed: () =>
                        favoritesProvider.toggleFavorite(widget.meetingId),
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
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
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  );
                },
              ),
            ),
            const SizedBox(width: 14),
            // Apply Button
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _hasApplied
                      ? null
                      : (_isApplying ? null : _applyToMeeting),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasApplied
                        ? const Color(0xFFC2C2C2)
                        : const Color(0xFFF44336),
                    foregroundColor: _hasApplied
                        ? const Color(0xFF111111)
                        : const Color(0xFFF5F5F5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                  ),
                  child: _isApplying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _hasApplied ? '신청 완료' : '참가 신청하기',
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
      ),
    );
  }
}
