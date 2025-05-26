import 'package:flutter/material.dart';

// 트럼프 카드 티어 시스템
enum CardRank {
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
  ace
}

enum CardSuit { clubs, diamonds, hearts, spades }

class UserTier {
  final CardRank rank;
  final CardSuit suit;
  final int eloRating; // 점수 시스템 (ELO 레이팅)
  final int gamesPlayed; // 총 참여 게임 수
  final int gamesWon; // 승리한 게임 수

  UserTier({
    required this.rank,
    required this.suit,
    required this.eloRating,
    required this.gamesPlayed,
    required this.gamesWon,
  });

  // 티어명 생성
  String get tierName {
    String rankName = _getRankName(rank);
    String suitName = _getSuitName(suit);
    return '$rankName of $suitName';
  }

  // 티어 이미지 경로
  String get tierImagePath {
    String rankCode = _getRankCode(rank);
    String suitCode = _getSuitCode(suit);
    return 'assets/images/cards/${rankCode}_$suitCode.png';
  }

  // 승률 계산
  double get winRate {
    if (gamesPlayed == 0) return 0;
    return (gamesWon / gamesPlayed) * 100;
  }

  // 랭크명 가져오기
  String _getRankName(CardRank rank) {
    switch (rank) {
      case CardRank.two:
        return 'Two';
      case CardRank.three:
        return 'Three';
      case CardRank.four:
        return 'Four';
      case CardRank.five:
        return 'Five';
      case CardRank.six:
        return 'Six';
      case CardRank.seven:
        return 'Seven';
      case CardRank.eight:
        return 'Eight';
      case CardRank.nine:
        return 'Nine';
      case CardRank.ten:
        return 'Ten';
      case CardRank.jack:
        return 'Jack';
      case CardRank.queen:
        return 'Queen';
      case CardRank.king:
        return 'King';
      case CardRank.ace:
        return 'Ace';
    }
  }

  // 랭크 코드 가져오기
  String _getRankCode(CardRank rank) {
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

  // 슈트명 가져오기
  String _getSuitName(CardSuit suit) {
    switch (suit) {
      case CardSuit.clubs:
        return 'Clubs';
      case CardSuit.diamonds:
        return 'Diamonds';
      case CardSuit.hearts:
        return 'Hearts';
      case CardSuit.spades:
        return 'Spades';
    }
  }

  // 슈트 코드 가져오기
  String _getSuitCode(CardSuit suit) {
    switch (suit) {
      case CardSuit.clubs:
        return 'C';
      case CardSuit.diamonds:
        return 'D';
      case CardSuit.hearts:
        return 'H';
      case CardSuit.spades:
        return 'S';
    }
  }

  // 티어별 색상 가져오기
  Color get tierColor {
    switch (suit) {
      case CardSuit.clubs:
        return Colors.black87;
      case CardSuit.diamonds:
        return Colors.red;
      case CardSuit.hearts:
        return Colors.red.shade800;
      case CardSuit.spades:
        return Colors.indigo.shade900;
    }
  }

  // 티어 랭크 설명
  String get tierDescription {
    if (rank == CardRank.ace && suit == CardSuit.spades) {
      return '최고 등급! 라운더스 마스터에 도달했습니다.';
    }

    String description = '';
    if (rank.index < 4) {
      description = '초보 플레이어, 계속 도전하세요!';
    } else if (rank.index < 8) {
      description = '중급 플레이어, 점점 실력이 늘고 있습니다!';
    } else if (rank.index < 11) {
      description = '고급 플레이어, 당신은 이미 뛰어난 실력자입니다!';
    } else {
      description = '전문가 플레이어, 정상급 실력자입니다!';
    }

    return description;
  }

  // 다음 티어 계산
  UserTier get nextTier {
    if (rank == CardRank.ace && suit == CardSuit.spades) {
      // 이미 최고 등급
      return this;
    }

    late CardRank nextRank;
    late CardSuit nextSuit;

    if (rank == CardRank.ace) {
      nextRank = CardRank.two;
      nextSuit = CardSuit.values[suit.index + 1];
    } else {
      nextRank = CardRank.values[rank.index + 1];
      nextSuit = suit;
    }

    return UserTier(
      rank: nextRank,
      suit: nextSuit,
      eloRating: eloRating + 100,
      gamesPlayed: gamesPlayed,
      gamesWon: gamesWon,
    );
  }

  // 필요 점수 계산
  int pointsToNextTier() {
    return (nextTier.eloRating - eloRating);
  }

  // 랭크에 따른 점수 계산
  static int calculateEloFromTier(CardRank rank, CardSuit suit) {
    int baseElo = 1000;
    int rankBonus = rank.index * 100;
    int suitBonus = suit.index * 300;

    return baseElo + rankBonus + suitBonus;
  }

  // 점수에 따른 티어 계산
  static UserTier tierFromElo(int elo, int gamesPlayed, int gamesWon) {
    int baseElo = 1000;
    int suitIndex = (elo - baseElo) ~/ 1300;
    int remainingElo = (elo - baseElo) % 1300;
    int rankIndex = remainingElo ~/ 100;

    // 범위 체크
    suitIndex = suitIndex.clamp(0, CardSuit.values.length - 1);
    rankIndex = rankIndex.clamp(0, CardRank.values.length - 1);

    return UserTier(
      rank: CardRank.values[rankIndex],
      suit: CardSuit.values[suitIndex],
      eloRating: elo,
      gamesPlayed: gamesPlayed,
      gamesWon: gamesWon,
    );
  }
}
