import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/review_service.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import 'review_write_screen.dart';

class ReviewListScreen extends StatefulWidget {
  final String? gameId;

  const ReviewListScreen({super.key, this.gameId});

  @override
  State<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends State<ReviewListScreen> {
  final ReviewService _reviewService = ReviewService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = true;
  List<ReviewModel> _reviews = [];
  List<ReviewModel> _filteredReviews = [];
  String? _currentUserId;
  bool _photoReviewsOnly = false;
  bool _bestFirst = true; // true: 베스트순, false: 최신순

  // 평점 통계
  double _averageRating = 0.0;
  Map<int, int> _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
  int _totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;

      if (user != null) {
        _currentUserId = user.uid;

        List<ReviewModel> reviews = [];

        if (widget.gameId != null) {
          // 특정 게임의 리뷰를 로드
          reviews = await _reviewService.getReviewsByGame(widget.gameId!);
        } else {
          // gameId가 없으면 사용자의 리뷰를 로드
          reviews = await _reviewService.getReviewsByUser(user.uid);
        }

        if (mounted) {
          setState(() {
            _reviews = reviews;
            _calculateRatingStatistics();
            _applyFilters();
            _isLoading = false;
          });
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

  void _calculateRatingStatistics() {
    if (_reviews.isEmpty) return;

    _totalReviews = _reviews.length;
    _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    double totalRating = 0;
    for (final review in _reviews) {
      totalRating += review.rating;
      _ratingDistribution[review.rating] =
          (_ratingDistribution[review.rating] ?? 0) + 1;
    }

    _averageRating = totalRating / _totalReviews;
  }

  void _applyFilters() {
    _filteredReviews = List.from(_reviews);

    // 사진 리뷰만 필터
    if (_photoReviewsOnly) {
      _filteredReviews = _filteredReviews
          .where((review) => review.images.isNotEmpty)
          .toList();
    }

    // 정렬
    if (_bestFirst) {
      // 베스트순: 도움이 돼요 수 + 평점 높은 순
      _filteredReviews.sort((a, b) {
        final aScore = a.helpfulVotes.length * 10 + a.rating;
        final bScore = b.helpfulVotes.length * 10 + b.rating;
        return bScore.compareTo(aScore);
      });
    } else {
      // 최신순
      _filteredReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  void _togglePhotoFilter() {
    setState(() {
      _photoReviewsOnly = !_photoReviewsOnly;
      _applyFilters();
    });
  }

  void _toggleSortOrder(bool bestFirst) {
    setState(() {
      _bestFirst = bestFirst;
      _applyFilters();
    });
  }

  Future<void> _toggleHelpfulVote(ReviewModel review) async {
    if (_currentUserId == null) return;

    try {
      final isCurrentlyHelpful = review.helpfulVotes.contains(_currentUserId);
      await _reviewService.toggleHelpfulVote(review.id, _currentUserId!);

      // 로컬 상태 업데이트
      setState(() {
        if (isCurrentlyHelpful) {
          review.helpfulVotes.remove(_currentUserId);
        } else {
          review.helpfulVotes.add(_currentUserId!);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF44336)),
            )
          : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF111111),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        '리뷰',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          fontFamily: 'Pretendard',
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody() {
    if (_reviews.isEmpty) {
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

    return Column(
      children: [
        _buildRatingSummary(),
        _buildFilterSection(),
        Expanded(child: _buildReviewsList()),
      ],
    );
  }

  Widget _buildRatingSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          // 평점 및 별점
          Expanded(
            child: Column(
              children: [
                Text(
                  _averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Color(0xFFF5F5F5),
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Pretendard',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Icon(
                      Icons.star,
                      color: const Color(0xFFF44336),
                      size: 20,
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          // 평점 분포
          Expanded(
            flex: 2,
            child: Column(
              children: [
                for (int rating = 5; rating >= 1; rating--)
                  _buildRatingBar(rating),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int rating) {
    final count = _ratingDistribution[rating] ?? 0;
    final percentage = _totalReviews > 0 ? count / _totalReviews : 0.0;
    final isHighest = rating == 5;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Text(
            '${rating}점',
            style: TextStyle(
              color: isHighest
                  ? const Color(0xFFF44336)
                  : const Color(0xFFEAEAEA),
              fontSize: 12,
              fontWeight: isHighest ? FontWeight.w700 : FontWeight.w500,
              fontFamily: 'Pretendard',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFC2C2C2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF44336),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 20,
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Color(0xFFF5F5F5),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'Pretendard',
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 정렬 옵션
          Row(
            children: [
              GestureDetector(
                onTap: () => _toggleSortOrder(true),
                child: Text(
                  '베스트순',
                  style: TextStyle(
                    color: _bestFirst
                        ? const Color(0xFFEAEAEA)
                        : const Color(0xFFA0A0A0),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => _toggleSortOrder(false),
                child: Text(
                  '최신순',
                  style: TextStyle(
                    color: !_bestFirst
                        ? const Color(0xFFEAEAEA)
                        : const Color(0xFFA0A0A0),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // 사진 리뷰 필터
          GestureDetector(
            onTap: _togglePhotoFilter,
            child: Row(
              children: [
                Icon(
                  _photoReviewsOnly
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  size: 20,
                  color: const Color(0xFFA0A0A0),
                ),
                const SizedBox(width: 4),
                const Text(
                  '사진 리뷰만',
                  style: TextStyle(
                    color: Color(0xFFA0A0A0),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    if (_filteredReviews.isEmpty) {
      return const Center(
        child: Text(
          '조건에 맞는 리뷰가 없어요.',
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredReviews.length,
      itemBuilder: (context, index) {
        final review = _filteredReviews[index];
        return _buildReviewCard(review);
      },
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 사용자 정보
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFD6D6D6),
                child: Text(
                  review.userName.isNotEmpty ? review.userName[0] : '?',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
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
                        color: Color(0xFFF5F5F5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const Text(
                      'LV. Clover',
                      style: TextStyle(
                        color: Color(0xFFA0A0A0),
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
          const SizedBox(height: 8),
          // 별점 및 날짜
          Row(
            children: [
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    color: index < review.rating
                        ? const Color(0xFFF44336)
                        : const Color(0xFFC2C2C2),
                    size: 20,
                  );
                }),
              ),
              const Spacer(),
              Text(
                DateFormat('yy.MM.dd').format(review.createdAt),
                style: const TextStyle(
                  color: Color(0xFFA0A0A0),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),
          // 리뷰 이미지들
          if (review.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.images.length > 4 ? 4 : review.images.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: review.images[index].isNotEmpty
                          ? Image.network(
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
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.transparent,
                                  style: BorderStyle.none,
                                ),
                              ),
                              child: Image.asset(
                                'assets/images/test.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
          // 리뷰 내용
          if (review.content.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.content.length > 100
                  ? '${review.content.substring(0, 100)}...'
                  : review.content,
              style: const TextStyle(
                color: Color(0xFFF5F5F5),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Pretendard',
                height: 1.5,
              ),
            ),
            if (review.content.length > 100)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  '더보기',
                  style: TextStyle(
                    color: Color(0xFFA0A0A0),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
          ],
          // 도움이 돼요 버튼
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () => _toggleHelpfulVote(review),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF8C8C8C)),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.thumb_up_outlined,
                        size: 18,
                        color: review.helpfulVotes.contains(_currentUserId)
                            ? const Color(0xFFF44336)
                            : const Color(0xFFF5F5F5),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '도움이 돼요',
                        style: TextStyle(
                          color: Color(0xFFF5F5F5),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'N명에게 도움이 되었습니다.',
                style: const TextStyle(
                  color: Color(0xFFD6D6D6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
