import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/meeting.dart';
import '../models/game.dart';
import '../models/venue.dart';
import '../utils/toast_utils.dart';
import '../screens/meeting_detail_screen.dart';

class HostCreateMeetingScreen extends StatefulWidget {
  final bool isEditMode;
  final Meeting? meetingToEdit;
  final Game? gameToEdit;
  final Venue? venueToEdit;

  const HostCreateMeetingScreen({
    super.key,
    this.isEditMode = false,
    this.meetingToEdit,
    this.gameToEdit,
    this.venueToEdit,
  });

  @override
  State<HostCreateMeetingScreen> createState() =>
      _HostCreateMeetingScreenState();
}

class _HostCreateMeetingScreenState extends State<HostCreateMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _benefitController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _startTime; // "18:30" 형태로 저장
  String? _endTime; // "20:00" 형태로 저장
  Game? _selectedGame;
  Venue? _selectedVenue;
  List<Venue> _venues = [];
  bool _isSubmitting = false;
  bool _isLoadingVenues = true;
  String? _selectedCoverImage; // 호스트가 선택한 표지 이미지
  bool _hasSetEditGame = false; // 수정 모드에서 게임이 이미 설정되었는지 확인

  late FirestoreService _firestoreService;
  late AuthService _authService;
  String? _currentUserId;
  String? _userName;

  // 30분 단위 시간 리스트 생성
  List<String> _generateTimeSlots() {
    List<String> timeSlots = [];
    for (int hour = 9; hour <= 23; hour++) {
      timeSlots.add('${hour.toString().padLeft(2, '0')}:00');
      timeSlots.add('${hour.toString().padLeft(2, '0')}:30');
    }
    return timeSlots;
  }

  // 폼 유효성 검사
  bool _isFormValid() {
    return _titleController.text.trim().isNotEmpty &&
        _selectedVenue != null &&
        _startTime != null &&
        _endTime != null &&
        _selectedGame != null &&
        (_startTime != null && _endTime != null
            ? _isValidTimeRange(_startTime!, _endTime!)
            : false);
  }

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
    _currentUserId = _authService.currentUser?.uid;
    _loadUserName();
    _loadAllVenues(); // 처음부터 모든 장소 로드
    _ensureGamesExist();

    // 수정 모드인 경우 기존 데이터 로드
    if (widget.isEditMode && widget.meetingToEdit != null) {
      _loadEditData();
    }
  }

  void _loadEditData() {
    final meeting = widget.meetingToEdit!;

    // 폼 데이터 채우기
    _titleController.text = meeting.title;
    _locationController.text = meeting.location;
    _benefitController.text = meeting.benefitDescription ?? '';

    // 날짜 설정
    _selectedDate = meeting.scheduledDate;

    // 시간 설정
    _startTime =
        '${meeting.scheduledDate.hour.toString().padLeft(2, '0')}:${meeting.scheduledDate.minute.toString().padLeft(2, '0')}';
    // 기본적으로 2시간 후로 종료 시간 설정 (실제로는 DB에서 가져와야 함)
    final endDateTime = meeting.scheduledDate.add(const Duration(hours: 2));
    _endTime =
        '${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}';

    // 커버 이미지 설정
    _selectedCoverImage = meeting.coverImageUrl;

    // 게임과 장소는 데이터 로드 후에 설정해야 함
    // _setEditDataAfterLoad()에서 처리

    setState(() {});
  }

  // 데이터 로드 후 게임과 장소 설정
  void _setEditDataAfterLoad() {
    if (!widget.isEditMode || widget.meetingToEdit == null) return;

    // 장소 설정 - venues 리스트에서 동일한 ID를 가진 항목 찾기
    if (widget.venueToEdit != null) {
      final venueFromList = _venues.firstWhere(
        (venue) => venue.id == widget.venueToEdit!.id,
        orElse: () => widget.venueToEdit!,
      );
      if (_venues.contains(venueFromList)) {
        _selectedVenue = venueFromList;
      }
    }

    setState(() {});
  }

  // 게임 데이터 로드 후 게임 설정
  void _setEditGameAfterLoad(List<Game> games) {
    if (!widget.isEditMode || widget.gameToEdit == null || _hasSetEditGame)
      return;

    // 게임 설정 - games 리스트에서 동일한 ID를 가진 항목 찾기
    final gameFromList = games.cast<Game?>().firstWhere(
      (game) => game?.id == widget.gameToEdit!.id,
      orElse: () => null,
    );

    if (gameFromList != null) {
      _selectedGame = gameFromList;
      _hasSetEditGame = true; // 플래그 설정하여 중복 실행 방지
      setState(() {});
    }
  }

  Future<void> _ensureGamesExist() async {
    try {
      // 게임 데이터가 있는지 확인
      final games = await _firestoreService.getGames().first;
      if (games.isEmpty) {
        print('게임 데이터가 없어서 샘플 게임을 추가합니다...');
        // await _firestoreService.addSampleGames(); // 자동 생성 비활성화
        print('샘플 게임 추가 완료!');
      } else {
        print('기존 게임 데이터 ${games.length}개 발견');
      }
    } catch (e) {
      print('게임 데이터 확인 중 오류: $e');
    }
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

  Future<void> _loadHostVenues() async {
    print('Current user ID: $_currentUserId');
    if (_currentUserId != null) {
      try {
        print('Loading venues for user: $_currentUserId');
        final hostVenues = await _firestoreService.getHostVenues(
          _currentUserId!,
        );
        print('Loaded ${hostVenues.length} venues');
        if (mounted) {
          setState(() {
            _venues = hostVenues;
            _isLoadingVenues = false;
          });
        }
      } catch (e) {
        print('Error loading host venues: $e');
        if (mounted) {
          setState(() {
            _isLoadingVenues = false;
          });
        }
      }
    } else {
      print('No current user ID');
      setState(() {
        _isLoadingVenues = false;
      });
    }
  }

  Future<void> _loadAllVenues() async {
    print('🏢 모든 장소 데이터 로딩 시작...');
    setState(() {
      _isLoadingVenues = true;
    });

    try {
      // 모든 venues 컬렉션 데이터 가져오기
      final allVenues = await _firestoreService.getAllVenues();
      print('🏢 총 ${allVenues.length}개의 장소를 찾았습니다');

      // locations에서도 장소 데이터 가져오기
      final locationVenues = await _firestoreService.getAllLocationVenues();
      print('🏢 locations에서 ${locationVenues.length}개의 장소를 찾았습니다');

      // 두 리스트 합치기 (중복 제거)
      final combinedVenues = <Venue>[];
      combinedVenues.addAll(allVenues);

      for (final venue in locationVenues) {
        // ID 기반으로 중복 제거
        if (!combinedVenues.any((v) => v.id == venue.id)) {
          combinedVenues.add(venue);
        }
      }

      print('🏢 중복 제거 후 총 ${combinedVenues.length}개의 장소가 있습니다');

      if (mounted) {
        setState(() {
          _venues = combinedVenues;
          _isLoadingVenues = false;
        });

        // 수정 모드인 경우 데이터 로드 후 설정
        _setEditDataAfterLoad();
      }
    } catch (e) {
      print('🚨 모든 장소 로딩 중 오류: $e');
      if (mounted) {
        setState(() {
          _isLoadingVenues = false;
        });
      }

      // 사용자에게 오류 알림
      if (mounted) {
        ToastUtils.showError(context, '장소 데이터를 불러오는 중 오류가 발생했습니다.');
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _benefitController.dispose();
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
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFF44336), // 빨간색으로 변경하여 선택된 날짜 잘 보이게
              onPrimary: Colors.white,
              surface: Color(0xFF2E2E2E),
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF44336),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      print('📅 선택된 날짜: ${picked.year}-${picked.month}-${picked.day}');
    }
  }

  // 시간을 분으로 변환하는 헬퍼 함수
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  // 분을 시간 문자열로 변환하는 헬퍼 함수
  String _minutesToTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  // 유효한 시간 슬롯 필터링
  List<String> _getValidTimeSlots(bool isStart) {
    final allTimeSlots = _generateTimeSlots();

    if (isStart) {
      // 시작시간: 종료시간이 있으면 제약조건 적용
      if (_endTime != null) {
        final endMinutes = _timeToMinutes(_endTime!);
        return allTimeSlots.where((time) {
          final startMinutes = _timeToMinutes(time);
          final duration = endMinutes - startMinutes;
          return duration >= 60 && duration <= 300; // 1시간 이상 5시간 이하
        }).toList();
      }
      return allTimeSlots;
    } else {
      // 종료시간: 시작시간이 있으면 제약조건 적용
      if (_startTime != null) {
        final startMinutes = _timeToMinutes(_startTime!);
        return allTimeSlots.where((time) {
          final endMinutes = _timeToMinutes(time);
          final duration = endMinutes - startMinutes;
          return duration >= 60 && duration <= 300; // 1시간 이상 5시간 이하
        }).toList();
      }
      return allTimeSlots;
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final validTimeSlots = _getValidTimeSlots(isStart);
    final currentTime = isStart ? _startTime : _endTime;

    // 현재 선택된 시간의 인덱스 찾기
    int initialIndex = 0;
    if (currentTime != null && validTimeSlots.contains(currentTime)) {
      initialIndex = validTimeSlots.indexOf(currentTime);
    }

    String? selectedTime = currentTime;

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2E2E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                isStart ? '시작 시간 선택' : '종료 시간 선택',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (!isStart && _startTime != null)
                Text(
                  '플레이 시간: 1시간 이상 5시간 이하',
                  style: const TextStyle(
                    color: Color(0xFFA0A0A0),
                    fontSize: 12,
                  ),
                ),
              const SizedBox(height: 16),
              Expanded(
                child: validTimeSlots.isEmpty
                    ? const Center(
                        child: Text(
                          '선택 가능한 시간이 없습니다.\n시작 시간을 다시 선택해주세요.',
                          style: TextStyle(
                            color: Color(0xFFA0A0A0),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : CupertinoPicker(
                        backgroundColor: Colors.transparent,
                        itemExtent: 40,
                        scrollController: FixedExtentScrollController(
                          initialItem: initialIndex,
                        ),
                        onSelectedItemChanged: (index) {
                          selectedTime = validTimeSlots[index];
                        },
                        children: validTimeSlots.map((time) {
                          return Center(
                            child: Text(
                              time,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          color: Color(0xFFA0A0A0),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: validTimeSlots.isEmpty
                          ? null
                          : () {
                              if (selectedTime != null) {
                                // 시간 검증
                                if (_validateTimeSelection(
                                  selectedTime!,
                                  isStart,
                                )) {
                                  setState(() {
                                    if (isStart) {
                                      _startTime = selectedTime;
                                      // 종료시간이 유효하지 않으면 리셋
                                      if (_endTime != null &&
                                          !_isValidTimeRange(
                                            _startTime!,
                                            _endTime!,
                                          )) {
                                        _endTime = null;
                                      }
                                    } else {
                                      _endTime = selectedTime;
                                    }
                                  });
                                  Navigator.pop(context);
                                } else {
                                  // 유효하지 않은 시간 선택시 경고
                                  ToastUtils.showError(
                                    context,
                                    '플레이 시간은 1시간 이상 5시간 이하여야 합니다.',
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF44336),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('확인', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 시간 선택 검증
  bool _validateTimeSelection(String selectedTime, bool isStart) {
    if (isStart && _endTime != null) {
      return _isValidTimeRange(selectedTime, _endTime!);
    } else if (!isStart && _startTime != null) {
      return _isValidTimeRange(_startTime!, selectedTime);
    }
    return true; // 하나만 선택된 경우는 항상 유효
  }

  // 시간 범위 검증 (1시간 이상 5시간 이하)
  bool _isValidTimeRange(String startTime, String endTime) {
    final startMinutes = _timeToMinutes(startTime);
    final endMinutes = _timeToMinutes(endTime);
    final duration = endMinutes - startMinutes;

    return duration >= 60 && duration <= 300; // 1시간(60분) 이상 5시간(300분) 이하
  }

  Future<void> _submitMeeting() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startTime == null || _endTime == null) {
      ToastUtils.showError(context, '시작 시간과 종료 시간을 모두 선택해주세요');
      return;
    }

    if (_selectedGame == null) {
      ToastUtils.showError(context, '게임을 선택해주세요');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 시작 시간으로 DateTime 생성 (시간은 문자열로 저장하되, 날짜는 DateTime으로)
      final startTimeParts = _startTime!.split(':');
      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        int.parse(startTimeParts[0]),
        int.parse(startTimeParts[1]),
      );

      // 🔍 호스트가 입력한 베테핏 디버그
      final benefitInput = _benefitController.text.trim();
      print('🎁 호스트가 입력한 베테핏: "$benefitInput"');
      print('🎁 베테핏 입력 길이: ${benefitInput.length}');
      print('🎁 베테핏 비어있음: ${benefitInput.isEmpty}');
      print(
        '🎁 description에 들어갈 값: ${benefitInput.isNotEmpty ? benefitInput : _selectedGame!.description}',
      );

      if (widget.isEditMode && widget.meetingToEdit != null) {
        // 수정 모드: 기존 모임 업데이트
        final updatedMeeting = Meeting(
          id: widget.meetingToEdit!.id,
          title: _titleController.text.trim().isNotEmpty
              ? _titleController.text.trim()
              : _selectedGame!.title,
          description: _benefitController.text.trim().isNotEmpty
              ? _benefitController.text.trim()
              : _selectedGame!.description,
          location: _locationController.text.trim(),
          scheduledDate: scheduledDateTime,
          maxParticipants: _selectedGame!.maxParticipants,
          currentParticipants:
              widget.meetingToEdit!.currentParticipants, // 기존 참가자 수 유지
          hostId: widget.meetingToEdit!.hostId,
          hostName: widget.meetingToEdit!.hostName,
          price: _selectedGame!.price.toDouble(),
          participants: widget.meetingToEdit!.participants, // 기존 참가자 목록 유지
          imageUrls: [_selectedGame!.imageUrl],
          coverImageUrl: _selectedCoverImage,
          requiredLevel: _selectedGame!.difficulty,
          gameId: _selectedGame!.id,
          venueId: _selectedVenue?.id,
          benefitDescription: _benefitController.text.trim(),
          tags: _selectedGame!.tags,
          difficulty: _selectedGame!.difficulty,
          rating: _selectedGame!.rating,
          reviewCount: _selectedGame!.reviewCount,
          minParticipants: _selectedGame!.minParticipants,
          status: widget.meetingToEdit!.status, // 기존 상태 유지
        );

        await _firestoreService.updateMeeting(
          updatedMeeting.id,
          updatedMeeting.toMap(),
        );
        ToastUtils.showSuccess(context, '모임이 수정되었습니다!');

        if (mounted) {
          Navigator.pop(context, true); // true를 반환하여 새로고침 신호
        }
      } else {
        // 생성 모드: 새 모임 생성
        final Meeting meeting = Meeting(
          id: '',
          title: _titleController.text.trim().isNotEmpty
              ? _titleController.text.trim()
              : _selectedGame!.title,
          description: _benefitController.text.trim().isNotEmpty
              ? _benefitController.text.trim()
              : _selectedGame!.description,
          location: _locationController.text.trim(),
          scheduledDate: scheduledDateTime,
          maxParticipants: _selectedGame!.maxParticipants,
          currentParticipants: 0,
          hostId: _currentUserId ?? '',
          hostName: _userName ?? '게스트',
          price: _selectedGame!.price.toDouble(),
          participants: [],
          imageUrls: [_selectedGame!.imageUrl],
          coverImageUrl: _selectedCoverImage, // 호스트가 업로드한 표지 이미지
          requiredLevel: _selectedGame!.difficulty,
          gameId: _selectedGame!.id,
          venueId: _selectedVenue?.id, // 선택된 장소의 ID 저장
          benefitDescription: _benefitController.text.trim(),
          tags: _selectedGame!.tags,
          difficulty: _selectedGame!.difficulty,
          rating: _selectedGame!.rating,
          reviewCount: _selectedGame!.reviewCount,
          minParticipants: _selectedGame!.minParticipants,
        );

        // Firestore에 저장 (시작/종료 시간도 추가 필드로 저장)
        await _firestoreService.createMeeting(meeting);
        ToastUtils.showSuccess(context, '모임이 성공적으로 생성되었습니다!');

        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      ToastUtils.showError(context, '모임 생성 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: Text(
          widget.isEditMode ? '모임 수정하기' : '모임 만들기',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF111111),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _currentUserId == null
          ? const Center(
              child: Text('로그인이 필요합니다.', style: TextStyle(color: Colors.white)),
            )
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // 제목
                      _buildTextField(
                        _titleController,
                        '모임 제목',
                        '모임 제목을 입력하세요 (선택사항)',
                      ),
                      const SizedBox(height: 16),
                      // 위치/장소 선택
                      _buildVenueDropdown(),
                      const SizedBox(height: 16),
                      // 날짜
                      _buildDateButton(context),
                      const SizedBox(height: 16),
                      // 시간 선택 (시작/종료)
                      _buildTimeButtons(context),
                      const SizedBox(height: 16),
                      // 게임 선택
                      _buildGameDropdown(context),
                      const SizedBox(height: 16),
                      // 표지 이미지 업로드
                      _buildCoverImageUpload(),
                      const SizedBox(height: 16),
                      // 참여 혜택
                      _buildTextField(
                        _benefitController,
                        '참여 혜택',
                        '참여 혜택을 입력하세요 (선택사항)',
                      ),
                      const SizedBox(height: 120), // 하단 버튼 공간 확보
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Row(
          children: [
            // 미리보기 버튼
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _showPreview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: const Color(0xFFF5F5F5),
                    side: const BorderSide(color: Color(0xFF8C8C8C)),
                    disabledBackgroundColor: Colors.transparent,
                    disabledForegroundColor: const Color(0xFF8C8C8C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    '미리보기',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // 만들기 버튼
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || !_isFormValid())
                      ? null
                      : _submitMeeting,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_isSubmitting || !_isFormValid())
                        ? const Color(0xFFC2C2C2)
                        : const Color(0xFFF44336),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFC2C2C2),
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
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
                      : Text(
                          widget.isEditMode ? '저장하기' : '만들기',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFEAEAEA),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF3C3C3C),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextFormField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFA0A0A0)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              setState(() {}); // 폼 상태 변경 시 UI 업데이트
            },
            validator: (value) {
              // 모든 필드는 선택사항 (장소는 별도 드롭다운에서 검증)
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateButton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '날짜',
          style: TextStyle(
            color: Color(0xFFEAEAEA),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF3C3C3C),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${_selectedDate.year}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.day.toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  // 플레이 시간 계산
  String _getPlayDuration() {
    if (_startTime != null && _endTime != null) {
      final startMinutes = _timeToMinutes(_startTime!);
      final endMinutes = _timeToMinutes(_endTime!);
      final duration = endMinutes - startMinutes;

      if (duration <= 0) return '';

      final hours = duration ~/ 60;
      final minutes = duration % 60;

      if (minutes == 0) {
        return '플레이 시간: ${hours}시간';
      } else {
        return '플레이 시간: ${hours}시간 ${minutes}분';
      }
    }
    return '';
  }

  Widget _buildTimeButtons(BuildContext context) {
    final playDuration = _getPlayDuration();
    final isValidDuration =
        _startTime != null &&
        _endTime != null &&
        _isValidTimeRange(_startTime!, _endTime!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '시간 선택',
          style: TextStyle(
            color: Color(0xFFEAEAEA),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectTime(context, true),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3C3C3C),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _startTime ?? '시작 시간',
                    style: TextStyle(
                      color: _startTime != null
                          ? Colors.white
                          : const Color(0xFFA0A0A0),
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '~',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => _selectTime(context, false),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3C3C3C),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _endTime ?? '종료 시간',
                    style: TextStyle(
                      color: _endTime != null
                          ? Colors.white
                          : const Color(0xFFA0A0A0),
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (playDuration.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            playDuration,
            style: TextStyle(
              color: isValidDuration
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFF44336),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!isValidDuration && _startTime != null && _endTime != null)
            const Text(
              '플레이 시간은 1시간 이상 5시간 이하여야 합니다.',
              style: TextStyle(color: Color(0xFFF44336), fontSize: 12),
            ),
        ],
      ],
    );
  }

  Widget _buildVenueDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '장소 선택',
          style: TextStyle(
            color: Color(0xFFEAEAEA),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        if (_isLoadingVenues)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF3C3C3C),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '장소 목록 로딩 중...',
              style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 15),
            ),
          )
        else if (_venues.isEmpty)
          InkWell(
            onTap: () {
              print('🏢 장소 선택 버튼이 탭되었습니다!');
              _loadAllVenues();
            },
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF3C3C3C),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF666666), width: 1),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '장소 선택하기',
                      style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 15),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFFA0A0A0),
                    size: 20,
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF3C3C3C),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonFormField<Venue>(
              value: _selectedVenue != null && _venues.contains(_selectedVenue)
                  ? _selectedVenue
                  : null,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              dropdownColor: const Color(0xFF3C3C3C),
              style: const TextStyle(color: Colors.white, fontSize: 15),
              hint: const Text(
                '장소를 선택하세요',
                style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 15),
              ),
              items: [
                // 등록된 장소들만 표시 (직접 입력 옵션 제거)
                ..._venues.map((Venue venue) {
                  return DropdownMenuItem<Venue>(
                    value: venue,
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: 280, // 최대 너비 제한
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            venue.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            venue.address,
                            style: const TextStyle(
                              color: Color(0xFFA0A0A0),
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
              onChanged: (Venue? newValue) {
                setState(() {
                  _selectedVenue = newValue;
                  if (newValue != null) {
                    // 선택된 장소의 주소를 location controller에 설정
                    _locationController.text =
                        '${newValue.name} (${newValue.address})';
                  }
                });
              },
              validator: (value) {
                if (_selectedVenue == null) {
                  return '장소를 선택해주세요';
                }
                return null;
              },
            ),
          ),
      ],
    );
  }

  Widget _buildGameDropdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '게임 선택',
          style: TextStyle(
            color: Color(0xFFEAEAEA),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<Game>>(
          stream: _firestoreService.getGames(),
          builder: (context, snapshot) {
            print('🎮 StreamBuilder state: ${snapshot.connectionState}');
            print('🎮 Has error: ${snapshot.hasError}');
            print('🎮 Error: ${snapshot.error}');
            print('🎮 Has data: ${snapshot.hasData}');
            print('🎮 Data length: ${snapshot.data?.length ?? 'null'}');

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF3C3C3C),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '게임 목록 로딩 중...',
                  style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 15),
                ),
              );
            }

            if (snapshot.hasError) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF3C3C3C),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '게임 목록을 불러올 수 없습니다',
                  style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 15),
                ),
              );
            }

            final games = snapshot.data ?? [];

            // 수정 모드에서 게임 데이터 로드 후 설정 (한 번만 실행)
            if (games.isNotEmpty && !_hasSetEditGame) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _setEditGameAfterLoad(games);
              });
            }

            if (games.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF3C3C3C),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '등록된 게임이 없습니다',
                  style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 15),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF3C3C3C),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonFormField<Game>(
                value: _selectedGame != null && games.contains(_selectedGame)
                    ? _selectedGame
                    : null,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                dropdownColor: const Color(0xFF3C3C3C),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                hint: const Text(
                  '게임을 선택하세요',
                  style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 15),
                ),
                items: games.map((Game game) {
                  return DropdownMenuItem<Game>(
                    value: game,
                    child: Text(
                      game.title,
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (Game? newValue) {
                  setState(() {
                    _selectedGame = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return '게임을 선택해주세요';
                  }
                  return null;
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // 표지 이미지 업로드 UI
  Widget _buildCoverImageUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '모임 표지 이미지',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF5F5F5),
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '모임을 대표할 이미지를 업로드해주세요. (선택사항)',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFFA0A0A0),
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _selectCoverImage,
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E2E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF444444), width: 1),
            ),
            child: _selectedCoverImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _selectedCoverImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImagePlaceholder();
                      },
                    ),
                  )
                : _buildImagePlaceholder(),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 48,
          color: Color(0xFF8C8C8C),
        ),
        SizedBox(height: 8),
        Text(
          '이미지 선택',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF8C8C8C),
            fontFamily: 'Pretendard',
          ),
        ),
      ],
    );
  }

  // 이미지 선택 후 Firebase Storage 업로드
  Future<void> _selectCoverImage() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return; // 사용자가 취소

      // 업로드 경로 지정
      final ext = picked.name.split('.').last;
      final path =
          'meeting_covers/${_currentUserId ?? 'anonymous'}/${DateTime.now().millisecondsSinceEpoch}.$ext';

      final ref = FirebaseStorage.instance.ref().child(path);

      // 업로드 진행 다이얼로그
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await ref.putFile(File(picked.path));

      final url = await ref.getDownloadURL();

      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        setState(() {
          _selectedCoverImage = url;
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }
      ToastUtils.showError(context, '이미지 업로드 실패: $e');
    }
  }

  // 미리보기 기능
  void _showPreview() {
    // 기본 유효성 검증
    if (_selectedGame == null) {
      ToastUtils.showError(context, '게임을 선택해주세요');
      return;
    }

    if (_selectedVenue == null) {
      ToastUtils.showError(context, '장소를 선택해주세요');
      return;
    }

    if (_startTime == null || _endTime == null) {
      ToastUtils.showError(context, '시작 시간과 종료 시간을 모두 선택해주세요');
      return;
    }

    // 시작 시간으로 DateTime 생성
    final startTimeParts = _startTime!.split(':');
    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      int.parse(startTimeParts[0]),
      int.parse(startTimeParts[1]),
    );

    // 임시 모임 객체 생성 (실제로 저장되지 않음)
    final previewMeeting = Meeting(
      id: 'preview_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : _selectedGame!.title,
      description: _benefitController.text.trim().isNotEmpty
          ? _benefitController.text.trim()
          : _selectedGame!.description,
      location: _locationController.text.trim(),
      scheduledDate: scheduledDateTime,
      maxParticipants: _selectedGame!.maxParticipants,
      currentParticipants: 0,
      hostId: _currentUserId ?? '',
      hostName: _userName ?? '게스트',
      price: _selectedGame!.price.toDouble(),
      participants: [],
      imageUrls: [_selectedGame!.imageUrl],
      coverImageUrl: _selectedCoverImage,
      requiredLevel: _selectedGame!.difficulty,
      gameId: _selectedGame!.id,
      venueId: _selectedVenue?.id,
      benefitDescription: _benefitController.text.trim(),
      tags: _selectedGame!.tags,
      difficulty: _selectedGame!.difficulty,
      rating: _selectedGame!.rating,
      reviewCount: _selectedGame!.reviewCount,
      minParticipants: _selectedGame!.minParticipants,
      status: 'preview', // 미리보기 상태 표시
    );

    // 실제 모임 상세 화면을 미리보기 모드로 호출
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeetingDetailScreen(
          meetingId: previewMeeting.id,
          isPreview: true,
          previewMeeting: previewMeeting,
          previewGame: _selectedGame,
          previewVenue: _selectedVenue,
        ),
      ),
    );
  }
}
