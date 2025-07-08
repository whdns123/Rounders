import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // 이미지 선택 모달 표시 (갤러리 전용)
  Future<File?> pickImage(BuildContext context) async {
    return await showModalBottomSheet<File?>(
      context: context,
      backgroundColor: const Color(0xFF2E2E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF8C8C8C),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '사진 선택',
              style: TextStyle(
                color: Color(0xFFF5F5F5),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Pretendard',
              ),
            ),
            const SizedBox(height: 20),
            // 임시로 갤러리만 제공 (카메라 권한 문제 해결)
            Center(
              child: _buildPickerOption(
                context,
                icon: Icons.photo_library,
                label: '갤러리에서 선택',
                onTap: () async {
                  final image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1024,
                    maxHeight: 1024,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    Navigator.pop(context, File(image.path));
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF444444),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFF5F5F5), size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFF5F5F5),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Firebase Storage에 이미지 업로드
  Future<String> uploadImage(File imageFile, String userId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage
          .ref()
          .child('review_images')
          .child(userId)
          .child(fileName);

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('이미지 업로드 실패: $e');
    }
  }

  // Firebase Storage에서 이미지 삭제
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // 이미지 삭제 실패해도 무시 (이미 삭제되었을 수도 있음)
      print('이미지 삭제 실패: $e');
    }
  }

  // 여러 이미지 업로드
  Future<List<String>> uploadImages(
    List<File> imageFiles,
    String userId,
  ) async {
    final List<String> uploadedUrls = [];

    for (final imageFile in imageFiles) {
      try {
        final url = await uploadImage(imageFile, userId);
        uploadedUrls.add(url);
      } catch (e) {
        // 개별 이미지 업로드 실패 시 건너뛰기
        print('개별 이미지 업로드 실패: $e');
      }
    }

    return uploadedUrls;
  }

  // 여러 이미지 삭제
  Future<void> deleteImages(List<String> imageUrls) async {
    for (final imageUrl in imageUrls) {
      await deleteImage(imageUrl);
    }
  }
}
