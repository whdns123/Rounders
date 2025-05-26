import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ImageUploadService {
  static final ImageUploadService _instance = ImageUploadService._internal();
  factory ImageUploadService() => _instance;
  ImageUploadService._internal();

  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 갤러리에서 단일 이미지 선택
  Future<File?> pickSingleImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('이미지 선택 실패: $e');
      return null;
    }
  }

  /// 갤러리에서 여러 이미지 선택
  Future<List<File>> pickMultipleImages({int maxImages = 5}) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      // 최대 이미지 개수 제한
      final selectedImages = images.take(maxImages).toList();

      return selectedImages.map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      print('이미지 선택 실패: $e');
      return [];
    }
  }

  /// 카메라로 사진 촬영
  Future<File?> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('사진 촬영 실패: $e');
      return null;
    }
  }

  /// Firebase Storage에 단일 이미지 업로드
  Future<String?> uploadSingleImage(File imageFile, String folderPath) async {
    try {
      // 파일명 생성 (현재 시간 + 원본 파일명)
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final String fullPath = '$folderPath/$fileName';

      // Firebase Storage에 업로드
      final Reference ref = _storage.ref().child(fullPath);
      final UploadTask uploadTask = ref.putFile(imageFile);

      // 업로드 진행 상황 모니터링 (선택사항)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('업로드 진행률: ${(progress * 100).toStringAsFixed(1)}%');
      });

      // 업로드 완료 대기
      final TaskSnapshot snapshot = await uploadTask;

      // 다운로드 URL 가져오기
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print('이미지 업로드 성공: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('이미지 업로드 실패: $e');
      return null;
    }
  }

  /// Firebase Storage에 여러 이미지 업로드
  Future<List<String>> uploadMultipleImages(
      List<File> imageFiles, String folderPath) async {
    List<String> uploadedUrls = [];

    for (File imageFile in imageFiles) {
      try {
        final String? url = await uploadSingleImage(imageFile, folderPath);
        if (url != null) {
          uploadedUrls.add(url);
        }
      } catch (e) {
        print('이미지 업로드 실패: $e');
        // 실패한 이미지는 건너뛰고 계속 진행
        continue;
      }
    }

    return uploadedUrls;
  }

  /// 프로필 이미지 업로드 (특별한 처리)
  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    return await uploadSingleImage(imageFile, 'profiles/$userId');
  }

  /// 모임 이미지 업로드
  Future<List<String>> uploadMeetingImages(
      List<File> imageFiles, String meetingId) async {
    return await uploadMultipleImages(imageFiles, 'meetings/$meetingId');
  }

  /// 라운지 포스트 이미지 업로드
  Future<List<String>> uploadPostImages(
      List<File> imageFiles, String postId) async {
    return await uploadMultipleImages(imageFiles, 'posts/$postId');
  }

  /// Firebase Storage에서 이미지 삭제
  Future<bool> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('이미지 삭제 성공: $imageUrl');
      return true;
    } catch (e) {
      print('이미지 삭제 실패: $e');
      return false;
    }
  }

  /// 여러 이미지 삭제
  Future<void> deleteMultipleImages(List<String> imageUrls) async {
    for (String url in imageUrls) {
      await deleteImage(url);
    }
  }
}
