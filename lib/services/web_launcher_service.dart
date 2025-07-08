import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class WebLauncherService {
  // 관리자 웹사이트 URL들 (실제 배포 시 실제 URL로 변경 필요)
  static const String _customerServiceUrl =
      'https://rounders-admin.com/customer-service';
  static const String _partnershipUrl =
      'https://rounders-admin.com/partnership';
  static const String _hostSupportUrl =
      'https://rounders-admin.com/host-support';

  // 고객센터 문의 페이지 열기
  static Future<void> openCustomerService(BuildContext context) async {
    await _launchUrl(context, _customerServiceUrl, '고객센터 문의');
  }

  // 제휴 및 호스트 지원 페이지 열기
  static Future<void> openPartnership(BuildContext context) async {
    await _launchUrl(context, _partnershipUrl, '제휴 및 호스트 지원');
  }

  // 호스트 지원 페이지 열기
  static Future<void> openHostSupport(BuildContext context) async {
    await _launchUrl(context, _hostSupportUrl, '호스트 지원');
  }

  // 일반 URL 열기 (개인정보 처리방침 등)
  static Future<void> openUrl(
    BuildContext context,
    String url, {
    String? pageName,
  }) async {
    await _launchUrl(context, url, pageName ?? 'External Link');
  }

  // 공통 URL 실행 메서드
  static Future<void> _launchUrl(
    BuildContext context,
    String urlString,
    String pageName,
  ) async {
    try {
      final Uri url = Uri.parse(urlString);

      // URL을 열 수 있는지 확인
      if (!await launchUrl(
        url,
        mode: LaunchMode.externalApplication, // 외부 브라우저에서 열기
      )) {
        // URL을 열 수 없는 경우 대체 동작
        await _showFallbackDialog(context, pageName, urlString);
      }
    } catch (e) {
      // 에러 발생 시 대체 동작
      await _showErrorDialog(context, pageName, e.toString());
    }
  }

  // URL을 열 수 없을 때 대체 다이얼로그
  static Future<void> _showFallbackDialog(
    BuildContext context,
    String pageName,
    String url,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E2E2E),
          title: Text(
            pageName,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '브라우저를 열 수 없습니다.\n다음 URL을 수동으로 복사해서 사용해주세요:',
                style: TextStyle(
                  color: Color(0xFFEAEAEA),
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  url,
                  style: const TextStyle(
                    color: Color(0xFFF44336),
                    fontFamily: 'Pretendard',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                '확인',
                style: TextStyle(
                  color: Color(0xFFF44336),
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 에러 발생 시 에러 다이얼로그
  static Future<void> _showErrorDialog(
    BuildContext context,
    String pageName,
    String error,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E2E2E),
          title: const Text(
            '오류',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            '$pageName 페이지를 열 수 없습니다.\n잠시 후 다시 시도해주세요.',
            style: const TextStyle(
              color: Color(0xFFEAEAEA),
              fontFamily: 'Pretendard',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                '확인',
                style: TextStyle(
                  color: Color(0xFFF44336),
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 개발/테스트용 - 실제 URL 대신 정보 다이얼로그 표시
  static Future<void> showDevelopmentDialog(
    BuildContext context,
    String pageName,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E2E2E),
          title: Text(
            pageName,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            '이 기능은 관리자 웹사이트 연동 후 사용 가능합니다.\n\n개발이 완료되면 외부 웹사이트로 이동하게 됩니다.',
            style: TextStyle(
              color: Color(0xFFEAEAEA),
              fontFamily: 'Pretendard',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                '확인',
                style: TextStyle(
                  color: Color(0xFFF44336),
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
