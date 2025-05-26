import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import '../services/mock_auth_service.dart';
import '../services/user_profile_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'edit_profile_screen.dart';
import 'host_application_screen.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final _userProfileService = UserProfileService();
  bool _isLoading = true;
  late AuthService _authService;

  // 호스트 상태 정보
  bool _isHost = false;
  String _hostStatus = 'none';
  bool _isLoadingHostStatus = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authService = Provider.of<AuthService>(context, listen: false);
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _isLoadingHostStatus = true;
    });

    try {
      await _userProfileService.refreshData();

      // 호스트 상태 확인
      if (_authService.currentUser != null) {
        final firestoreService =
            Provider.of<FirestoreService>(context, listen: false);
        final hostStatus = await firestoreService
            .getHostApplicationStatus(_authService.currentUser!.uid);

        setState(() {
          _isHost = hostStatus['isHost'] ?? false;
          _hostStatus = hostStatus['hostStatus'] ?? 'none';
        });
      }
    } catch (e) {
      print('사용자 데이터 로드 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사용자 데이터를 불러오는 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingHostStatus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final displayName = user?.displayName ?? '게스트';
    final email = user?.email ?? '로그인 필요';

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 프로필 정보
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundImage:
                              AssetImage('assets/images/badge.png'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                email,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildTierChip(
                                      _userProfileService.userTierString),
                                  const SizedBox(width: 8),
                                  _buildStatChip(
                                      '${_userProfileService.totalScore}점',
                                      Icons.emoji_events),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),

                  // 사용자 통계 섹션
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '나의 통계',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCard(
                              '티어',
                              _userProfileService.userTierString,
                              Icons.military_tech,
                              _getTierColor(_userProfileService.userTierString),
                            ),
                            _buildStatCard(
                              '총점',
                              '${_userProfileService.totalScore}점',
                              Icons.emoji_events,
                              Colors.amber,
                            ),
                            _buildStatCard(
                              '참여 모임',
                              '${_userProfileService.meetingsPlayed}회',
                              Icons.groups,
                              Colors.blue,
                            ),
                            _buildStatCard(
                              '평균 점수',
                              _userProfileService.avgScore.toStringAsFixed(1),
                              Icons.trending_up,
                              Colors.green,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 호스트 정보 표시
                        if (_isHost) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildHostingCard(
                                  '주최한 모임',
                                  '${_userProfileService.hostedMeetingsCount}회',
                                  _userProfileService.hostedMeetingsCount > 0),
                            ],
                          ),

                          // 호스트 모임 목록 보기 버튼
                          if (_userProfileService.hostedMeetingsCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Center(
                                child: TextButton.icon(
                                  onPressed: () {
                                    // 내가 주최한 모임 목록 화면으로 이동
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              '내가 주최한 모임 목록 기능은 곧 추가될 예정입니다.')),
                                    );
                                  },
                                  icon: const Icon(Icons.list, size: 16),
                                  label: const Text('내가 주최한 모임 목록 보기'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.indigo,
                                  ),
                                ),
                              ),
                            ),
                        ],

                        // 호스트 라이선스 신청 버튼
                        if (!_isHost &&
                            _hostStatus == 'none' &&
                            !_isLoadingHostStatus)
                          Padding(
                            padding: const EdgeInsets.only(top: 24.0),
                            child: Center(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const HostApplicationScreen(),
                                    ),
                                  ).then((_) => _loadUserData());
                                },
                                icon: const Icon(Icons.verified_user),
                                label: const Text('호스트 라이선스 신청하기'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                ),
                              ),
                            ),
                          ),

                        // 호스트 신청 상태 표시
                        if (!_isHost &&
                            _hostStatus == 'pending' &&
                            !_isLoadingHostStatus)
                          Padding(
                            padding: const EdgeInsets.only(top: 24.0),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.amber.shade200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.hourglass_empty,
                                        color: Colors.amber.shade700),
                                    const SizedBox(width: 8),
                                    const Text(
                                      '호스트 라이선스 심사 중',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const Divider(),

                  // 티어 정보 섹션
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '나의 티어',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),

                  // 티어 설명
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _buildTierDescription(
                        _userProfileService.userTierString),
                  ),

                  const SizedBox(height: 16),

                  // 게임 기록 표시
                  if (_userProfileService.gameHistory.isNotEmpty) ...[
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        '최근 게임 기록',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),

                    ..._userProfileService.gameHistory.take(3).map((game) {
                      final bool isWin = game['result'] == 'Win';
                      final int points = game['pointsGained'] as int;

                      return ListTile(
                        title: Text(game['gameName'] as String),
                        subtitle: Text(game['date'] as String),
                        trailing: Text(
                          '${isWin ? '+' : ''}$points 점',
                          style: TextStyle(
                            color: isWin ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),

                    // 더보기 버튼
                    if (_userProfileService.gameHistory.length > 3)
                      Center(
                        child: TextButton(
                          onPressed: () {
                            // 게임 기록 전체 보기 화면으로 이동
                          },
                          child: const Text('전체 기록 보기'),
                        ),
                      ),
                  ] else ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          '게임 기록이 없습니다.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const Divider(),

                  // 업적 섹션
                  if (_userProfileService.achievements.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        '나의 업적',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            _userProfileService.achievements.map((achievement) {
                          return Chip(
                            label: Text(achievement),
                            backgroundColor: Colors.indigo.shade100,
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 설정 섹션
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '설정',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),

                  // 설정 목록
                  ListTile(
                    leading: const Icon(Icons.account_circle),
                    title: const Text('계정 정보'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      final firestoreService =
                          Provider.of<FirestoreService>(context, listen: false);
                      final user = await firestoreService
                          .getUserById(_authService.currentUser?.uid ?? '');

                      if (user != null && mounted) {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(user: user),
                          ),
                        );

                        // 프로필이 업데이트되었으면 데이터 새로고침
                        if (result == true) {
                          _loadUserData();
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('사용자 정보를 불러올 수 없습니다.')),
                          );
                        }
                      }
                    },
                  ),
                  // 주최한 모임 관리 메뉴
                  if (_isHost)
                    ListTile(
                      leading: const Icon(Icons.event_available),
                      title: const Text('주최한 모임 관리'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_userProfileService.hostedMeetingsCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_userProfileService.hostedMeetingsCount}',
                                style: TextStyle(
                                  color: Colors.indigo.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('주최한 모임 관리 기능은 곧 추가될 예정입니다.')),
                        );
                      },
                    ),
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('알림 설정'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: const Text('개인정보 설정'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.gamepad),
                    title: const Text('게임 결과 테스트'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pushNamed(context, '/game-result-test');
                    },
                  ),

                  // 로그아웃 버튼
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title:
                        const Text('로그아웃', style: TextStyle(color: Colors.red)),
                    onTap: () => _handleLogout(context),
                  ),
                ],
              ),
            ),
    );
  }

  // 티어 색상 반환
  Color _getTierColor(String tier) {
    switch (tier) {
      case '다이아몬드':
        return Colors.lightBlue;
      case '플래티넘':
        return Colors.blueGrey;
      case '골드':
        return Colors.amber;
      case '실버':
        return Colors.grey;
      case '브론즈':
      default:
        return Colors.brown;
    }
  }

  // 티어 칩 위젯
  Widget _buildTierChip(String tier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getTierColor(tier).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getTierColor(tier)),
      ),
      child: Text(
        tier,
        style: TextStyle(
          color: _getTierColor(tier).withOpacity(0.8),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 통계 칩 위젯
  Widget _buildStatChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 통계 카드 위젯
  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 호스트 정보 카드 위젯
  Widget _buildHostingCard(String label, String value, bool isHost) {
    return Card(
      elevation: 2,
      color:
          isHost ? Colors.indigoAccent.withOpacity(0.1) : Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_available,
              color: isHost ? Colors.indigoAccent : Colors.grey,
              size: 28,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isHost ? Colors.indigo : Colors.grey.shade700,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        isHost ? Colors.indigo.shade700 : Colors.grey.shade600,
                  ),
                ),
                if (isHost)
                  const Text(
                    '호스트 뱃지 획득!',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 티어 설명 위젯
  Widget _buildTierDescription(String tier) {
    String description;
    switch (tier) {
      case '다이아몬드':
        description = '최상위 티어입니다. 보드게임의 달인이며, 다양한 게임에서 뛰어난 실력을 보여주고 있습니다.';
        break;
      case '플래티넘':
        description = '높은 수준의 플레이어입니다. 전략적 사고와 판단력이 뛰어납니다.';
        break;
      case '골드':
        description = '중상위 티어로, 게임에 대한 이해도가 높고 안정적인 실력을 보여줍니다.';
        break;
      case '실버':
        description = '중급 티어로, 기본기를 잘 갖추고 있습니다. 더 많은 경험을 쌓아 상위 티어로 올라갈 수 있습니다.';
        break;
      case '브론즈':
      default:
        description = '시작 티어입니다. 다양한 모임에 참여하여 점수를 쌓아보세요!';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildTierChip(tier),
              const SizedBox(width: 8),
              Text(
                '티어',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '모임 참여 및 순위에 따라 점수가 누적되며, 평균 점수에 따라 티어가 결정됩니다.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 로그아웃 처리
  Future<void> _handleLogout(BuildContext context) async {
    // 확인 다이얼로그 표시
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();

      if (context.mounted) {
        // 로그인 화면으로 이동
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }
}
