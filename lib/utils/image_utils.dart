import 'package:flutter/material.dart';
import '../models/meeting.dart';

class ImageUtils {
  /// 모임의 표지 이미지 URL을 가져옵니다
  /// 우선순위: coverImageUrl -> imageUrl -> 기본 이미지
  static String? getMeetingCoverImageUrl(Meeting meeting) {
    if (meeting.coverImageUrl?.isNotEmpty == true) {
      return meeting.coverImageUrl;
    }
    if (meeting.imageUrl?.isNotEmpty == true) {
      return meeting.imageUrl;
    }
    return null;
  }

  /// 모임 표지 이미지 위젯을 생성합니다
  static Widget buildMeetingCoverImage({
    required Meeting meeting,
    required double width,
    required double height,
    BorderRadius? borderRadius,
    Widget? placeholder,
  }) {
    final imageUrl = getMeetingCoverImageUrl(meeting);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: borderRadius ?? BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: imageUrl != null
          ? ClipRRect(
              borderRadius: borderRadius ?? BorderRadius.circular(4),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultPlaceholder();
                },
              ),
            )
          : (placeholder ?? _buildDefaultPlaceholder()),
    );
  }

  /// 기본 플레이스홀더 이미지
  static Widget _buildDefaultPlaceholder() {
    return const Icon(Icons.event, color: Color(0xFF8C8C8C), size: 32);
  }
}
