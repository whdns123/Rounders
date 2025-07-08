import 'package:flutter/material.dart';

/// 피그마 디자인 기반 공통 모달 컴포넌트
class CommonModal extends StatelessWidget {
  final String title;
  final String description;
  final String? primaryButtonText;
  final String? secondaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final bool isPrimaryDestructive;
  final bool showCloseButton;

  const CommonModal({
    super.key,
    required this.title,
    required this.description,
    this.primaryButtonText,
    this.secondaryButtonText,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.isPrimaryDestructive = true,
    this.showCloseButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: 280,
          decoration: BoxDecoration(
            color: const Color(0xFF2E2E2E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 제목
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Color(0xFFFFFFFF),
                    height: 1.4, // lineHeight 28px / fontSize 20px
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // 설명
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFFFFFFFF),
                    height: 1.43, // lineHeight 20px / fontSize 14px
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 36),

                // 버튼 영역
                if (primaryButtonText != null || secondaryButtonText != null)
                  Row(
                    children: [
                      // 세컨더리 버튼 (닫기)
                      if (secondaryButtonText != null) ...[
                        Expanded(child: _buildSecondaryButton()),
                        if (primaryButtonText != null)
                          const SizedBox(width: 12),
                      ],

                      // 프라이머리 버튼 (확인)
                      if (primaryButtonText != null)
                        Expanded(child: _buildPrimaryButton()),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton() {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onSecondaryPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF8C8C8C), width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          backgroundColor: Colors.transparent,
        ),
        child: Text(
          secondaryButtonText!,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFFF5F5F5),
            height: 1.5, // lineHeight 24px / fontSize 16px
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onPrimaryPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF44336),
          foregroundColor: const Color(0xFFF5F5F5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          elevation: 0,
        ),
        child: Text(
          primaryButtonText!,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            height: 1.5, // lineHeight 24px / fontSize 16px
          ),
        ),
      ),
    );
  }
}

/// 공통 모달 표시 유틸리티
class ModalUtils {
  /// 확인/취소 모달 표시
  static Future<bool?> showConfirmModal({
    required BuildContext context,
    required String title,
    required String description,
    String confirmText = '확인',
    String cancelText = '취소',
    bool isDestructive = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0x70000000), // 70% 투명도
      builder: (context) => CommonModal(
        title: title,
        description: description,
        primaryButtonText: confirmText,
        secondaryButtonText: cancelText,
        onPrimaryPressed: () => Navigator.of(context).pop(true),
        onSecondaryPressed: () => Navigator.of(context).pop(false),
        isPrimaryDestructive: isDestructive,
      ),
    );
  }

  /// 정보 표시 모달 (확인 버튼만)
  static Future<void> showInfoModal({
    required BuildContext context,
    required String title,
    required String description,
    String buttonText = '확인',
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0x70000000), // 70% 투명도
      builder: (context) => CommonModal(
        title: title,
        description: description,
        primaryButtonText: buttonText,
        onPrimaryPressed: () => Navigator.of(context).pop(),
        isPrimaryDestructive: false,
      ),
    );
  }

  /// 에러 모달 표시
  static Future<void> showErrorModal({
    required BuildContext context,
    required String title,
    required String description,
    String buttonText = '확인',
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0x70000000), // 70% 투명도
      builder: (context) => CommonModal(
        title: title,
        description: description,
        primaryButtonText: buttonText,
        onPrimaryPressed: () => Navigator.of(context).pop(),
        isPrimaryDestructive: true,
      ),
    );
  }

  /// 로딩 모달 표시
  static void showLoadingModal({
    required BuildContext context,
    String message = '처리 중입니다...',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0x70000000), // 70% 투명도
      builder: (context) => Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E2E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFFF44336),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFFFFFFFF),
                    height: 1.43,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
