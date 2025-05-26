import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'payment_screen.dart';

class MeetingDetailWebScreen extends StatefulWidget {
  final String meetingId;

  const MeetingDetailWebScreen({
    Key? key,
    required this.meetingId,
  }) : super(key: key);

  @override
  State<MeetingDetailWebScreen> createState() => _MeetingDetailWebScreenState();
}

class _MeetingDetailWebScreenState extends State<MeetingDetailWebScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _isParticipating = false;
  bool _isRegistering = false;
  late FirestoreService _firestoreService;
  late AuthService _authService;
  String? _currentUserId;
  UserModel? _userInfo;

  @override
  void initState() {
    super.initState();

    // 웹뷰 컨트롤러 초기화
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('http://lapidarist.co.kr/kaist'));

    // 서비스 초기화 및 참가 상태 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _firestoreService = Provider.of<FirestoreService>(context, listen: false);
      _authService = Provider.of<AuthService>(context, listen: false);
      _currentUserId = _authService.currentUser?.uid;

      // 참가 여부 확인
      _checkParticipationStatus();

      // 사용자 정보 가져오기
      if (_currentUserId != null) {
        _loadUserInfo();
      }
    });
  }

  // 참가 상태 확인
  Future<void> _checkParticipationStatus() async {
    if (_currentUserId == null) return;

    try {
      final meeting = await _firestoreService.getMeetingById(widget.meetingId);
      setState(() {
        _isParticipating = meeting.participants.contains(_currentUserId);
      });
    } catch (e) {
      _showMessage('모임 정보를 불러오는데 실패했습니다.');
    }
  }

  // 사용자 정보 가져오기
  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await _firestoreService.getUserById(_currentUserId!);
      setState(() {
        _userInfo = userInfo;
      });
    } catch (e) {
      _showMessage('사용자 정보를 불러오는데 실패했습니다.');
    }
  }

  // 신청하기 버튼 처리
  Future<void> _handleRegister() async {
    if (_currentUserId == null) {
      // 로그인되지 않은 경우 로그인 화면으로 이동
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(
            onLoginSuccess: () {
              // 로그인 성공 시 사용자 정보 로드
              setState(() {
                _currentUserId = _authService.currentUser?.uid;
              });
              if (_currentUserId != null) {
                _loadUserInfo();
                _checkParticipationStatus();
              }
            },
          ),
        ),
      );
    } else {
      // 사용자 정보가 없는 경우 다시 로드
      if (_userInfo == null) {
        await _loadUserInfo();
      }

      // 사용자 정보가 여전히 없다면 오류 메시지 표시
      if (_userInfo == null) {
        _showMessage('사용자 정보를 불러올 수 없습니다.');
        return;
      }

      // 모임 정보 가져오기
      try {
        final meeting =
            await _firestoreService.getMeetingById(widget.meetingId);

        // 예약 화면으로 이동
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              meeting: meeting,
              user: _userInfo!,
            ),
          ),
        );

        // 예약 성공 시 참가 상태 업데이트
        if (result == true) {
          setState(() {
            _isParticipating = true;
          });
        }
      } catch (e) {
        _showMessage('모임 정보를 불러오는데 실패했습니다.');
      }
    }
  }

  // 모임 참가 처리
  Future<void> _joinMeeting() async {
    if (_currentUserId == null) {
      _showMessage('로그인이 필요합니다.');
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      await _firestoreService.joinMeeting(widget.meetingId);
      setState(() {
        _isParticipating = true;
      });
      _showMessage('모임 참가 신청이 완료되었습니다.');
    } catch (e) {
      _showMessage('모임 참가 신청에 실패했습니다: $e');
    } finally {
      setState(() {
        _isRegistering = false;
      });
    }
  }

  // 모임 취소 처리
  Future<void> _leaveMeeting() async {
    if (_currentUserId == null) {
      _showMessage('로그인이 필요합니다.');
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      await _firestoreService.leaveMeeting(widget.meetingId);
      setState(() {
        _isParticipating = false;
      });
      _showMessage('모임 참가가 취소되었습니다.');
    } catch (e) {
      _showMessage('모임 취소에 실패했습니다: $e');
    } finally {
      setState(() {
        _isRegistering = false;
      });
    }
  }

  // 메시지 표시
  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A55A2),
        title: const Text('모임 상세보기', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 웹뷰 영역
          Positioned.fill(
            bottom: 70, // 버튼 높이만큼 공간 확보
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          // 하단 고정 버튼
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isRegistering
                    ? null
                    : (_isParticipating ? _leaveMeeting : _handleRegister),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isParticipating ? Colors.red : const Color(0xFF4A55A2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isRegistering
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isParticipating ? '참가 취소하기' : '신청하기',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
