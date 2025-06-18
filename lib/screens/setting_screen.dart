import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'delete_account_screen.dart';
import 'terms_policy_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _deviceNotificationEnabled = true;
  bool _marketingAgreementEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(
        context,
        listen: false,
      );

      final user = authService.currentUser;
      if (user != null) {
        final userData = await firestoreService.getUserById(user.uid);
        if (userData != null && mounted) {
          setState(() {
            // 사용자 설정 로드 (예시)
            _deviceNotificationEnabled = userData.email.isNotEmpty;
            _marketingAgreementEnabled = false; // 기본값
          });
        }
      }
    } catch (e) {
      print('사용자 설정 로딩 실패: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveUserSettings() async {
    try {
      // 여기에 사용자 설정 저장 로직 구현
      // Firestore에 설정 저장 등
      print(
        '설정 저장: 기기 알림 $_deviceNotificationEnabled, 마케팅 동의 $_marketingAgreementEnabled',
      );
    } catch (e) {
      print('설정 저장 실패: $e');
    }
  }

  Future<void> _logout() async {
    final confirmed = await _showLogoutDialog();
    if (confirmed == true) {
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.signOut();

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        print('로그아웃 실패: $e');
        if (mounted) {
          _showErrorDialog('로그아웃 중 오류가 발생했습니다.');
        }
      }
    }
  }

  Future<void> _deleteAccount() async {
    final result = await _showDeleteAccountDialog();
    if (result != null && result['password']?.isNotEmpty == true) {
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.deleteAccount(result['password']!);

        // 탈퇴 사유를 로그로 기록 (실제 서비스에서는 분석용 데이터로 저장)
        print('탈퇴 사유: ${result['reason']}');

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        print('계정 삭제 실패: $e');
        if (mounted) {
          _showErrorDialog('계정 삭제 중 오류가 발생했습니다.\n비밀번호를 확인해주세요.');
        }
      }
    }
  }

  Future<bool?> _showLogoutDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E2E2E),
          title: const Text(
            '로그아웃',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            '정말 로그아웃하시겠습니까?',
            style: TextStyle(
              color: Color(0xFFEAEAEA),
              fontFamily: 'Pretendard',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                '취소',
                style: TextStyle(
                  color: Color(0xFFC2C2C2),
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text(
                '로그아웃',
                style: TextStyle(
                  color: Color(0xFFF44336),
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, String>?> _showDeleteAccountDialog() async {
    return Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => const DeleteAccountScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E2E2E),
          title: const Text(
            '오류',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Color(0xFFEAEAEA),
              fontFamily: 'Pretendard',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                '확인',
                style: TextStyle(
                  color: Color(0xFFF44336),
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
          '설정',
          style: TextStyle(
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
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 기기 알림 설정
                  _buildToggleItem(
                    title: '기기 알림 설정',
                    value: _deviceNotificationEnabled,
                    onChanged: (value) {
                      setState(() {
                        _deviceNotificationEnabled = value;
                      });
                      _saveUserSettings();
                    },
                  ),
                  const SizedBox(height: 20),

                  // 마케팅, 맞춤 정보 수신 동의
                  _buildToggleItem(
                    title: '마케팅, 맞춤 정보 수신 동의',
                    value: _marketingAgreementEnabled,
                    onChanged: (value) {
                      setState(() {
                        _marketingAgreementEnabled = value;
                      });
                      _saveUserSettings();
                    },
                  ),
                  const SizedBox(height: 20),

                  // 로그아웃
                  _buildActionItem(title: '로그아웃', onTap: _logout),
                  const SizedBox(height: 20),

                  // 탈퇴하기
                  _buildActionItem(title: '탈퇴하기', onTap: _deleteAccount),
                  const SizedBox(height: 20),

                  // 약관 및 정책
                  _buildActionItem(
                    title: '약관 및 정책',
                    onTap: () {
                      print('약관 및 정책 버튼 클릭됨');
                      try {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsPolicyScreen(),
                          ),
                        );
                        print('TermsPolicyScreen 네비게이션 성공');
                      } catch (e) {
                        print('TermsPolicyScreen 네비게이션 오류: $e');
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFEAEAEA),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Pretendard',
            ),
          ),
          const Spacer(),
          _buildToggleSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          color: value ? const Color(0xFFF44336) : const Color(0xFF8C8C8C),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEAEAEA),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required String title,
    required VoidCallback onTap,
  }) {
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
                fontSize: 16,
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
}
