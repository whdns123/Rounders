import 'package:flutter/material.dart';
import '../models/user_tier.dart';

class CardTierWidget extends StatelessWidget {
  final UserTier tier;
  final bool showDetails;
  final double cardWidth;
  final double cardHeight;

  const CardTierWidget({
    super.key,
    required this.tier,
    this.showDetails = true,
    this.cardWidth = 180,
    this.cardHeight = 250,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 카드 표현
        Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                // 배경 카드 이미지 (실제로는 assets/images/cards/에 이미지 추가 필요)
                // Image.asset(
                //   tier.tierImagePath,
                //   fit: BoxFit.cover,
                //   width: double.infinity,
                //   height: double.infinity,
                // ),

                // 임시 카드 디자인
                _buildCardDesign(),

                // 카드 테두리
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black.withOpacity(0.05),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (showDetails) ...[
          const SizedBox(height: 16),

          // 티어 이름
          Text(
            tier.tierName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: tier.tierColor,
            ),
          ),

          const SizedBox(height: 8),

          // 티어 설명
          Text(
            tier.tierDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 12),

          // 점수 및 승률
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatItem(
                'Rating',
                tier.eloRating.toString(),
                Icons.star,
              ),
              const SizedBox(width: 20),
              _buildStatItem(
                '승률',
                '${tier.winRate.toStringAsFixed(1)}%',
                Icons.emoji_events,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 다음 티어 정보
          if (tier.rank != CardRank.ace || tier.suit != CardSuit.spades)
            Column(
              children: [
                Text(
                  '다음 티어: ${tier.nextTier.tierName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '필요 점수: ${tier.pointsToNextTier()} 점',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
        ],
      ],
    );
  }

  // 통계 항목 위젯
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.indigo),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // 카드 디자인 (이미지 없을 때 사용하는 임시 디자인)
  Widget _buildCardDesign() {
    String rankText = _getRankDisplayText(tier.rank);
    String suitSymbol = _getSuitSymbol(tier.suit);
    Color suitColor = _getSuitColor(tier.suit);

    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          children: [
            // 좌상단 숫자와 무늬
            Positioned(
              top: 5,
              left: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    rankText,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: suitColor,
                    ),
                  ),
                  Text(
                    suitSymbol,
                    style: TextStyle(
                      fontSize: 20,
                      color: suitColor,
                    ),
                  ),
                ],
              ),
            ),

            // 우하단 숫자와 무늬 (거꾸로)
            Positioned(
              bottom: 5,
              right: 5,
              child: Transform.rotate(
                angle: 3.14159, // 180도
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      rankText,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: suitColor,
                      ),
                    ),
                    Text(
                      suitSymbol,
                      style: TextStyle(
                        fontSize: 20,
                        color: suitColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 가운데 큰 무늬
            Center(
              child: Text(
                suitSymbol,
                style: TextStyle(
                  fontSize: 80,
                  color: suitColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 카드 랭크 표시 텍스트
  String _getRankDisplayText(CardRank rank) {
    switch (rank) {
      case CardRank.two:
        return '2';
      case CardRank.three:
        return '3';
      case CardRank.four:
        return '4';
      case CardRank.five:
        return '5';
      case CardRank.six:
        return '6';
      case CardRank.seven:
        return '7';
      case CardRank.eight:
        return '8';
      case CardRank.nine:
        return '9';
      case CardRank.ten:
        return '10';
      case CardRank.jack:
        return 'J';
      case CardRank.queen:
        return 'Q';
      case CardRank.king:
        return 'K';
      case CardRank.ace:
        return 'A';
    }
  }

  // 무늬 기호
  String _getSuitSymbol(CardSuit suit) {
    switch (suit) {
      case CardSuit.clubs:
        return '♣';
      case CardSuit.diamonds:
        return '♦';
      case CardSuit.hearts:
        return '♥';
      case CardSuit.spades:
        return '♠';
    }
  }

  // 무늬 색상
  Color _getSuitColor(CardSuit suit) {
    switch (suit) {
      case CardSuit.clubs:
        return Colors.black;
      case CardSuit.spades:
        return Colors.black;
      case CardSuit.diamonds:
        return Colors.red;
      case CardSuit.hearts:
        return Colors.red;
    }
  }
}
