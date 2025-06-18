import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/web_launcher_service.dart';
import '../models/user_model.dart';
import 'booking_history_list_screen.dart';
import 'review_list_screen.dart';
import 'notice_list_screen.dart';
import 'setting_screen.dart';
import 'terms_policy_screen.dart';
import 'license_list_screen.dart';
import 'profile_edit_screen.dart';
import 'refund_list_screen.dart';

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
          _buildIconButton(Icons.favorite_border),
          _buildIconButton(Icons.notifications_none),
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

  Widget _buildIconButton(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      margin: const EdgeInsets.only(right: 4),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  Widget _buildProfileSection() {
    return GestureDetector(
      onTap: () => _navigateToProfileEdit(),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      _currentUser?.tier ?? '브론즈',
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
                Row(
                  children: [
                    const Text(
                      '총 점수:',
                      style: TextStyle(
                        color: Color(0xFFA0A0A0),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    Text(
                      ' ${_currentUser?.totalScore ?? 0}점',
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
                Row(
                  children: [
                    const Text(
                      '우승 횟수:',
                      style: TextStyle(
                        color: Color(0xFFA0A0A0),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    Text(
                      ' ${_currentUser?.wins ?? 0}회',
                      style: const TextStyle(
                        color: Color(0xFFA0A0A0),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const Text(
                      ' (승률: ',
                      style: TextStyle(
                        color: Color(0xFFA0A0A0),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    Text(
                      '${(_currentUser?.winRate ?? 0).toStringAsFixed(1)}%)',
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
                Row(
                  children: [
                    const Text(
                      '선호 지역:',
                      style: TextStyle(
                        color: Color(0xFFA0A0A0),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    Text(
                      ' ${_currentUser?.location ?? '미설정'}',
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
    final tier = _currentUser?.tier ?? '브론즈';
    switch (tier) {
      case '브론즈':
        return 'LV.1';
      case '실버':
        return 'LV.2';
      case '골드':
        return 'LV.3';
      case '플래티넘':
        return 'LV.4';
      case '다이아몬드':
        return 'LV.5';
      default:
        return 'LV.1';
    }
  }

  Widget _buildTierIcon() {
    final tier = _currentUser?.tier ?? '브론즈';
    switch (tier) {
      case '브론즈':
        return const Icon(
          Icons.military_tech,
          color: Color(0xFFCD7F32),
          size: 40,
        );
      case '실버':
        return const Icon(
          Icons.workspace_premium,
          color: Color(0xFFC0C0C0),
          size: 40,
        );
      case '골드':
        return const Icon(
          Icons.emoji_events,
          color: Color(0xFFFFD700),
          size: 40,
        );
      case '플래티넘':
        return const Icon(Icons.diamond, color: Color(0xFFE5E4E2), size: 40);
      case '다이아몬드':
        return const Icon(Icons.diamond, color: Color(0xFF87CEEB), size: 40);
      default:
        return const Icon(
          Icons.local_florist,
          color: Color(0xFF2E2E2E),
          size: 40,
        );
    }
  }

  Widget _buildActionButtons(BuildContext context) {
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
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
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
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingsGroup(
          title: '이용 내역',
          items: [
            _buildSettingItem('환불 내역', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RefundListScreen(),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 36),
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
              WebLauncherService.showDevelopmentDialog(context, '고객센터 문의');
              // 실제 배포 시 아래 코드로 변경
              // WebLauncherService.openCustomerService(context);
            }),
          ],
        ),
        const SizedBox(height: 36),
        _buildSettingsGroup(
          title: '제휴 및 호스트',
          items: [
            _buildSettingItem('제휴 및 호스트 지원', () {
              WebLauncherService.showDevelopmentDialog(context, '제휴 및 호스트 지원');
              // 실제 배포 시 아래 코드로 변경
              // WebLauncherService.openPartnership(context);
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
