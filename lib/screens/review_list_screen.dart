import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/review_service.dart';
import '../models/review_model.dart';
import 'review_write_screen.dart';

class ReviewListScreen extends StatefulWidget {
  final String? gameId;

  const ReviewListScreen({super.key, this.gameId});

  @override
  State<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends State<ReviewListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReviewService _reviewService = ReviewService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _reviewableMeetings = [];
  List<ReviewModel> _myReviews = [];
  List<ReviewModel> _gameReviews = [];
  String? _currentUserId;

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
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;

      if (user != null) {
        _currentUserId = user.uid;

        if (widget.gameId != null) {
          // 특정 게임의 리뷰를 로드
          final gameReviews = await _reviewService.getReviewsByGame(
            widget.gameId!,
          );
          if (mounted) {
            setState(() {
              _gameReviews = gameReviews;
              _isLoading = false;
            });
          }
        } else {
          // 내 리뷰 관련 데이터를 로드
          final reviewableMeetings = await _reviewService.getReviewableMeetings(
            user.uid,
          );
          final myReviews = await _reviewService.getReviewsByUser(user.uid);

          if (mounted) {
            setState(() {
              _reviewableMeetings = reviewableMeetings;
              _myReviews = myReviews;
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('데이터 로딩 실패: $e')));
      }
    }
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
        title: Text(
          widget.gameId != null ? '리뷰' : '나의 리뷰',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
        bottom: widget.gameId != null
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFF44336),
                indicatorWeight: 4,
                labelColor: const Color(0xFFEAEAEA),
                unselectedLabelColor: const Color(0xFF8C8C8C),
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Pretendard',
                ),
                tabs: const [
                  Tab(text: '리뷰 쓰기'),
                  Tab(text: '작성한 리뷰'),
                ],
              ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF44336)),
            )
          : widget.gameId != null
          ? _buildGameReviewsTab()
          : TabBarView(
              controller: _tabController,
              children: [_buildReviewableTab(), _buildMyReviewsTab()],
            ),
    );
  }

  Widget _buildReviewableTab() {
    if (_reviewableMeetings.isEmpty) {
      return const Center(
        child: Text(
          '작성할 리뷰가 없어요.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reviewableMeetings.length,
      itemBuilder: (context, index) {
        final meeting = _reviewableMeetings[index];
        return _buildReviewableMeetingCard(meeting);
      },
    );
  }

  Widget _buildReviewableMeetingCard(Map<String, dynamic> meeting) {
    final date = meeting['date'] as DateTime;
    final participants = meeting['participants'] as List<String>;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${DateFormat('yyyy.MM.dd').format(date)} 참여',
            style: const TextStyle(
              color: Color(0xFFF5F5F5),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'Pretendard',
            ),
          ),
          const SizedBox(height: 8),
          _buildMeetingCard(meeting),
          const SizedBox(height: 12),
          _buildReviewWriteButton(meeting),
        ],
      ),
    );
  }

  Widget _buildMeetingCard(Map<String, dynamic> meeting) {
    final date = meeting['date'] as DateTime;
    final participants = meeting['participants'] as List<String>;

    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          // 모임 이미지
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFF444444),
              borderRadius: BorderRadius.circular(4),
              image: meeting['imageUrl']?.isNotEmpty == true
                  ? DecorationImage(
                      image: NetworkImage(meeting['imageUrl']),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: meeting['imageUrl']?.isEmpty != false
                ? const Icon(Icons.image, color: Color(0xFF8C8C8C), size: 32)
                : null,
          ),
          const SizedBox(width: 12),
          // 모임 정보
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meeting['title'] ?? '',
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
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFFD6D6D6),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${meeting['location']} • ${DateFormat('M.d(E) HH시 mm분', 'ko').format(date)}',
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.people,
                        color: Color(0xFFD6D6D6),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${participants.length}명 참여',
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
          ),
        ],
      ),
    );
  }

  Widget _buildReviewWriteButton(Map<String, dynamic> meeting) {
    return Container(
      width: double.infinity,
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF8C8C8C)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: ElevatedButton(
        onPressed: () => _navigateToReviewWrite(meeting),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        ),
        child: const Text(
          '리뷰 쓰기',
          style: TextStyle(
            color: Color(0xFFF5F5F5),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }

  Widget _buildGameReviewsTab() {
    if (_gameReviews.isEmpty) {
      return const Center(
        child: Text(
          '작성된 리뷰가 없어요.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _gameReviews.length,
      itemBuilder: (context, index) {
        final review = _gameReviews[index];
        return _buildGameReviewCard(review);
      },
    );
  }

  Widget _buildMyReviewsTab() {
    if (_myReviews.isEmpty) {
      return const Center(
        child: Text(
          '작성한 리뷰가 없어요.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myReviews.length,
      itemBuilder: (context, index) {
        final review = _myReviews[index];
        return _buildMyReviewCard(review);
      },
    );
  }

  Widget _buildGameReviewCard(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 사용자 정보 및 별점
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF444444),
                child: Text(
                  review.userName.isNotEmpty ? review.userName[0] : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        color: Color(0xFFEAEAEA),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: const Color(0xFFF44336),
                            size: 14,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('yyyy.MM.dd').format(review.createdAt),
                          style: const TextStyle(
                            color: Color(0xFF8C8C8C),
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
          // 리뷰 내용
          if (review.content.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.content,
              style: const TextStyle(
                color: Color(0xFFD6D6D6),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
          // 리뷰 이미지들
          if (review.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.images.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.only(
                      right: index < review.images.length - 1 ? 8 : 0,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        review.images[index],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: const Color(0xFF444444),
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Color(0xFF8C8C8C),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          // 도움이 돼요 버튼
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () => _toggleHelpfulVote(review),
                child: Row(
                  children: [
                    Icon(
                      Icons.thumb_up_outlined,
                      size: 16,
                      color: review.helpfulVotes.contains(_currentUserId)
                          ? const Color(0xFFF44336)
                          : const Color(0xFF8C8C8C),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '도움이 돼요 ${review.helpfulVotes.length}',
                      style: TextStyle(
                        color: review.helpfulVotes.contains(_currentUserId)
                            ? const Color(0xFFF44336)
                            : const Color(0xFF8C8C8C),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Pretendard',
                      ),
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

  Widget _buildMyReviewCard(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMeetingCardFromReview(review),
          const SizedBox(height: 8),
          Text(
            '작성일 ${DateFormat('yyyy.MM.dd').format(review.createdAt)}',
            style: const TextStyle(
              color: Color(0xFF8C8C8C),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingCardFromReview(ReviewModel review) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          // 모임 이미지
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFF444444),
              borderRadius: BorderRadius.circular(4),
              image: review.meetingImage.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(review.meetingImage),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: review.meetingImage.isEmpty
                ? const Icon(Icons.image, color: Color(0xFF8C8C8C), size: 32)
                : null,
          ),
          const SizedBox(width: 12),
          // 모임 정보
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.meetingTitle,
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
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFFD6D6D6),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${review.meetingLocation} • ${DateFormat('M.d(E) HH시 mm분', 'ko').format(review.meetingDate)}',
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.people,
                        color: Color(0xFFD6D6D6),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${review.participantCount}명 참여',
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
          ),
        ],
      ),
    );
  }

  void _navigateToReviewWrite(Map<String, dynamic> meeting) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewWriteScreen(
          meetingId: meeting['id'],
          meetingTitle: meeting['title'],
          meetingLocation: meeting['location'],
          meetingDate: meeting['date'],
          meetingImage: meeting['imageUrl'] ?? '',
          participantCount: (meeting['participants'] as List).length,
        ),
      ),
    ).then((_) {
      // 리뷰 작성 후 돌아오면 데이터 새로고침
      _loadData();
    });
  }

  Future<void> _toggleHelpfulVote(ReviewModel review) async {
    if (_currentUserId == null) return;

    try {
      await _reviewService.toggleHelpfulVote(review.id, _currentUserId!);
      // 데이터 새로고침
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('투표 처리 실패: $e')));
    }
  }
}
