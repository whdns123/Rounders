import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class HostApplicationScreen extends StatefulWidget {
  const HostApplicationScreen({Key? key}) : super(key: key);

  @override
  _HostApplicationScreenState createState() => _HostApplicationScreenState();
}

class _HostApplicationScreenState extends State<HostApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isCheckingStatus = true;
  String _hostStatus = 'none';

  // 신청 폼 필드
  final _reasonController = TextEditingController();
  final _experienceController = TextEditingController();
  final _planController = TextEditingController();
  String _selectedHostType = '개인';

  @override
  void initState() {
    super.initState();
    _checkHostStatus();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _experienceController.dispose();
    _planController.dispose();
    super.dispose();
  }

  // 호스트 신청 상태 확인
  Future<void> _checkHostStatus() async {
    setState(() {
      _isCheckingStatus = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);

      if (authService.currentUser != null) {
        final status = await firestoreService
            .getHostApplicationStatus(authService.currentUser!.uid);

        setState(() {
          _hostStatus = status['hostStatus'] ?? 'none';
        });
      }
    } catch (e) {
      print('호스트 상태 확인 실패: $e');
    } finally {
      setState(() {
        _isCheckingStatus = false;
      });
    }
  }

  // 호스트 신청 제출
  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);

      if (authService.currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 신청 데이터 생성
      final applicationData = {
        'reason': _reasonController.text.trim(),
        'experience': _experienceController.text.trim(),
        'plan': _planController.text.trim(),
        'hostType': _selectedHostType,
        'appliedAt': DateTime.now(),
      };

      // 호스트 신청 제출
      await firestoreService.applyForHostLicense(
        authService.currentUser!.uid,
        applicationData,
      );

      // 성공 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('호스트 라이선스 신청이 제출되었습니다. 관리자 검토 후 승인됩니다.')),
        );

        // 신청 상태 갱신
        setState(() {
          _hostStatus = 'pending';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '신청 제출 중 오류가 발생했습니다: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('호스트 라이선스 신청'),
        backgroundColor: Colors.indigo,
      ),
      body: _isCheckingStatus
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    // 호스트 상태에 따라 다른 화면 표시
    switch (_hostStatus) {
      case 'approved':
        return _buildApprovedContent();
      case 'pending':
        return _buildPendingContent();
      case 'rejected':
        return _buildRejectedContent();
      case 'none':
      default:
        return _buildApplicationForm();
    }
  }

  // 호스트 승인된 경우 화면
  Widget _buildApprovedContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            const Text(
              '호스트 라이선스 승인됨',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '축하합니다! 이제 모임을 주최하고 관리할 수 있습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.home),
              label: const Text('홈으로 돌아가기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 호스트 신청 대기 중인 경우 화면
  Widget _buildPendingContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.hourglass_empty,
              size: 80,
              color: Colors.amber,
            ),
            const SizedBox(height: 24),
            const Text(
              '호스트 라이선스 심사 중',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '신청하신 호스트 라이선스가 현재 심사 중입니다.\n관리자 검토 후 승인 결과를 알려드립니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }

  // 호스트 신청 거절된 경우 화면
  Widget _buildRejectedContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            const Text(
              '호스트 라이선스 신청 거절됨',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '신청하신 호스트 라이선스가 거절되었습니다.\n자세한 내용은 관리자에게 문의해주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // 신청 상태 초기화
                setState(() {
                  _hostStatus = 'none';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('다시 신청하기'),
            ),
          ],
        ),
      ),
    );
  }

  // 호스트 신청 폼
  Widget _buildApplicationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '호스트 라이선스 신청',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '호스트가 되면 모임을 직접 개설하고 참가자들을 관리할 수 있습니다. 아래 정보를 입력해주세요.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // 에러 메시지
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),

            // 호스트 유형 선택
            const Text(
              '호스트 유형',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedHostType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: '개인', child: Text('개인 호스트')),
                DropdownMenuItem(value: '단체', child: Text('단체/기업 호스트')),
                DropdownMenuItem(value: '장소제공자', child: Text('장소 제공자')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedHostType = value ?? '개인';
                });
              },
            ),
            const SizedBox(height: 16),

            // 신청 이유
            const Text(
              '신청 이유',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                hintText: '호스트가 되고자 하는 이유를 설명해주세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '신청 이유를 입력해주세요';
                }
                if (value.trim().length < 20) {
                  return '최소 20자 이상 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 관련 경험
            const Text(
              '관련 경험',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _experienceController,
              decoration: const InputDecoration(
                hintText: '모임 주최 또는 관련 활동 경험을 적어주세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '관련 경험을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 모임 계획
            const Text(
              '모임 계획',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _planController,
              decoration: const InputDecoration(
                hintText: '어떤 모임을 어떻게 운영할 계획인지 설명해주세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '모임 계획을 입력해주세요';
                }
                if (value.trim().length < 30) {
                  return '최소 30자 이상 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // 신청 버튼
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitApplication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
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
                    : const Text('신청하기'),
              ),
            ),
            const SizedBox(height: 16),

            // 안내 사항
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '호스트 라이선스 안내',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• 호스트 신청은 관리자 검토 후 승인됩니다 (1~2일 소요)\n'
                    '• 승인 시 모임 개설 및 관리 권한이 부여됩니다\n'
                    '• 허위 정보 기재 시 승인이 취소될 수 있습니다',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
