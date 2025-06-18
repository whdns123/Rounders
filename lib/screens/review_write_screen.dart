import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/review_service.dart';
import '../services/firestore_service.dart';
import '../models/review_model.dart';

class ReviewWriteScreen extends StatefulWidget {
  final String meetingId;
  final String meetingTitle;
  final String meetingLocation;
  final DateTime meetingDate;
  final String meetingImage;
  final int participantCount;

  const ReviewWriteScreen({
    super.key,
    required this.meetingId,
    required this.meetingTitle,
    required this.meetingLocation,
    required this.meetingDate,
    required this.meetingImage,
    required this.participantCount,
  });

  @override
  State<ReviewWriteScreen> createState() => _ReviewWriteScreenState();
}

class _ReviewWriteScreenState extends State<ReviewWriteScreen> {
  final TextEditingController _reviewController = TextEditingController();
  final ReviewService _reviewService = ReviewService();
  final int _maxLength = 500;
  final int _minLength = 20;

  int _rating = 5;
  final List<String> _imageUrls = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _reviewController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _reviewController.removeListener(_onTextChanged);
    _reviewController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _errorMessage = null;
    });
  }

  bool get _isValidReview {
    final text = _reviewController.text.trim();
    return text.length >= _minLength && text.length <= _maxLength;
  }

  bool get _canSubmit {
    return _isValidReview && !_isLoading;
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
          onPressed: () => _showExitDialog(),
        ),
        title: const Text(
          '리뷰 쓰기',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => _showExitDialog(),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageUploadSection(),
                  const SizedBox(height: 36),
                  _buildRatingSection(),
                  const SizedBox(height: 36),
                  _buildReviewSection(),
                  const SizedBox(height: 100), // 버튼 공간 확보
                ],
              ),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '사진을 업로드해주세요. (선택)',
          style: TextStyle(
            color: Color(0xFFF5F5F5),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '모임을 즐기면서 찍은 사진이나 장소에 대한 사진 등을 자유롭게 업로드해주세요. 단, 모임과 관련 없거나 부적합한 사진을 리뷰에 등록하시는 경우 사전경고 없이 사진이 삭제될 수 있습니다.',
          style: TextStyle(
            color: Color(0xFFA0A0A0),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'Pretendard',
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        _buildImageGrid(),
      ],
    );
  }

  Widget _buildImageGrid() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (_imageUrls.length < 5) _buildAddImageButton(),
          ...List.generate(
            _imageUrls.length,
            (index) => _buildImageItem(index),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF8C8C8C)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: _addImage,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Color(0xFFD6D6D6), size: 24),
            SizedBox(height: 4),
            Text(
              '*최대 5장',
              style: TextStyle(
                color: Color(0xFFD6D6D6),
                fontSize: 12,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem(int index) {
    return Container(
      width: 91,
      height: 92,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          Container(
            width: 80,
            height: 80,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              image: DecorationImage(
                image: NetworkImage(_imageUrls[index]),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF8C8C8C),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '별점을 매겨주세요. (필수)',
          style: TextStyle(
            color: Color(0xFFF5F5F5),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () => setState(() => _rating = index + 1),
              child: Icon(
                Icons.star,
                size: 32,
                color: index < _rating
                    ? const Color(0xFFF44336)
                    : const Color(0xFFC2C2C2),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildReviewSection() {
    final currentLength = _reviewController.text.length;
    final isValid = currentLength >= _minLength;
    final showError = currentLength > 0 && !isValid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '리뷰를 작성해주세요. (필수)',
              style: TextStyle(
                color: Color(0xFFF5F5F5),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Pretendard',
              ),
            ),
            Text(
              '$currentLength자 | 최소 $_minLength자',
              style: const TextStyle(
                color: Color(0xFFA0A0A0),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
        if (showError) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.error, color: Color(0xFFFF002F), size: 16),
              const SizedBox(width: 4),
              Text(
                '최소 $_minLength자를 채워주세요.',
                style: const TextStyle(
                  color: Color(0xFFFF002F),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2E2E2E),
            borderRadius: BorderRadius.circular(6),
          ),
          child: TextField(
            controller: _reviewController,
            maxLines: null,
            maxLength: _maxLength,
            style: const TextStyle(
              color: Color(0xFFEAEAEA),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Pretendard',
              height: 1.5,
            ),
            decoration: const InputDecoration(
              hintText:
                  '모임을 하면서 느꼈던 감정을 솔직하게 알려주세요.\n\n게임 난이도는 어땠나요?\n몰입감/ 재미가 있었나요?\n호스트는 어땠나요?\n장소에 대한 만족도는 어땠나요?',
              hintStyle: TextStyle(
                color: Color(0xFFA0A0A0),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'Pretendard',
                height: 1.5,
              ),
              border: InputBorder.none,
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: const Color(0xFF111111),
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: _canSubmit
                ? const Color(0xFFF44336)
                : const Color(0xFFC2C2C2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ElevatedButton(
            onPressed: _canSubmit ? _submitReview : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    '저장하기',
                    style: TextStyle(
                      color: _canSubmit
                          ? const Color(0xFFF5F5F5)
                          : const Color(0xFF8C8C8C),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Pretendard',
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _addImage() {
    // 이미지 선택 기능 - 현재는 더미 이미지 추가
    if (_imageUrls.length < 5) {
      setState(() {
        _imageUrls.add('https://via.placeholder.com/150');
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  void _showExitDialog() {
    final hasContent =
        _reviewController.text.trim().isNotEmpty || _imageUrls.isNotEmpty;

    if (!hasContent) {
      Navigator.of(context).pop();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF2E2E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '리뷰 작성을 그만하시겠어요?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                '작성 중인 내용은 저장되지 않아요.\n정말 나가시겠어요?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pretendard',
                  height: 1.43,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF8C8C8C)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          '나가기',
                          style: TextStyle(
                            color: Color(0xFFF5F5F5),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF44336),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          '계속 작성하기',
                          style: TextStyle(
                            color: Color(0xFFF5F5F5),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).then((shouldExit) {
      if (shouldExit == true) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _submitReview() async {
    if (!_canSubmit) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(
        context,
        listen: false,
      );
      final user = authService.currentUser;

      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 사용자 정보 가져오기
      final userData = await firestoreService.getUserById(user.uid);

      // 리뷰 생성
      final review = ReviewModel(
        id: '',
        userId: user.uid,
        userName: userData?.name ?? '사용자',
        userLevel: userData?.tier ?? '브론즈',
        meetingId: widget.meetingId,
        meetingTitle: widget.meetingTitle,
        meetingLocation: widget.meetingLocation,
        meetingDate: widget.meetingDate,
        meetingImage: widget.meetingImage,
        rating: _rating,
        content: _reviewController.text.trim(),
        images: _imageUrls,
        createdAt: DateTime.now(),
        helpfulVotes: [],
        participantCount: widget.participantCount,
      );

      await _reviewService.createReview(review);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('리뷰가 작성되었습니다.'),
            backgroundColor: Color(0xFFF44336),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('리뷰 작성 실패: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
