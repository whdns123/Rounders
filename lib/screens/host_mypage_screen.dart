import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/web_launcher_service.dart';
import '../models/user_model.dart';
import 'booking_history_list_screen.dart';
import 'host_meeting_management_screen.dart';
import 'review_list_screen.dart';
import 'notice_list_screen.dart';
import 'setting_screen.dart';
import 'terms_policy_screen.dart';
import 'license_list_screen.dart';

class HostMypageScreen extends StatefulWidget {
  const HostMypageScreen({super.key});

  @override
  State<HostMypageScreen> createState() => _HostMypageScreenState();
}

class _HostMypageScreenState extends State<HostMypageScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;
  int _hostedMeetingsCount = 0;

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
            _hostedMeetingsCount = userData?.hostedMeetings.length ?? 0;
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

                    // Booking History & Host Center Buttons
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
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF44336),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'HOST',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
              ],
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
    );
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
            child: Center(child: _buildHostIcon()),
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
                      _getHostLevel(),
                      style: const TextStyle(
                        color: Color(0xFFEAEAEA),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Host',
                      style: TextStyle(
                        color: Color(0xFFF44336),
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
                      '주최한 모임:',
                      style: TextStyle(
                        color: Color(0xFFA0A0A0),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    Text(
                      ' $_hostedMeetingsCount회',
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
                      '호스트 기간:',
                      style: TextStyle(
                        color: Color(0xFFA0A0A0),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    Text(
                      ' ${_getHostDuration()}',
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

  String _getHostLevel() {
    if (_hostedMeetingsCount >= 50) {
      return 'LV.5';
    } else if (_hostedMeetingsCount >= 20) {
      return 'LV.4';
    } else if (_hostedMeetingsCount >= 10) {
      return 'LV.3';
    } else if (_hostedMeetingsCount >= 5) {
      return 'LV.2';
    } else {
      return 'LV.1';
    }
  }

  String _getHostDuration() {
    if (_currentUser?.hostSince != null) {
      final duration = DateTime.now().difference(_currentUser!.hostSince!);
      final days = duration.inDays;
      if (days >= 365) {
        return '${(days / 365).floor()}년';
      } else if (days >= 30) {
        return '${(days / 30).floor()}개월';
      } else {
        return '$days일';
      }
    }
    return '신규';
  }

  Widget _buildHostIcon() {
    return const Icon(Icons.stars, color: Color(0xFFF44336), size: 40);
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // 리뷰 Button
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
        const SizedBox(width: 8),
        // 예약 내역 Button
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
        const SizedBox(width: 8),
        // 호스트 센터 Button
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
                    builder: (context) => const HostMeetingManagementScreen(),
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
                '호스트 센터',
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
