import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meeting.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/image_upload_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  late FirestoreService _firestoreService;
  late AuthService _authService;
  late ImageUploadService _imageUploadService;

  List<File> _selectedImages = [];
  List<Meeting> _userMeetings = [];
  Meeting? _selectedMeeting;
  bool _isLoading = false;
  bool _isLoadingMeetings = true;

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
    _imageUploadService = ImageUploadService();
    _loadUserMeetings();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // 모든 모임들을 불러오기
  Future<void> _loadUserMeetings() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 호스트한 모임만 가져오기 (인덱스 문제 회피)
      _firestoreService.getMyHostedMeetings().listen((hostedMeetings) {
        if (mounted) {
          setState(() {
            _userMeetings = hostedMeetings;

            // 선택된 미팅이 더 이상 존재하지 않으면 null로 초기화
            if (_selectedMeeting != null &&
                !_userMeetings
                    .any((meeting) => meeting.id == _selectedMeeting!.id)) {
              _selectedMeeting = null;
            }

            _isLoadingMeetings = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedMeeting = null; // 에러 발생 시에도 null로 초기화
          _isLoadingMeetings = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('모임 목록 로드 실패: $e')),
        );
      }
    }
  }

  // 이미지 선택
  Future<void> _pickImages() async {
    try {
      print('🖼️ 이미지 선택 시작...');

      if (_imageUploadService == null) {
        throw Exception('ImageUploadService가 초기화되지 않았습니다.');
      }

      final images = await _imageUploadService.pickMultipleImages(maxImages: 5);

      print('📸 선택된 이미지 수: ${images.length}');

      if (mounted) {
        setState(() {
          _selectedImages = images;
        });

        if (images.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${images.length}장의 이미지가 선택되었습니다.')),
          );
        }
      }
    } catch (e) {
      print('❌ 이미지 선택 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택 실패: $e')),
        );
      }
    }
  }

  // 게시글 작성
  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMeeting == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모임을 선택해주세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 이미지 업로드
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        final postId = DateTime.now().millisecondsSinceEpoch.toString();
        imageUrls =
            await _imageUploadService.uploadPostImages(_selectedImages, postId);
      }

      // 게시글 생성
      await _firestoreService.createPost(
        eventId: _selectedMeeting!.id,
        imageUrls: imageUrls,
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시글이 작성되었습니다!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시글 작성 실패: $e')),
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
        title: const Text('글 작성', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4A55A2),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPost,
            child: Text(
              '게시',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoadingMeetings
          ? const Center(child: CircularProgressIndicator())
          : _userMeetings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        '작성할 수 있는 모임이 없습니다.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '호스팅한 모임에 대해 글을 작성할 수 있어요.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 모임 선택 섹션
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '모임 선택',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<Meeting>(
                              value: _userMeetings.contains(_selectedMeeting)
                                  ? _selectedMeeting
                                  : null,
                              isExpanded: true,
                              decoration: InputDecoration(
                                hintText: '글을 작성할 모임을 선택하세요',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 16),
                              ),
                              items: _userMeetings.map((meeting) {
                                return DropdownMenuItem<Meeting>(
                                  value: meeting,
                                  child: Text(
                                    '${meeting.title} - ${meeting.location}',
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                );
                              }).toList(),
                              onChanged: (Meeting? meeting) {
                                setState(() {
                                  _selectedMeeting = meeting;
                                });
                              },
                              validator: (value) {
                                if (value == null) return '모임을 선택해주세요';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 이미지 선택 섹션
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '사진 추가',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed: () async {
                                        try {
                                          final image =
                                              await _imageUploadService
                                                  .pickSingleImage();
                                          if (image != null) {
                                            setState(() {
                                              _selectedImages = [image];
                                            });
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      '1장의 이미지가 선택되었습니다.')),
                                            );
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text('이미지 선택 실패: $e')),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.photo),
                                      label: const Text('1장'),
                                    ),
                                    TextButton.icon(
                                      onPressed: _pickImages,
                                      icon:
                                          const Icon(Icons.add_photo_alternate),
                                      label: const Text('여러장'),
                                    ),
                                    TextButton.icon(
                                      onPressed: () async {
                                        try {
                                          final image =
                                              await _imageUploadService
                                                  .takePhoto();
                                          if (image != null) {
                                            setState(() {
                                              _selectedImages = [image];
                                            });
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content:
                                                      Text('사진이 촬영되었습니다.')),
                                            );
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text('사진 촬영 실패: $e')),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.camera_alt),
                                      label: const Text('카메라'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_selectedImages.isEmpty)
                              Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.grey.shade300,
                                      style: BorderStyle.solid),
                                ),
                                child: InkWell(
                                  onTap: _pickImages,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate,
                                            size: 48,
                                            color: Colors.grey.shade500),
                                        const SizedBox(height: 8),
                                        Text(
                                          '모임 사진을 추가해보세요',
                                          style: TextStyle(
                                              color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                height: 120,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _selectedImages.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      width: 120,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                      ),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.file(
                                              _selectedImages[index],
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _selectedImages
                                                      .removeAt(index);
                                                });
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.6),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 글 내용 섹션
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '글 내용',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 6,
                              decoration: InputDecoration(
                                hintText: '모임에 대한 생각이나 이야기를 공유해보세요!',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return '글 내용을 입력해주세요';
                                }
                                if (value.trim().length < 10) {
                                  return '글은 10자 이상 입력해주세요';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 작성 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createPost,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A55A2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                                  '글 게시하기',
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
