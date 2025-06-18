import 'package:flutter/material.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  String? _selectedReason;
  String _customReason = '';
  String _password = '';
  final TextEditingController _customReasonController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final List<String> _withdrawalReasons = [
    '원하는 시간/지역에 참여할 수 있는 모임이 없어요',
    '게임 주제나 난이도가 나와 잘 맞지 않아요',
    '모임 참여 경험(진행자, 구성원 등)이 기대에 못 미쳤어요',
    '앱 사용이 불편하거나 오류가 많았어요',
    '더 이상 이용할 시간이 없어요',
    '그냥 한번 사용해본 거예요',
    '기타(직접입력)',
  ];

  bool get _canSubmit {
    if (_selectedReason == null) return false;
    if (_selectedReason == '기타(직접입력)' && _customReason.trim().isEmpty) {
      return false;
    }
    if (_password.trim().isEmpty) return false;
    return true;
  }

  void _handleSubmit() {
    if (!_canSubmit) return;

    final String finalReason = _selectedReason == '기타(직접입력)'
        ? _customReason.trim()
        : _selectedReason!;

    Navigator.of(
      context,
    ).pop({'reason': finalReason, 'password': _password.trim()});
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
          '회원 탈퇴',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목 섹션
                  const Text(
                    '회원 탈퇴이유를 알려주세요.',
                    style: TextStyle(
                      color: Color(0xFFF5F5F5),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '더 좋은 서비스를 제공하기 위해 노력하겠습니다.',
                    style: TextStyle(
                      color: Color(0xFFD6D6D6),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  const SizedBox(height: 36),

                  // 탈퇴 사유 선택
                  ...List.generate(_withdrawalReasons.length, (index) {
                    final reason = _withdrawalReasons[index];
                    final isSelected = _selectedReason == reason;

                    return Column(
                      children: [
                        _buildReasonItem(reason, isSelected),
                        if (reason == '기타(직접입력)' && isSelected) ...[
                          const SizedBox(height: 12),
                          _buildCustomReasonField(),
                        ],
                        const SizedBox(height: 8),
                      ],
                    );
                  }),

                  const SizedBox(height: 24),

                  // 비밀번호 입력 섹션
                  const Text(
                    '계속하려면 비밀번호를 입력해주세요.',
                    style: TextStyle(
                      color: Color(0xFFEAEAEA),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPasswordField(),
                  const SizedBox(height: 8),
                  const Text(
                    '계정을 삭제하면 모든 데이터가 영구적으로 삭제됩니다.',
                    style: TextStyle(
                      color: Color(0xFF8C8C8C),
                      fontSize: 12,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 하단 버튼
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(color: Color(0xFF111111)),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _canSubmit ? _handleSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canSubmit
                      ? const Color(0xFFF44336)
                      : const Color(0xFFC2C2C2),
                  foregroundColor: _canSubmit
                      ? const Color(0xFFF5F5F5)
                      : const Color(0xFF8C8C8C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '탈퇴하기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonItem(String reason, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedReason = reason;
          if (reason != '기타(직접입력)') {
            _customReason = '';
            _customReasonController.clear();
          }
        });
      },
      child: SizedBox(
        height: 24,
        child: Row(
          children: [
            // 라디오 버튼
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFF44336)
                      : const Color(0xFF8C8C8C),
                  width: 2,
                ),
                color: isSelected
                    ? const Color(0xFFF44336)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.circle, size: 8, color: Color(0xFFF5F5F5))
                  : null,
            ),
            const SizedBox(width: 8),
            // 텍스트
            Expanded(
              child: Text(
                reason,
                style: const TextStyle(
                  color: Color(0xFFEAEAEA),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomReasonField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF3C3C3C),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        controller: _customReasonController,
        style: const TextStyle(
          color: Color(0xFFEAEAEA),
          fontFamily: 'Pretendard',
        ),
        decoration: const InputDecoration(
          hintText: '기타 사유를 입력해주세요.',
          hintStyle: TextStyle(
            color: Color(0xFFA0A0A0),
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        onChanged: (value) {
          setState(() {
            _customReason = value;
          });
        },
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF3C3C3C),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: true,
        style: const TextStyle(
          color: Color(0xFFEAEAEA),
          fontFamily: 'Pretendard',
        ),
        decoration: const InputDecoration(
          hintText: '비밀번호',
          hintStyle: TextStyle(
            color: Color(0xFFA0A0A0),
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        onChanged: (value) {
          setState(() {
            _password = value;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _customReasonController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
