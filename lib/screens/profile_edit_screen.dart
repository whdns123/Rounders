import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class ProfileEditScreen extends StatefulWidget {
  final UserModel user;

  const ProfileEditScreen({super.key, required this.user});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _nicknameController;
  late TextEditingController _phoneController;
  late TextEditingController _jobController;
  late TextEditingController _majorController;
  late String _selectedGender;
  late String _selectedAgeGroup;
  late String _selectedLocation;
  bool _isLoading = false;

  // 선택 옵션들
  final List<String> _genderOptions = ['남성', '여성', '기타'];
  final List<String> _ageGroupOptions = [
    '10대',
    '20-24세',
    '25-29세',
    '30-34세',
    '35-39세',
    '40세 이상',
  ];
  final List<String> _locationOptions = [
    '서울',
    '부산',
    '대구',
    '인천',
    '광주',
    '대전',
    '울산',
    '세종',
    '경기',
    '강원',
    '충북',
    '충남',
    '전북',
    '전남',
    '경북',
    '경남',
    '제주',
    '기타',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _nicknameController = TextEditingController(
      text: widget.user.nickname ?? '',
    );
    _phoneController = TextEditingController(text: widget.user.phone);
    _jobController = TextEditingController(text: widget.user.job ?? '');
    _majorController = TextEditingController(text: widget.user.major ?? '');

    // 사용자 데이터가 옵션 리스트에 있는지 확인하고, 없으면 기본값 사용
    _selectedGender =
        widget.user.gender.isNotEmpty &&
            _genderOptions.contains(widget.user.gender)
        ? widget.user.gender
        : _genderOptions[0];
    _selectedAgeGroup =
        widget.user.ageGroup.isNotEmpty &&
            _ageGroupOptions.contains(widget.user.ageGroup)
        ? widget.user.ageGroup
        : _ageGroupOptions[0];
    _selectedLocation =
        widget.user.location.isNotEmpty &&
            _locationOptions.contains(widget.user.location)
        ? widget.user.location
        : _locationOptions[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    _jobController.dispose();
    _majorController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final firestoreService = Provider.of<FirestoreService>(
        context,
        listen: false,
      );

      final updatedUser = widget.user.copyWith(
        name: _nameController.text.trim(),
        nickname: _nicknameController.text.trim().isEmpty
            ? null
            : _nicknameController.text.trim(),
        gender: _selectedGender,
        ageGroup: _selectedAgeGroup,
        location: _selectedLocation,
        phone: _phoneController.text.trim(),
        job: _jobController.text.trim().isEmpty
            ? null
            : _jobController.text.trim(),
        major: _majorController.text.trim().isEmpty
            ? null
            : _majorController.text.trim(),
      );

      await firestoreService.updateUserProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필이 성공적으로 업데이트되었습니다'),
            backgroundColor: Color(0xFFF44336),
          ),
        );
        Navigator.pop(context, updatedUser);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 업데이트 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '내 정보',
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
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 이메일 (읽기 전용)
                      _buildReadOnlyField('이메일', widget.user.email),
                      const SizedBox(height: 20),

                      // 휴대폰 번호 (읽기 전용)
                      _buildReadOnlyField('휴대폰 번호', widget.user.phone),
                      const SizedBox(height: 4),
                      _buildAccountTypeText(),
                      const SizedBox(height: 32),

                      // 실명
                      _buildTextField(
                        '실명',
                        _nameController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '실명을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // 닉네임 (선택사항)
                      _buildTextField('닉네임 (선택사항)', _nicknameController),
                      const SizedBox(height: 20),

                      // 성별
                      _buildDropdownField(
                        '성별',
                        _selectedGender,
                        _genderOptions,
                        (value) {
                          setState(() => _selectedGender = value!);
                        },
                      ),
                      const SizedBox(height: 20),

                      // 연령대
                      _buildDropdownField(
                        '연령대',
                        _selectedAgeGroup,
                        _ageGroupOptions,
                        (value) {
                          setState(() => _selectedAgeGroup = value!);
                        },
                      ),
                      const SizedBox(height: 20),

                      // 지역
                      _buildDropdownField(
                        '지역',
                        _selectedLocation,
                        _locationOptions,
                        (value) {
                          setState(() => _selectedLocation = value!);
                        },
                      ),
                      const SizedBox(height: 20),

                      // 직업 (선택사항)
                      _buildTextField('직업 (선택사항)', _jobController),
                      const SizedBox(height: 20),

                      // 전공 (선택사항)
                      _buildTextField('전공 (선택사항)', _majorController),
                      const SizedBox(height: 40),

                      // 저장 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF44336),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            '저장',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildReadOnlyField(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF3C3C3C),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFFA0A0A0),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountTypeText() {
    String accountType = '카카오톡 연동 계정';
    if (widget.user.email.contains('@gmail.com')) {
      accountType = '구글 연동 계정';
    }

    return Text(
      accountType,
      style: const TextStyle(
        color: Color(0xFFA0A0A0),
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFamily: 'Pretendard',
      ),
    );
  }

  Widget _buildTextField(
    String title,
    TextEditingController controller, {
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF3C3C3C),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            hintStyle: const TextStyle(
              color: Color(0xFFA0A0A0),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String title,
    String value,
    List<String> options,
    void Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF3C3C3C),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              onChanged: onChanged,
              dropdownColor: const Color(0xFF3C3C3C),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFFA0A0A0),
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard',
              ),
              items: options.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
