import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/meeting.dart';
import '../models/game.dart';
import '../models/venue.dart';

class HostCreateMeetingScreen extends StatefulWidget {
  const HostCreateMeetingScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
    _currentUserId = _authService.currentUser?.uid;
    _loadUserName();
    _loadAllVenues(); // 처음부터 모든 장소 로드
    _ensureGamesExist();
  }

  Future<void> _ensureGamesExist() async {
    try {
      // 게임 데이터가 있는지 확인
      final games = await _firestoreService.getGames().first;
      if (games.isEmpty) {
        print('게임 데이터가 없어서 샘플 게임을 추가합니다...');
        await _firestoreService.addSampleGames();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('장소 데이터를 불러오는 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
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
            colorScheme: const ColorScheme.dark(primary: Color(0xFF111111)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final timeSlots = _generateTimeSlots();
    final currentTime = isStart ? _startTime : _endTime;

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
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: timeSlots.length,
                  itemBuilder: (context, index) {
                    final time = timeSlots[index];
                    final isSelected = time == currentTime;

                    return ListTile(
                      title: Text(
                        time,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFFF44336)
                              : Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: const Color(0xFF3C3C3C),
                      onTap: () {
                        setState(() {
                          if (isStart) {
                            _startTime = time;
                          } else {
                            _endTime = time;
                          }
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitMeeting() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('시작 시간과 종료 시간을 모두 선택해주세요')));
      return;
    }

    if (_selectedGame == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('게임을 선택해주세요')));
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

      // 모임 데이터 생성 (게임 정보 포함)
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

      // 추가로 시간 정보를 별도 필드로 저장하고 싶다면:
      // await _firestoreService.updateMeetingTimes(meetingId, _startTime!, _endTime!);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('모임이 성공적으로 생성되었습니다!')));

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('모임 생성 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: const Text('모임 만들기', style: TextStyle(color: Colors.white)),
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
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitMeeting,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
                    '만들기',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
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

  Widget _buildTimeButtons(BuildContext context) {
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
              value: _selectedVenue,
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
                value:
                    _selectedGame != null &&
                        games.any((g) => g.id == _selectedGame!.id)
                    ? games.firstWhere((g) => g.id == _selectedGame!.id)
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('이미지 업로드 실패: $e')));
    }
  }
}
