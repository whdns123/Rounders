import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';

class HostApplicationScreen extends StatefulWidget {
  const HostApplicationScreen({Key? key}) : super(key: key);

  @override
  _HostApplicationScreenState createState() => _HostApplicationScreenState();
}

class _HostApplicationScreenState extends State<HostApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _hasApplied = false;

  // 신청 폼 필드
  final _reasonController = TextEditingController();
  final _experienceController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  // 호스트 신청 제출
  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);
      await firestoreService.applyForHost();

      setState(() {
        _hasApplied = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('호스트 신청이 제출되었습니다!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('신청 실패: $e')),
      );
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
        title: const Text('호스트 신청'),
        backgroundColor: const Color(0xFF4A55A2),
        foregroundColor: Colors.white,
      ),
      body: _hasApplied ? _buildSuccessContent() : _buildApplicationForm(),
    );
  }

  Widget _buildSuccessContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            const Text(
              '신청이 완료되었습니다!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '관리자 검토 후 승인 여부를 알려드립니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A55A2),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('홈으로 돌아가기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '호스트 신청',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '모임을 주최하려면 호스트 권한이 필요합니다. 아래 정보를 입력해주세요.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            // 신청 이유
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: '신청 이유',
                hintText: '호스트가 되고 싶은 이유를 알려주세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '신청 이유를 입력해주세요';
                }
                if (value.trim().length < 10) {
                  return '신청 이유를 10자 이상 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 경험
            TextFormField(
              controller: _experienceController,
              decoration: const InputDecoration(
                labelText: '관련 경험',
                hintText: '모임 운영이나 관련 경험을 알려주세요',
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
            const SizedBox(height: 32),

            // 신청 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitApplication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A55A2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
                    : const Text(
                        '신청하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
