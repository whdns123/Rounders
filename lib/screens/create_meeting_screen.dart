import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/meeting.dart';

class CreateMeetingScreen extends StatefulWidget {
  const CreateMeetingScreen({Key? key}) : super(key: key);

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _maxParticipantsController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedLevel = '모두';

  final List<String> _levelOptions = ['모두', '초보', '중급', '고급', '전문가'];
  bool _isSubmitting = false;

  late FirestoreService _firestoreService;
  late AuthService _authService;
  String? _currentUserId;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
    _currentUserId = _authService.currentUser?.uid;
    _loadUserName();

    // 한글 입력을 위한 텍스트 컨트롤러 초기화
    _initializeTextControllers();
  }

  void _initializeTextControllers() {
    // 텍스트 변경 감지를 위한 리스너 추가 (필요시)
    _titleController.addListener(() {
      // 한글 입력 상태 감지 로직 (필요시 추가)
    });

    _descriptionController.addListener(() {
      // 한글 입력 상태 감지 로직 (필요시 추가)
    });

    _locationController.addListener(() {
      // 한글 입력 상태 감지 로직 (필요시 추가)
    });
  }

  Future<void> _loadUserName() async {
    if (_currentUserId != null) {
      final userInfo = await _firestoreService.getUserById(_currentUserId!);
      if (mounted) {
        setState(() {
          _userName = userInfo?.name ?? '게스트';
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4A55A2),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4A55A2),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }



  // 다음 모임 번호 가져오기
  Future<int> _getNextMeetingNumber() async {
    try {
      final snapshot = await _firestoreService.getActiveMeetings().first;
      return snapshot.length + 1;
    } catch (e) {
      print('모임 수 조회 실패, 기본값 1 사용: $e');
      return 1;
    }
  }

  // Asset 이미지 경로 생성
  Future<List<String>> _getAssetImagePaths() async {
    final meetingNumber = await _getNextMeetingNumber();
    final imagePath = 'assets/images/metting$meetingNumber.png';
    
    print('🖼️ 사용할 이미지: $imagePath (모임 번호: $meetingNumber)');
    
    return [imagePath];
  }

  Future<void> _submitMeeting() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Asset 이미지 경로 가져오기
      final List<String> imageUrls = await _getAssetImagePaths();

      // 모임 데이터 생성
      final Meeting meeting = Meeting(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        scheduledDate: _selectedDate,
        maxParticipants: int.parse(_maxParticipantsController.text.trim()),
        currentParticipants: 0,
        hostId: _currentUserId ?? '',
        hostName: _userName ?? '게스트',
        price: int.parse(_priceController.text.trim()),
        participants: [],
        imageUrls: imageUrls,
        requiredLevel: _selectedLevel,
      );

      // Firestore에 저장
      final meetingId = await _firestoreService.createMeeting(meeting);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모임이 성공적으로 생성되었습니다!')),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모임 생성 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('모임 만들기', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4A55A2),
        foregroundColor: Colors.white,
      ),
      body: _currentUserId == null
          ? const Center(child: Text('로그인이 필요합니다.'))
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '모임 정보',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 제목
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: '제목 *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.title),
                        ),
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        enableInteractiveSelection: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '제목을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 설명
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: '설명 *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.description),
                          alignLabelWithHint: true,
                        ),
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        enableInteractiveSelection: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '설명을 입력해주세요';
                          }
                          return null;
                        },
                        maxLines: 5,
                        minLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // 날짜 및 시간
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: '날짜 *',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTime(context),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: '시간 *',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.access_time),
                                ),
                                child: Text(
                                  '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 장소
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: '장소 *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.location_on),
                        ),
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        enableInteractiveSelection: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '장소를 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 참가비
                      TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: '참가비 (원) *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.monetization_on),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: false),
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '참가비를 입력해주세요';
                          }
                          if (int.tryParse(value) == null) {
                            return '숫자만 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 최대 인원
                      TextFormField(
                        controller: _maxParticipantsController,
                        decoration: InputDecoration(
                          labelText: '최대 인원 *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.group),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: false),
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '최대 인원을 입력해주세요';
                          }
                          if (int.tryParse(value) == null) {
                            return '숫자만 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 참가 가능 레벨
                      DropdownButtonFormField<String>(
                        value: _selectedLevel,
                        decoration: InputDecoration(
                          labelText: '참가 가능 레벨',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.grade),
                        ),
                        items: _levelOptions.map((level) {
                          return DropdownMenuItem<String>(
                            value: level,
                            child: Text(level),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedLevel = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // 대표 이미지 업로드
                      const Text(
                        '대표 이미지 (최대 5장)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '모임 이미지',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '자동 선택됨',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 자동 선택될 이미지 미리보기
                      FutureBuilder<int>(
                        future: _getNextMeetingNumber(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox(
                              height: 120,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          
                          final meetingNumber = snapshot.data!;
                          return Container(
                            height: 120,
                            width: 120,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image,
                                  size: 40,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'metting$meetingNumber.png',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '자동 할당됨',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),



                      // 모임 생성 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitMeeting,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A55A2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  '모임 만들기',
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
            ),
    );
  }
}
