import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/web_launcher_service.dart';
import '../services/favorites_provider.dart';
import '../models/user_model.dart';
import 'booking_history_list_screen.dart';
import 'setting_screen.dart';
import 'profile_edit_screen.dart';
import 'terms_policy_screen.dart';
import 'license_list_screen.dart';
import 'review_list_screen.dart';
import 'notice_list_screen.dart';
import 'favorites_screen.dart';
import 'notification_screen.dart';
import 'host_application_screen.dart';
import 'host_mypage_screen.dart';

class MypageScreen extends StatefulWidget {
  const MypageScreen({super.key});

  @override
  State<MypageScreen> createState() => _MypageScreenState();
}

class _MypageScreenState extends State<MypageScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(
        context,
        listen: false,
      );

      final user = authService.currentUser;
      if (user != null) {
        final userData = await firestoreService.getUserById(user.uid);
        if (mounted) {
          setState(() {
            _currentUser = userData;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('사용자 데이터 로딩 실패: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
        title: const Text(
          '마이페이지',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
        actions: [
          _buildIconButton(Icons.favorite_border, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FavoritesScreen()),
            );
          }),
          _buildIconButton(Icons.notifications_none, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationScreen(),
              ),
            );
          }),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF44336)),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Section
                    _buildProfileSection(),
                    const SizedBox(height: 16),

                    // Level Card
                    _buildLevelCard(),
                    const SizedBox(height: 16),

                    // Action Buttons (리뷰, 예약 내역)
                    _buildActionButtons(context),
                    const SizedBox(height: 36),

                    // Settings Section
                    _buildSettingsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 44,
      height: 44,
      margin: const EdgeInsets.only(right: 4),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildProfileSection() {
    return GestureDetector(
      onTap: () => _navigateToProfileEdit(),
      behavior: HitTestBehavior.translucent,
      child: Container(
        width: double.infinity,
        height: 60,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        decoration: BoxDecoration(color: Colors.transparent),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentUser?.name ?? '사용자',
                  style: const TextStyle(
                    color: Color(0xFFEAEAEA),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Pretendard',
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _getAccountTypeText(),
                  style: const TextStyle(
                    color: Color(0xFFA0A0A0),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToProfileEdit() async {
    if (_currentUser == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditScreen(user: _currentUser!),
      ),
    );

    // 프로필 수정 후 돌아왔을 때 데이터 새로고침
    if (result is UserModel) {
      setState(() {
        _currentUser = result;
      });
    }
  }

  String _getAccountTypeText() {
    if (_currentUser?.email.contains('@gmail.com') == true) {
      return '구글 연동 계정';
    } else if (_currentUser?.email.contains('kakao') == true) {
      return '카카오톡 연동 계정';
    } else {
      return '이메일 계정';
    }
  }

  Widget _buildLevelCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          // Level Illustration
          Container(
            width: 82,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(child: _buildTierIcon()),
          ),
          const SizedBox(width: 14),
          // Level Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getTierLevel(),
                      style: const TextStyle(
                        color: Color(0xFFEAEAEA),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _currentUser?.tierDisplayName ?? '클로버',
                      style: const TextStyle(
                        color: Color(0xFFEAEAEA),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 1. 참가한 게임
                Row(
                  children: [
                    const Text(
                      '참가한 게임:',
                      style: TextStyle(
                        color: Color(0xFFA0A0A0),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    Text(
                      ' ${_currentUser?.meetingsPlayed ?? 0}회',
                      style: const TextStyle(
                        color: Color(0xFFA0A0A0),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // 2. 티어 점수 (총점수와 통합)
                Row(
                  children: [
                    const Text(
                      '티어 점수:',
                      style: TextStyle(
                        color: Color(0xFFA0A0A0),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    Text(
                      ' ${_currentUser?.tierScore ?? 0}점',
                      style: const TextStyle(
                        color: Color(0xFFA0A0A0),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    if ((_currentUser?.pointsToNextTier ?? 0) > 0)
                      Text(
                        ' (다음 티어까지 ${_currentUser?.pointsToNextTier ?? 0}점)',
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                // 3. 평균 등수 (우승 횟수 대신)
                Row(
                  children: [
                    const Text(
                      '평균 등수:',
                      style: TextStyle(
                        color: Color(0xFFA0A0A0),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    Text(
                      (_currentUser?.meetingsPlayed ?? 0) > 0
                          ? ' ${(_currentUser?.averageRank ?? 0).toStringAsFixed(1)}등'
                          : ' 기록 없음',
                      style: const TextStyle(
                        color: Color(0xFFA0A0A0),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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
    );
  }

  String _getTierLevel() {
    final tier = _currentUser?.tier ?? 'clover';
    switch (tier) {
      case 'clover':
        return 'LV.1';
      case 'diamond':
        return 'LV.2';
      case 'heart':
        return 'LV.3';
      case 'spade':
        return 'LV.4';
      default:
        return 'LV.1';
    }
  }

  Widget _buildTierIcon() {
    final tier = _currentUser?.tier ?? 'clover';

    // 한국어 티어명을 영어 파일명으로 매핑
    String getTierFileName(String tier) {
      switch (tier) {
        case '브론즈':
        case 'clover':
          return 'clover';
        case '실버':
        case 'diamond':
          return 'diamond';
        case '골드':
        case 'heart':
          return 'heart';
        case '플래티넘':
        case 'spade':
          return 'spade';
        default:
          return 'clover';
      }
    }

    final fileName = getTierFileName(tier);
    final imagePath = 'assets/images/$fileName.png';

    // 디버깅 로그 제거 (개발 완료)

    // 실제 티어 이미지 사용 (피그마 디자인에 맞춰 크기 조정)
    return Image.asset(
      imagePath,
      width: 58,
      height: 60,
      errorBuilder: (context, error, stackTrace) {
        // 이미지 로드 실패 시 fallback 아이콘 사용
        // 이미지 파일이 없을 때 fallback 아이콘 (피그마 디자인에 맞춰 크기 조정)
        switch (tier) {
          case 'clover':
            return const Icon(Icons.eco, color: Color(0xFF4CAF50), size: 58);
          case 'diamond':
            return const Icon(
              Icons.diamond,
              color: Color(0xFF87CEEB),
              size: 58,
            );
          case 'heart':
            return const Icon(
              Icons.favorite,
              color: Color(0xFFF44336),
              size: 58,
            );
          case 'spade':
            return const Icon(
              Icons.landscape,
              color: Color(0xFF424242),
              size: 58,
            );
          default:
            return const Icon(Icons.eco, color: Color(0xFF4CAF50), size: 58);
        }
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    // 호스트인 경우 3개 버튼, 일반 사용자는 2개 버튼
    final isHost = _currentUser?.isHost == true;

    return Row(
      children: [
        // 리뷰 버튼
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF8C8C8C)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReviewListScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                '리뷰',
                style: TextStyle(
                  color: Color(0xFFF5F5F5),
                  fontSize: 14, // 일관성을 위해 14로 변경
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: isHost ? 8 : 12), // 호스트인 경우 간격 줄임
        // 예약 내역 버튼
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF8C8C8C)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BookingHistoryListScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                '예약 내역',
                style: TextStyle(
                  color: Color(0xFFF5F5F5),
                  fontSize: 14, // 일관성을 위해 14로 변경
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
          ),
        ),
        // 호스트 센터 버튼 (호스트인 경우에만 표시)
        if (isHost) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF8C8C8C)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HostMypageScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  '센터',
                  style: TextStyle(
                    color: Color(0xFFF5F5F5),
                    fontSize: 14, // 16 → 14로 줄임
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Pretendard',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingsGroup(
          title: '고객센터',
          items: [
            _buildSettingItem('공지사항', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NoticeListScreen(),
                ),
              );
            }),
            _buildSettingItem('고객센터 문의', () {
              WebLauncherService.openCustomerService(context);
            }),
          ],
        ),
        const SizedBox(height: 36),
        _buildSettingsGroup(
          title: '제휴 및 호스트',
          items: [
            _buildSettingItem('제휴 및 호스트 지원', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HostApplicationScreen(),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 36),
        _buildSettingsGroup(
          title: '설정',
          items: [
            _buildSettingItem('설정', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingScreen()),
              );
            }),
            _buildSettingItem('약관 및 정책', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsPolicyScreen(),
                ),
              );
            }),
            _buildAppVersionItem(),
            _buildSettingItem('오픈소스 라이선스', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LicenseListScreen(),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsGroup({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFC2C2C2),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(height: 18),
        ...items,
      ],
    );
  }

  Widget _buildSettingItem(String title, VoidCallback onTap) {
    return SizedBox(
      height: 44,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFEAEAEA),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Pretendard',
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAppVersionItem() {
    return const SizedBox(
      height: 20,
      child: Row(
        children: [
          Text(
            '앱 버전 정보',
            style: TextStyle(
              color: Color(0xFFEAEAEA),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'Pretendard',
            ),
          ),
          Spacer(),
          Text(
            '251.03.21',
            style: TextStyle(
              color: Color(0xFFC2C2C2),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }
}
