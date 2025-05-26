


import 'package:flutter/material.dart';
import 'meeting_card.dart';

class MeetingCardSlider extends StatefulWidget {
  const MeetingCardSlider({super.key});

  @override
  State<MeetingCardSlider> createState() => _MeetingCardSliderState();
}

class _MeetingCardSliderState extends State<MeetingCardSlider> {
  late PageController _pageController;
  final List<Map<String, String>> _meetings = [
    {
      'image': 'assets/images/1.jpg',
      'title': '두뇌 서바이벌: 라운더스 시즌1',
      'subtitle': '서울역 • 오늘 오후 7시'
    },
    {
      'image': 'assets/images/2.jpg',
      'title': '팀 대항 브레인 매치',
      'subtitle': '대전역 • 내일 오후 6시'
    },
    {
      'image': 'assets/images/3.jpg',
      'title': '심리 추리 게임의 밤',
      'subtitle': '동탄역 • 금요일 오후 8시'
    },
    {
      'image': 'assets/images/4.jpg',
      'title': '속도와 전략의 대결',
      'subtitle': '수원역 • 토요일 오후 5시'
    },
    {
      'image': 'assets/images/5.jpg',
      'title': 'AI 추론 마스터 챌린지',
      'subtitle': '부산역 • 일요일 오후 2시'
    },
    {
      'image': 'assets/images/6.jpg',
      'title': '논리와 심리의 밤',
      'subtitle': '광주역 • 다음주 금요일 오후 9시'
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.75);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.68,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _meetings.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value = 1.0;
              if (_pageController.position.haveDimensions) {
                value = _pageController.page! - index;
                value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
              }
              return Align(
                alignment: Alignment.topCenter,
                child: Transform.scale(
                  scale: Curves.easeOut.transform(value),
                  child: Opacity(
                    opacity: value,
                    child: MeetingCard(
                      imagePath: _meetings[index]['image']!,
                      title: _meetings[index]['title']!,
                      subtitle: _meetings[index]['subtitle']!,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}