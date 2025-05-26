import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/meeting.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'applicants_screen.dart';
import 'meeting_result_screen.dart';
import 'payment_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class MeetingDetailScreen extends StatefulWidget {
  final String meetingId;

  const MeetingDetailScreen({
    Key? key,
    required this.meetingId,
  }) : super(key: key);

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen> {
  bool _isLoading = true;
  final bool _isJoining = false;
  bool _isLeaving = false;
  late FirestoreService _firestoreService;
  late AuthService _authService;
  late String? _currentUserId;
  Meeting? _meeting;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _firestoreService = Provider.of<FirestoreService>(context, listen: false);
      _authService = Provider.of<AuthService>(context, listen: false);
      _currentUserId = _authService.currentUser?.uid;

      // 모임 정보 가져오기
      _fetchMeetingDetails();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 모임 정보 가져오기
  Future<void> _fetchMeetingDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Firebase에서 실제 모임 데이터 가져오기
      final meetingData =
          await _firestoreService.getMeetingById(widget.meetingId);
      setState(() {
        _meeting = meetingData;
      });
    } catch (e) {
      _showMessage('모임 정보를 불러오는데 실패했습니다: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 사용자가 참가 중인지 확인
  bool get _isParticipating =>
      _currentUserId != null &&
      _meeting != null &&
      _meeting!.participants.contains(_currentUserId);

  // 사용자가 호스트인지 확인
  bool get _isHost =>
      _currentUserId != null &&
      _meeting != null &&
      _meeting!.hostId == _currentUserId;

  // 모임이 완료되었는지 확인
  bool get _isCompleted => _meeting != null && _meeting!.isCompleted;

  // 모임 참가 처리
  Future<void> _joinMeeting() async {
    if (_meeting == null) return;

    if (_currentUserId == null) {
      _showMessage('로그인이 필요합니다.');
      return;
    }

    if (_meeting!.currentParticipants >= _meeting!.maxParticipants) {
      _showMessage('모임 정원이 가득 찼습니다.');
      return;
    }

    // 사용자 정보 가져오기
    try {
      final userModel = await _firestoreService.getUserById(_currentUserId!);

      if (userModel == null) {
        _showMessage('사용자 정보를 불러올 수 없습니다.');
        return;
      }

      // 결제 페이지로 이동
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            meeting: _meeting!,
            user: userModel,
          ),
        ),
      );

      // 결제 성공 시 화면 새로고침
      if (result == true) {
        await _fetchMeetingDetails();
      }
    } catch (e) {
      _showMessage('모임 신청 처리 중 오류가 발생했습니다: $e');
    }
  }

  // 모임 취소 처리
  Future<void> _leaveMeeting() async {
    if (_meeting == null) return;

    if (_currentUserId == null) {
      _showMessage('로그인이 필요합니다.');
      return;
    }

    if (_isHost) {
      _showMessage('호스트는 모임을 취소할 수 없습니다. 관리자에게 문의하세요.');
      return;
    }

    setState(() {
      _isLeaving = true;
    });

    try {
      await _firestoreService.leaveMeeting(_meeting!.id);
      setState(() {
        // 참가자 정보 업데이트
        _meeting = _meeting!.removeParticipant(_currentUserId!);
      });
      _showMessage('모임 참가를 취소했습니다.');
    } catch (e) {
      _showMessage('모임 취소 실패: $e');
    } finally {
      setState(() {
        _isLeaving = false;
      });
    }
  }

  // 메시지 표시 헬퍼 함수
  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // 모임 삭제 확인 다이얼로그
  Future<void> _showDeleteConfirmDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모임 삭제'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('정말로 이 모임을 삭제하시겠습니까?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '주의사항',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 삭제된 모임은 복구할 수 없습니다.\n• 관련된 모든 데이터가 삭제됩니다.\n• 참가자가 있는 모임은 삭제할 수 없습니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteMeeting();
    }
  }

  // 모임 삭제 처리
  Future<void> _deleteMeeting() async {
    if (_meeting == null) return;

    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await _firestoreService.deleteMeeting(_meeting!.id);

      // 로딩 다이얼로그 닫기
      if (mounted) Navigator.of(context).pop();

      _showMessage('모임이 성공적으로 삭제되었습니다.');

      // 이전 화면으로 돌아가기
      if (mounted) {
        Navigator.of(context).pop(true); // 삭제 성공을 알리고 돌아가기
      }
    } catch (e) {
      // 로딩 다이얼로그 닫기
      if (mounted) Navigator.of(context).pop();

      _showMessage('모임 삭제에 실패했습니다: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A55A2),
        title: const Text('모임 상세 정보', style: TextStyle(color: Colors.white)),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _meeting == null
              ? const Center(child: Text('모임 정보를 불러올 수 없습니다.'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 이미지 슬라이더
                      _buildImageSlider(),

                      // 모임 정보
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 모임 제목
                            Text(
                              _meeting!.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // 모임 호스트
                            Row(
                              children: [
                                const Icon(Icons.person,
                                    color: Colors.grey, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '주최자: ${_meeting!.hostName}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // 모임 시간
                            Row(
                              children: [
                                const Icon(Icons.access_time,
                                    color: Colors.grey, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '일시: ${DateFormat('yyyy년 M월 d일 (E) a h:mm', 'ko_KR').format(_meeting!.scheduledDate)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // 모임 장소
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.grey, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '장소: ${_meeting!.location}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // 모임 참가비
                            Row(
                              children: [
                                const Icon(Icons.attach_money,
                                    color: Colors.grey, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '참가비: ${NumberFormat('#,###').format(_meeting!.price)}원',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // 모임 인원
                            Row(
                              children: [
                                const Icon(Icons.people,
                                    color: Colors.grey, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '인원: ${_meeting!.currentParticipants}/${_meeting!.maxParticipants}명',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // 필요 레벨
                            Row(
                              children: [
                                const Icon(Icons.grade,
                                    color: Colors.grey, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '필요 레벨: ${_meeting!.requiredLevel}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // 모임 설명
                            const Text(
                              '모임 설명',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _meeting!.description,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // 호스트 전용 정보 섹션
                            if (_isHost) _buildHostInfoSection(),

                            // 호스트 버튼 위젯
                            _buildHostButtons(context),

                            // 참가자 버튼 위젯
                            if (!_isHost) _buildParticipantButtons(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // 호스트 버튼 위젯
  Widget _buildHostButtons(BuildContext context) {
    final userId = _authService.currentUser?.uid;
    final bool isHost = userId == _meeting?.hostId;
    final bool isPastMeeting =
        _meeting?.scheduledDate.isBefore(DateTime.now()) ?? false;
    final bool isCompletedMeeting = _meeting?.isCompleted ?? false;
    final bool canDeleteMeeting = !isPastMeeting &&
        !isCompletedMeeting &&
        (_meeting?.currentParticipants ?? 0) <= 1; // 호스트만 있는 경우

    if (!isHost) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 신청자 관리 버튼
        ElevatedButton.icon(
          icon: const Icon(Icons.people, color: Colors.white),
          label: const Text('신청자 관리', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A55A2),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ApplicantsScreen(meeting: _meeting!),
              ),
            );
          },
        ),

        // 모임 삭제 버튼 (조건부 표시)
        if (canDeleteMeeting) ...[
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            label: const Text('모임 삭제', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => _showDeleteConfirmDialog(),
          ),
        ],

        // 결과 입력 버튼 (날짜가 지난 모임이고 아직 완료되지 않은 경우)
        if (isPastMeeting && !isCompletedMeeting) ...[
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.emoji_events, color: Colors.white),
            label:
                const Text('모임 결과 입력', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MeetingResultScreen(meeting: _meeting!),
                ),
              );

              // 결과 입력 후 화면 새로고침
              if (result == true) {
                _fetchMeetingDetails();
              }
            },
          ),
        ],

        // 모임 완료 표시 (이미 완료된 경우)
        if (isCompletedMeeting) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle,
                    color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  '모임 완료',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // 참가자 버튼 위젯
  Widget _buildParticipantButtons(BuildContext context) {
    final userId = _authService.currentUser?.uid;
    final isParticipant = _meeting?.participants.contains(userId) ?? false;
    final isPastMeeting =
        _meeting?.scheduledDate.isBefore(DateTime.now()) ?? false;
    final isCompletedMeeting = _meeting?.isCompleted ?? false;

    if (_meeting?.hostId == userId) {
      return const SizedBox.shrink(); // 호스트는 별도 버튼 표시
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isParticipant) ...[
          // 참가 취소 버튼 (모임 날짜 전이고 완료되지 않은 경우만)
          if (!isPastMeeting && !isCompletedMeeting)
            ElevatedButton.icon(
              icon: const Icon(Icons.exit_to_app, color: Colors.white),
              label: const Text('참가 취소', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _isLeaving
                  ? null
                  : () async {
                      await _leaveMeeting();
                    },
            ),

          // 모임 완료 표시 (이미 완료된 경우)
          if (isCompletedMeeting) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle,
                      color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '모임 완료',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ] else ...[
          // 모임 신청 버튼 (모임 날짜 전이고 완료되지 않은 경우만)
          if (!isPastMeeting && !isCompletedMeeting)
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle, color: Colors.white),
              label: const Text('모임 신청', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A55A2),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _isJoining
                  ? null
                  : () async {
                      await _joinMeeting();
                    },
            ),

          // 모임 종료 표시 (날짜가 지난 경우)
          if (isPastMeeting || isCompletedMeeting)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, color: Colors.grey.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '모임 종료',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildImageSlider() {
    return SizedBox(
      height: 250,
      child: _meeting!.imageUrls.isEmpty
          ? Container(
              color: Colors.grey[300],
              child: const Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 50,
                  color: Colors.grey,
                ),
              ),
            )
          : Stack(
              alignment: Alignment.bottomCenter,
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: _meeting!.imageUrls.length,
                  itemBuilder: (context, index) {
                    final imageUrl = _meeting!.imageUrls[index];
                    return imageUrl.startsWith('assets/')
                        ? Image.asset(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                  ),
                                ),
                              );
                            },
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                  ),
                                ),
                              );
                            },
                          );
                  },
                ),
                // 페이지 인디케이터
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: _meeting!.imageUrls.length,
                    effect: const WormEffect(
                      dotWidth: 10,
                      dotHeight: 10,
                      activeDotColor: Color(0xFF4A55A2),
                      dotColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHostInfoSection() {
    if (_meeting == null) return const SizedBox.shrink();

    final bool isPastMeeting = _meeting!.scheduledDate.isBefore(DateTime.now());
    final bool isCompletedMeeting = _meeting!.isCompleted;
    final bool canDeleteMeeting = !isPastMeeting &&
        !isCompletedMeeting &&
        _meeting!.currentParticipants <= 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.admin_panel_settings,
                  color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                '호스트 정보',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 참가자 현황
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '현재 참가자',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_meeting!.currentParticipants}명',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '최대 인원',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_meeting!.maxParticipants}명',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '예상 수익',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${NumberFormat('#,###').format(_meeting!.currentParticipants * _meeting!.price)}원',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 모집률 진행 바
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '모집률',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${((_meeting!.currentParticipants / _meeting!.maxParticipants) * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value:
                    _meeting!.currentParticipants / _meeting!.maxParticipants,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                minHeight: 8,
              ),
            ],
          ),

          // 모임 상태 표시
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                canDeleteMeeting ? Icons.delete_outline : Icons.info_outline,
                size: 16,
                color: canDeleteMeeting
                    ? Colors.orange.shade600
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  canDeleteMeeting
                      ? '참가자가 없어 모임을 삭제할 수 있습니다.'
                      : _meeting!.currentParticipants > 1
                          ? '참가자가 있어 모임을 삭제할 수 없습니다.'
                          : isPastMeeting
                              ? '이미 시작된 모임은 삭제할 수 없습니다.'
                              : '모임 관리 중',
                  style: TextStyle(
                    fontSize: 12,
                    color: canDeleteMeeting
                        ? Colors.orange.shade600
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
