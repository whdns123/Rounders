import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/review_service.dart';
import '../models/review_model.dart';

class HostReviewListScreen extends StatefulWidget {
  final String hostId;
  final String hostName;

  const HostReviewListScreen({
    super.key,
    required this.hostId,
    required this.hostName,
  });

  @override
  State<HostReviewListScreen> createState() => _HostReviewListScreenState();
}

class _HostReviewListScreenState extends State<HostReviewListScreen> {
  final ReviewService _reviewService = ReviewService();
  bool _isLoading = true;
  List<ReviewModel> _hostReviews = [];
  Map<String, dynamic> _hostStats = {};
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      _currentUserId = authService.currentUser?.uid;

      // 호스트 리뷰와 통계를 동시에 로드
      final reviews = await _reviewService.getReviewsByHost(widget.hostId);
      final stats = await _reviewService.getHostRatingStats(widget.hostId);

      if (mounted) {
        setState(() {
          _hostReviews = reviews;
          _hostStats = stats;
          _isLoading = false;
        });
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
          '${widget.hostName} 호스트 리뷰',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF44336)),
            )
          : Column(
              children: [
                // 호스트 리뷰 통계 헤더
                _buildHostStatsHeader(),
                const SizedBox(height: 16),
                // 리뷰 목록
                Expanded(child: _buildReviewsList()),
              ],
            ),
    );
  }

  Widget _buildHostStatsHeader() {
    final averageRating = _hostStats['averageRating'] as double? ?? 0.0;
    final totalReviews = _hostStats['totalReviews'] as int? ?? 0;
    final ratingCounts = _hostStats['ratingCounts'] as Map<int, int>? ?? {};

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 호스트 이름과 전체 평점
          Row(
            children: [
              // 호스트 아바타
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF44336),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              // 호스트 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.hostName,
                      style: const TextStyle(
                        color: Color(0xFFEAEAEA),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            Icons.star,
                            size: 16,
                            color: index < averageRating.round()
                                ? const Color(0xFFF44336)
                                : const Color(0xFF8C8C8C),
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          '${averageRating.toStringAsFixed(1)} ($totalReviews개 리뷰)',
                          style: const TextStyle(
                            color: Color(0xFFD6D6D6),
                            fontSize: 14,
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

          if (totalReviews > 0) ...[
            const SizedBox(height: 20),
            // 별점 분포
            ...List.generate(5, (index) {
              final rating = 5 - index;
              final count = ratingCounts[rating] ?? 0;
              final percentage = totalReviews > 0 ? count / totalReviews : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text(
                      '$rating★',
                      style: const TextStyle(
                        color: Color(0xFFD6D6D6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFF444444),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: percentage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF44336),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 30,
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Color(0xFFD6D6D6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Pretendard',
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    if (_hostReviews.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: Color(0xFF8C8C8C),
            ),
            SizedBox(height: 16),
            Text(
              '아직 작성된 리뷰가 없어요',
              style: TextStyle(
                color: Color(0xFF8C8C8C),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard',
              ),
            ),
            SizedBox(height: 8),
            Text(
              '첫 번째 리뷰를 남겨보세요!',
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _hostReviews.length,
      itemBuilder: (context, index) {
        final review = _hostReviews[index];
        return _buildReviewCard(review);
      },
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
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
          // 모임 정보와 날짜
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.meetingTitle,
                      style: const TextStyle(
                        color: Color(0xFFEAEAEA),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Pretendard',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review.meetingLocation,
                      style: const TextStyle(
                        color: Color(0xFFD6D6D6),
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
              Text(
                DateFormat('M.d').format(review.createdAt),
                style: const TextStyle(
                  color: Color(0xFF8C8C8C),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 작성자 정보와 별점
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF444444),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFFD6D6D6),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        color: Color(0xFFEAEAEA),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    Text(
                      review.userLevel,
                      style: const TextStyle(
                        color: Color(0xFF8C8C8C),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
              ),
              // 별점
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    Icons.star,
                    size: 14,
                    color: index < review.rating
                        ? const Color(0xFFF44336)
                        : const Color(0xFF444444),
                  );
                }),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 리뷰 내용
          Text(
            review.content,
            style: const TextStyle(
              color: Color(0xFFEAEAEA),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Pretendard',
              height: 1.4,
            ),
          ),

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
                    width: 80,
                    height: 80,
                    margin: EdgeInsets.only(
                      right: index < review.images.length - 1 ? 8 : 0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: const Color(0xFF444444),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        review.images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image,
                            color: Color(0xFF8C8C8C),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 12),

          // 하단 정보 (참여인원, 도움이 돼요)
          Row(
            children: [
              Icon(Icons.people, size: 14, color: const Color(0xFF8C8C8C)),
              const SizedBox(width: 4),
              Text(
                '${review.participantCount}명 참여',
                style: const TextStyle(
                  color: Color(0xFF8C8C8C),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Pretendard',
                ),
              ),
              const Spacer(),
              // 도움이 돼요 버튼
              GestureDetector(
                onTap: () => _toggleHelpfulVote(review),
                child: Row(
                  children: [
                    Icon(
                      review.helpfulVotes.contains(_currentUserId)
                          ? Icons.thumb_up
                          : Icons.thumb_up_outlined,
                      size: 14,
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
