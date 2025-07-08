import 'package:flutter/material.dart';

class ToastUtils {
  /// 피그마 디자인 기반 SnackBar를 표시합니다.
  ///
  /// [context]: BuildContext
  /// [message]: 표시할 메시지
  /// [isError]: 에러 메시지인지 여부 (기본값: false)
  /// [duration]: 표시 시간 (기본값: 2초)
  /// [showIcon]: 아이콘 표시 여부 (기본값: true)
  static void showToast(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 2),
    bool showIcon = true,
  }) {
    // 기존 SnackBar 제거
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          height: 52,
          child: Row(
            children: [
              if (showIcon) ...[
                Icon(
                  isError ? Icons.error_outline : Icons.info_outline,
                  color: const Color(0xFF2E2E2E),
                  size: 24,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF2E2E2E),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                    height: 1.43, // lineHeight 20px / fontSize 14px
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFEAEAEA),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80), // FAB와 겹치지 않도록
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        elevation: 0, // 피그마 디자인에는 그림자가 없음
        duration: duration,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      ),
    );
  }

  /// 성공 메시지를 표시합니다.
  static void showSuccess(BuildContext context, String message) {
    showToast(context, message, isError: false);
  }

  /// 에러 메시지를 표시합니다.
  static void showError(BuildContext context, String message) {
    showToast(context, message, isError: true);
  }

  /// 아이콘 없는 토스트를 표시합니다.
  static void showSimple(BuildContext context, String message) {
    showToast(context, message, showIcon: false);
  }

  /// 액션이 있는 토스트를 표시합니다 (현재는 피그마 디자인에 없지만 호환성을 위해 유지)
  static void showWithAction(
    BuildContext context,
    String message,
    String actionLabel,
    VoidCallback onActionPressed, {
    bool isError = false,
  }) {
    // 기존 SnackBar 제거
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          height: 52,
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.info_outline,
                color: const Color(0xFF2E2E2E),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF2E2E2E),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                    height: 1.43,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFEAEAEA),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        elevation: 0,
        duration: const Duration(seconds: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        action: SnackBarAction(
          label: actionLabel,
          onPressed: onActionPressed,
          textColor: const Color(0xFFF44336),
        ),
      ),
    );
  }
}
