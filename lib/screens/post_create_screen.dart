import 'package:flutter/material.dart';
import '../models/post.dart';
import '../main.dart';

class PostCreateScreen extends StatefulWidget {
  const PostCreateScreen({super.key});

  @override
  State<PostCreateScreen> createState() => _PostCreateScreenState();
}

class _PostCreateScreenState extends State<PostCreateScreen> {
  final _captionController = TextEditingController();
  String _selectedImage = 'assets/images/1.jpg'; // 기본 이미지

  final List<String> _imageOptions = [
    'assets/images/1.jpg',
    'assets/images/2.jpg',
    'assets/images/3.jpg',
    'assets/images/4.jpg',
    'assets/images/badge.png',
  ];

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시물 작성'),
        backgroundColor: Colors.indigo,
        actions: [
          TextButton(
            onPressed: _submitPost,
            child: const Text(
              '게시',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 사용자 정보
            Row(
              children: [
                const CircleAvatar(
                  backgroundImage: AssetImage('assets/images/badge.png'),
                  radius: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  authService.currentUser?.displayName ?? '사용자',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 이미지 선택
            const Text(
              '이미지 선택',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _imageOptions.length,
                itemBuilder: (context, index) {
                  final image = _imageOptions[index];
                  final isSelected = _selectedImage == image;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedImage = image;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: isSelected
                            ? Border.all(color: Colors.indigo, width: 3)
                            : null,
                      ),
                      child: Image.asset(
                        image,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // 선택된 이미지 미리보기
            Center(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: Image.asset(_selectedImage, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 16),

            // 캡션 입력
            TextField(
              controller: _captionController,
              decoration: const InputDecoration(
                hintText: '문구 입력...',
                border: InputBorder.none,
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }

  void _submitPost() {
    if (_captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('내용을 입력해주세요')));
      return;
    }

    // 게시물 생성
    final post = Post.create(
      username: authService.currentUser?.displayName ?? '사용자',
      profileUrl: 'assets/images/badge.png',
      imageUrl: _selectedImage,
      caption: _captionController.text.trim(),
    );

    // 이전 화면으로 결과 전달
    Navigator.pop(context, post);
  }
}
