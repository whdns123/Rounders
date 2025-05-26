import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class SignupScreen extends StatefulWidget {
  final VoidCallback? onSignupSuccess;

  const SignupScreen({Key? key, this.onSignupSuccess}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedGender = '남성';
  String _selectedAgeGroup = '20대';
  String _selectedLocation = '서울';

  bool _isLoading = false;
  String? _errorMessage;

  // 성별 선택 옵션
  final List<String> _genderOptions = ['남성', '여성', '기타'];

  // 나이대 선택 옵션
  final List<String> _ageGroupOptions = ['10대', '20대', '30대', '40대', '50대 이상'];

  // 거주지 선택 옵션
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
    '제주'
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
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

      // 이메일로 회원가입
      final userCredential = await authService.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (userCredential != null && userCredential.user != null) {
        // 사용자 프로필 초기화 (중요: Firestore에 사용자 기본 정보 생성)
        await firestoreService.initializeUserProfile(userCredential.user!);

        // 사용자 추가 정보 Firestore에 저장
        final user = UserModel(
          id: userCredential.user!.uid,
          email: _emailController.text.trim(),
          name: _nameController.text.trim(),
          gender: _selectedGender,
          ageGroup: _selectedAgeGroup,
          location: _selectedLocation,
          phone: _phoneController.text.trim(),
        );

        await firestoreService.updateUserProfile(user);

        // 사용자 표시 이름 업데이트
        await authService.updateProfile(
          displayName: _nameController.text.trim(),
        );

        if (widget.onSignupSuccess != null) {
          widget.onSignupSuccess!();
        }

        // 자동 로그인 처리
        await authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('회원가입이 완료되었습니다!')),
          );
          Navigator.of(context).pop(); // 회원가입 화면 닫기
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = '회원가입에 실패했습니다: $e';
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
        title: const Text('회원가입'),
        backgroundColor: const Color(0xFF4A55A2),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 에러 메시지
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: 14,
                    ),
                  ),
                ),

              // 이메일 입력
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '이메일 *',
                  hintText: 'example@email.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이메일을 입력해주세요.';
                  }
                  if (!value.contains('@')) {
                    return '유효한 이메일 형식이 아닙니다.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 비밀번호 입력
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '비밀번호 *',
                  hintText: '6자 이상 입력해주세요',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 입력해주세요.';
                  }
                  if (value.length < 6) {
                    return '비밀번호는 6자 이상이어야 합니다.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 이름 입력
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '이름 *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이름을 입력해주세요.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 성별 선택
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: '성별 *',
                  prefixIcon: Icon(Icons.wc),
                  border: OutlineInputBorder(),
                ),
                items: _genderOptions.map((gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedGender = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // 나이대 선택
              DropdownButtonFormField<String>(
                value: _selectedAgeGroup,
                decoration: const InputDecoration(
                  labelText: '나이대 *',
                  prefixIcon: Icon(Icons.event),
                  border: OutlineInputBorder(),
                ),
                items: _ageGroupOptions.map((ageGroup) {
                  return DropdownMenuItem<String>(
                    value: ageGroup,
                    child: Text(ageGroup),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedAgeGroup = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // 거주지 선택
              DropdownButtonFormField<String>(
                value: _selectedLocation,
                decoration: const InputDecoration(
                  labelText: '거주지 *',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                items: _locationOptions.map((location) {
                  return DropdownMenuItem<String>(
                    value: location,
                    child: Text(location),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedLocation = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // 연락처 입력
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: '연락처 *',
                  hintText: '010-1234-5678',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '연락처를 입력해주세요.';
                  }
                  // 간단한 전화번호 검증 (실제로는 더 정교한 검증이 필요할 수 있음)
                  if (!value.contains('-')) {
                    return '하이픈(-)을 포함하여 입력해주세요. (예: 010-1234-5678)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // 회원가입 버튼
              ElevatedButton(
                onPressed: _isLoading ? null : _signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A55A2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('회원가입', style: TextStyle(fontSize: 16)),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
