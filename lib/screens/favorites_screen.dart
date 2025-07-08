import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meeting.dart';
import '../services/firestore_service.dart';
import '../services/favorites_provider.dart';
import 'meeting_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
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
          '찜한 모임',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<List<Meeting>>(
          stream: Provider.of<FirestoreService>(context).getFavoriteMeetings(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFF44336)),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text(
                      '오류가 발생했습니다',
                      style: TextStyle(color: Colors.white, fontSize: 14),
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

            final favoriteMeetings = snapshot.data ?? [];

            // 찜한 모임이 없을 때
            if (favoriteMeetings.isEmpty) {
              return _buildEmptyFavorites();
            }

            // 찜한 모임이 있을 때
            return _buildFavoritesList(favoriteMeetings);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyFavorites() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E2E),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.favorite_border,
              size: 40,
              color: Color(0xFF8C8C8C),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '찜한 모임이 없어요',
            style: TextStyle(
              color: Color(0xFFF5F5F5),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Pretendard',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '마음에 드는 모임을 찜해보세요',
            style: TextStyle(
              color: Color(0xFF8C8C8C),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Pretendard',
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              '모임 둘러보기',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(List<Meeting> meetings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '총 ${meetings.length}개의 모임',
            style: const TextStyle(
              color: Color(0xFF8C8C8C),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Pretendard',
            ),
          ),
          const SizedBox(height: 16),

          // 세로 리스트 형태로 모임 카드 표시
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: meetings.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final meeting = meetings[index];
              return _buildFavoriteListItem(meeting, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(Meeting meeting, int index) {
    final colors = [
      Colors.blue.shade900,
      Colors.purple.shade900,
      Colors.green.shade900,
      Colors.orange.shade900,
    ];

    final cardColor = colors[index % colors.length];
    final daysUntil = meeting.scheduledDate.difference(DateTime.now()).inDays;
    final spotsLeft = meeting.maxParticipants - meeting.currentParticipants;

    return InkWell(
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
            // 이미지 섹션
            Expanded(
              flex: 3,
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
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
                child: Stack(
                  children: [
                    // 찜하기 버튼 (채워진 하트)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => _removeFavorite(meeting.id),
                        child: Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.favorite,
                            color: Color(0xFFF44336),
                            size: 18,
                          ),
                        ),
                      ),
                    ),

                    // D-Day 정보
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
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
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                    ),

                    // 제목
                    Positioned(
                      bottom: 8,
                      left: 12,
                      right: 12,
                      child: Text(
                        meeting.title,
                        style: const TextStyle(
                          color: Color(0xFFD6D6D6),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Pretendard',
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 정보 섹션
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 위치와 시간
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 12,
                          color: Color(0xFFD6D6D6),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${meeting.location} • ${_formatDate(meeting.scheduledDate)}',
                            style: const TextStyle(
                              color: Color(0xFFD6D6D6),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Pretendard',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // 태그
                    Wrap(
                      spacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCC9C5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text(
                            '우승 상품',
                            style: TextStyle(
                              color: Color(0xFFF44336),
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAEAEA),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text(
                            '난이도 상',
                            style: TextStyle(
                              color: Color(0xFF4B4B4B),
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // 자리 정보
                    Text(
                      '$spotsLeft자리 남음',
                      style: const TextStyle(
                        color: Color(0xFFC2C2C2),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteListItem(Meeting meeting, int index) {
    final daysUntil = meeting.scheduledDate.difference(DateTime.now()).inDays;

    return Container(
      height: 76, // 피그마 디자인 정확한 높이
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MeetingDetailScreen(meetingId: meeting.id),
            ),
          );
        },
        child: Row(
          children: [
            // 왼쪽 모임 이미지 (피그마 디자인: 76x76)
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4), // 피그마 디자인 radius
                border: Border.all(color: const Color(0xFF2E2E2E)),
                color: const Color(0xFF2E2E2E), // 기본 배경색
              ),
              child: Stack(
                children: [
                  // 이미지 표시
                  if ((meeting.coverImageUrl?.isNotEmpty ?? false) ||
                      (meeting.imageUrl?.isNotEmpty ?? false))
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        (meeting.coverImageUrl?.isNotEmpty == true)
                            ? meeting.coverImageUrl!
                            : meeting.imageUrl!,
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _getGradientColors(index)[0],
                                  _getGradientColors(index)[1],
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.image,
                              color: Colors.white54,
                              size: 32,
                            ),
                          );
                        },
                      ),
                    )
                  else
                    // 이미지가 없을 때만 그라데이션 표시
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getGradientColors(index)[0],
                            _getGradientColors(index)[1],
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.image,
                        color: Colors.white54,
                        size: 32,
                      ),
                    ),
                  // D-Day 배지 (왼쪽 상단)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
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
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                  ),
                  // 찜하기 하트 아이콘 (오른쪽 상단)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _FavoritesScreenButton(meetingId: meeting.id),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8), // 피그마 디자인 간격
            // 오른쪽 콘텐츠 영역 (피그마 디자인: 244x76)
            Expanded(
              child: SizedBox(
                height: 76,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 태그: 모집 중 (피그마 디자인 그대로)
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
                        '모집 중',
                        style: TextStyle(
                          color: Color(0xFFF44336),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Pretendard',
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12), // 태그와 제목 사이 간격
                    // 모임 제목 (피그마 디자인)
                    Text(
                      meeting.title,
                      style: const TextStyle(
                        color: Color(0xFFEAEAEA),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Pretendard',
                        height: 1.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4), // 제목과 위치 사이 간격
                    // 위치와 시간 정보 (피그마 디자인)
                    Row(
                      children: [
                        // 위치 아이콘 (피그마에서는 16x16)
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Color(0xFFD6D6D6),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${meeting.location} • ${_formatTime(meeting.scheduledDate)}',
                            style: const TextStyle(
                              color: Color(0xFFD6D6D6),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Pretendard',
                              height: 1.5,
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
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final weekday = ['일', '월', '화', '수', '목', '금', '토'][date.weekday % 7];
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.month}.${date.day}($weekday) $hour시 $minute분';
  }

  List<Color> _getGradientColors(int index) {
    final gradients = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)], // 보라-파랑
      [const Color(0xFFf093fb), const Color(0xFFf5576c)], // 핑크-빨강
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)], // 파랑-청록
      [const Color(0xFF43e97b), const Color(0xFF38f9d7)], // 초록-민트
      [const Color(0xFFfa709a), const Color(0xFFfee140)], // 핑크-노랑
      [const Color(0xFFa8edea), const Color(0xFFfed6e3)], // 민트-핑크
    ];
    return gradients[index % gradients.length];
  }

  Future<void> _removeFavorite(String meetingId) async {
    try {
      await Provider.of<FirestoreService>(
        context,
        listen: false,
      ).removeFromFavorites(meetingId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('찜 목록에서 제거되었습니다'),
            backgroundColor: Color(0xFF2E2E2E),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('찜 제거에 실패했습니다'),
            backgroundColor: Color(0xFFF44336),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final weekday = ['일', '월', '화', '수', '목', '금', '토'][date.weekday % 7];
    return '${date.month}.${date.day}($weekday)';
  }
}

class _FavoritesScreenButton extends StatefulWidget {
  final String meetingId;

  const _FavoritesScreenButton({required this.meetingId});

  @override
  State<_FavoritesScreenButton> createState() => _FavoritesScreenButtonState();
}

class _FavoritesScreenButtonState extends State<_FavoritesScreenButton>
    with SingleTickerProviderStateMixin {
  bool _isRemoving = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isRemoving) return;

    // 애니메이션 실행
    await _animationController.forward();
    await _animationController.reverse();

    setState(() {
      _isRemoving = true;
    });

    try {
      final favoritesProvider = Provider.of<FavoritesProvider>(
        context,
        listen: false,
      );
      await favoritesProvider.removeFromFavorites(widget.meetingId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('찜 목록에서 제거되었습니다'),
            backgroundColor: Color(0xFF2E2E2E),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('찜 제거에 실패했습니다'),
            backgroundColor: Color(0xFFF44336),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRemoving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        final isFavorite = favoritesProvider.isFavorite(widget.meetingId);

        return ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTap: _isRemoving ? null : _handleTap,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: _isRemoving
                  ? const SizedBox(
                      width: 8,
                      height: 8,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
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
                            : Colors.white.withOpacity(0.7),
                        size: 12,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
