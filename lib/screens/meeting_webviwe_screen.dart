import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'meeting_payment_screen.dart';

class MeetingWebViewScreen extends StatefulWidget {
  final String url;

  const MeetingWebViewScreen({super.key, required this.url});

  @override
  State<MeetingWebViewScreen> createState() => _MeetingWebViewScreenState();
}

class _MeetingWebViewScreenState extends State<MeetingWebViewScreen> {
  late final WebViewController _controller;
  String _meetingTitle = '두뇌 서바이벌: 라운더스 시즌1';
  String _meetingTime = '서울역 • 오늘 오후 7시';
  int _meetingPrice = 25000;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('🚀 WebView URL: ${widget.url}');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            print('📥 페이지 시작: $url');
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (url) {
            print('✅ 페이지 완료: $url');
            setState(() {
              _isLoading = false;

              // 웹페이지에서 모임 정보 추출 (실제로는 웹페이지에서 데이터를 가져와야 함)
              // JavaScriptChannel 또는 evaluateJavascript를 사용할 수 있음
              if (url.contains('roundus')) {
                _extractMeetingInfo();
              }
            });
          },
          onWebResourceError: (error) => print('❌ 로딩 오류: ${error.description}'),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  // 모임 정보 추출 (실제로는 웹페이지에서 추출해야 함)
  void _extractMeetingInfo() {
    // 이 메서드는 실제로는 WebViewController의 runJavaScriptReturningResult 등을 사용하여
    // 웹페이지에서 모임 정보를 추출해야 합니다.
    // 지금은 예시로 고정 값을 사용합니다.

    // URL 경로에 따라 다른 모임 정보 설정 (데모용)
    if (widget.url.contains('1')) {
      _meetingTitle = '두뇌 서바이벌: 라운더스 시즌1';
      _meetingTime = '서울역 • 오늘 오후 7시';
      _meetingPrice = 25000;
    } else if (widget.url.contains('2')) {
      _meetingTitle = '팀 대항 브레인 매치';
      _meetingTime = '대전역 • 내일 오후 6시';
      _meetingPrice = 30000;
    } else {
      _meetingTitle = '심리 추리 게임의 밤';
      _meetingTime = '동탄역 • 금요일 오후 8시';
      _meetingPrice = 20000;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('모임 상세보기'),
        backgroundColor: Colors.indigo,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MeetingPaymentScreen(
                    meetingTitle: _meetingTitle,
                    meetingTime: _meetingTime,
                    price: _meetingPrice,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('신청하기', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }
}
