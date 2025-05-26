import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  String _gender = '';
  String _ageGroup = '';

  // 연령대 옵션
  final List<String> _ageGroups = [
    '선택하세요',
    '10대',
    '20대',
    '30대',
    '40대',
    '50대 이상'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone);
    _locationController = TextEditingController(text: widget.user.location);
    _gender = widget.user.gender;
    _ageGroup = widget.user.ageGroup.isEmpty ? '선택하세요' : widget.user.ageGroup;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // 저장 버튼 클릭 시 호출
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 사용자 정보 업데이트
      final updatedUser = widget.user.copyWith(
        name: _nameController.text.trim(),
        gender: _gender,
        ageGroup: _ageGroup == '선택하세요' ? '' : _ageGroup,
        location: _locationController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      // Firestore에 저장
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);
      await firestoreService.updateUserProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필이 업데이트되었습니다.')),
        );
        Navigator.pop(context, true); // 수정 완료 후 이전 화면으로 돌아가기
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프로필 업데이트 실패: $e')),
        );
      }
    } finally {
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A55A2),
        title: const Text('개인정보 수정', style: TextStyle(color: Colors.white)),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필 이미지 (수정 기능은 나중에 추가)
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: widget.user.photoURL != null
                          ? NetworkImage(widget.user.photoURL!)
                          : null,
                      child: widget.user.photoURL == null
                          ? const Icon(Icons.person,
                              size: 50, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.indigo,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 이름 입력 필드
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '이름',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '이름을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 성별 선택
              const Text('성별',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              Row(
                children: [
                  Radio<String>(
                    value: '남성',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value!;
                      });
                    },
                    activeColor: Colors.indigo,
                  ),
                  const Text('남성'),
                  const SizedBox(width: 16),
                  Radio<String>(
                    value: '여성',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value!;
                      });
                    },
                    activeColor: Colors.indigo,
                  ),
                  const Text('여성'),
                  const SizedBox(width: 16),
                  Radio<String>(
                    value: '기타',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value!;
                      });
                    },
                    activeColor: Colors.indigo,
                  ),
                  const Text('기타'),
                ],
              ),
              const SizedBox(height: 16),

              // 연령대 선택 드롭다운
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: '연령대',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cake),
                ),
                value: _ageGroup,
                items: _ageGroups.map((String ageGroup) {
                  return DropdownMenuItem<String>(
                    value: ageGroup,
                    child: Text(ageGroup),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _ageGroup = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 지역 입력 필드
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: '지역',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                  hintText: '예: 서울시 강남구',
                ),
              ),
              const SizedBox(height: 16),

              // 전화번호 입력 필드
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: '전화번호',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                  hintText: '예: 010-1234-5678',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),

              // 저장 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A55A2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '저장하기',
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
      ),
    );
  }
}
