class Game {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String prologue;
  final String imageUrl; // 대표 이미지 (기존 호환성 유지)
  final List<String> images; // 게임 상세 이미지들 (4개)
  final List<String> timeTable;
  final List<String> benefits;
  final List<String> targetAudience;
  final int minParticipants;
  final int maxParticipants;
  final double price;
  final String difficulty;
  final List<String> tags;
  final double rating;
  final int reviewCount;

  Game({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.prologue,
    required this.imageUrl,
    this.images = const [], // 기본값으로 빈 배열
    required this.timeTable,
    required this.benefits,
    required this.targetAudience,
    required this.minParticipants,
    required this.maxParticipants,
    required this.price,
    required this.difficulty,
    required this.tags,
    required this.rating,
    required this.reviewCount,
  });

  factory Game.fromMap(Map<String, dynamic> map) {
    try {
      return Game(
        id: map['id'] ?? '',
        title: map['title'] ?? '제목 없음',
        subtitle: map['subtitle'] ?? '',
        description: map['description'] ?? '',
        prologue: map['prologue'] ?? '',
        imageUrl: map['imageUrl'] ?? map['representativeImage'] ?? '',
        images: _extractImages(map),
        timeTable: _parseStringList(map['timeTable'] ?? map['rules']),
        benefits: _parseStringList(map['benefits'] ?? ['게임 참여 혜택']),
        targetAudience: _parseStringList(map['targetAudience'] ?? ['모든 참가자']),
        minParticipants: _parseInt(map['minParticipants'] ?? map['minPlayers']),
        maxParticipants: _parseInt(map['maxParticipants'] ?? map['maxPlayers']),
        price: _parseDouble(map['price'] ?? 15000), // 기본값 설정
        difficulty: _parseDifficulty(map['difficulty']),
        tags: _parseStringList(map['tags']),
        rating: _parseDouble(map['rating']),
        reviewCount: _parseInt(map['reviewCount']),
      );
    } catch (e) {
      print('🚨 Game.fromMap 오류: $e');
      print('🚨 문제 데이터: $map');
      rethrow;
    }
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static String _parseDifficulty(dynamic value) {
    if (value == null) return '난이도 정보 없음';
    if (value is String) return value;
    if (value is int) {
      switch (value) {
        case 1:
          return '난이도 하';
        case 2:
          return '난이도 중';
        case 3:
          return '난이도 상';
        default:
          return '난이도 정보 없음';
      }
    }
    return value.toString();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'prologue': prologue,
      'imageUrl': imageUrl,
      'images': images,
      'timeTable': timeTable,
      'benefits': benefits,
      'targetAudience': targetAudience,
      'minParticipants': minParticipants,
      'maxParticipants': maxParticipants,
      'price': price,
      'difficulty': difficulty,
      'tags': tags,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Game && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Firestore 문서에서 이미지 리스트 추출
  ///
  /// 1) `images` 배열이 존재하면 그대로 사용
  /// 2) 배열이 없거나 비어 있으면, key 이름에 `image` 가 포함된 String 값들을 수집해
  ///    최대 10개까지만 반환 (대표 imageUrl 은 제외)
  static List<String> _extractImages(Map<String, dynamic> map) {
    // 1) 배열 형태 우선
    final rawImages = map['images'];
    final parsed = _parseStringList(rawImages);
    if (parsed.isNotEmpty) return parsed;

    // 2) 개별 필드 스캔
    final List<String> found = [];
    map.forEach((key, value) {
      if (value is String && value.isNotEmpty) {
        final lowerKey = key.toLowerCase();
        if (lowerKey.contains('image') || lowerKey.contains('img')) {
          found.add(value);
        }
      }
    });

    // 대표 imageUrl 과 중복 제거
    final repImage = map['imageUrl'] ?? map['representativeImage'];
    if (repImage is String) {
      found.removeWhere((url) => url == repImage);
    }

    // 개수 제한 및 반환
    return found.take(10).toList();
  }
}
