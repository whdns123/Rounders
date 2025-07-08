class Game {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String prologue;
  final String imageUrl; // 대표 이미지 (gameImage와 동일할 수 있음)
  final String gameImage; // 게임 대표 이미지
  final String benefitImage; // 혜택 이미지
  final String meetingPlayImage; // 모임 중 플레이 사진
  final String roundersPlayImage; // 라운더스 스타일 게임 이미지
  final List<String> images; // 모든 이미지들을 배열로 (호환성)
  final List<String> rules; // 게임 룰 (기존 timeTable)
  final List<String> materials; // 준비물
  final List<String> tags;
  final int minPlayers; // 실제 필드명
  final int maxPlayers; // 실제 필드명
  final double participationFee; // 실제 필드명 (기존 price)
  final String difficulty;
  final String gameType; // 게임 타입
  final int estimatedDuration; // 예상 시간 (분)
  final bool isActive; // 활성 상태

  // 호환성을 위한 기존 필드들 (deprecated)
  @deprecated
  List<String> get timeTable => rules;
  @deprecated
  List<String> get benefits => []; // 실제 Firestore에는 없음
  @deprecated
  List<String> get targetAudience => []; // 실제 Firestore에는 없음
  @deprecated
  int get minParticipants => minPlayers;
  @deprecated
  int get maxParticipants => maxPlayers;
  @deprecated
  double get price => participationFee;
  @deprecated
  double get rating => 0.0; // 실제 Firestore에는 없음
  @deprecated
  int get reviewCount => 0; // 실제 Firestore에는 없음

  Game({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.prologue,
    required this.imageUrl,
    required this.gameImage,
    required this.benefitImage,
    required this.meetingPlayImage,
    required this.roundersPlayImage,
    this.images = const [], // 기본값으로 빈 배열
    required this.rules,
    required this.materials,
    required this.tags,
    required this.minPlayers,
    required this.maxPlayers,
    required this.participationFee,
    required this.difficulty,
    required this.gameType,
    required this.estimatedDuration,
    required this.isActive,
  });

  factory Game.fromMap(Map<String, dynamic> map) {
    try {
      return Game(
        id: map['id'] ?? '',
        title: map['title'] ?? '제목 없음',
        subtitle: map['subtitle'] ?? '',
        description: map['description'] ?? '',
        prologue: map['prologue'] ?? '',
        imageUrl: map['imageUrl'] ?? '',
        gameImage: map['gameImage'] ?? '',
        benefitImage: map['benefitImage'] ?? '',
        meetingPlayImage: map['meetingPlayImage'] ?? '',
        roundersPlayImage: map['roundersPlayImage'] ?? '',
        images: _extractImages(map),
        rules: _parseStringList(map['rules']),
        materials: _parseStringList(map['materials']),
        tags: _parseStringList(map['tags']),
        minPlayers: _parseInt(map['minPlayers']),
        maxPlayers: _parseInt(map['maxPlayers']),
        participationFee: _parseDouble(map['participationFee']),
        difficulty: map['difficulty'] ?? '난이도 정보 없음',
        gameType: map['gameType'] ?? '',
        estimatedDuration: _parseInt(map['estimatedDuration']),
        isActive: map['isActive'] ?? true,
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
      'gameImage': gameImage,
      'benefitImage': benefitImage,
      'meetingPlayImage': meetingPlayImage,
      'roundersPlayImage': roundersPlayImage,
      'rules': rules,
      'materials': materials,
      'tags': tags,
      'minPlayers': minPlayers,
      'maxPlayers': maxPlayers,
      'participationFee': participationFee,
      'difficulty': difficulty,
      'gameType': gameType,
      'estimatedDuration': estimatedDuration,
      'isActive': isActive,
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
  /// 2) 배열이 없거나 비어 있으면, 특정 이미지 필드들을 순서대로 수집
  static List<String> _extractImages(Map<String, dynamic> map) {
    print('🔍 Game._extractImages 시작');
    print('🔍 전체 필드: ${map.keys.toList()}');

    // 1) 배열 형태 우선
    final rawImages = map['images'];
    final parsed = _parseStringList(rawImages);
    if (parsed.isNotEmpty) {
      print('🔍 images 배열 사용: $parsed');
      return parsed;
    }

    // 2) 특정 이미지 필드들을 순서대로 수집
    final List<String> found = [];

    // 이미지 순서 최적화: 중복 방지 및 의미있는 순서로 배치
    final imageFields = [
      'gameImage', // index 0: 게임 대표 이미지
      'roundersPlayImage', // index 1: 라운더스 게임 진행 이미지 ⭐
      'meetingPlayImage', // index 2: 모임 플레이 이미지
      'benefitImage', // index 3: 참여혜택 배경 이미지 ⭐ (중요한 위치!)
      'imageUrl', // index 4: 추가 이미지 (마지막으로 이동)
    ];

    for (String field in imageFields) {
      final value = map[field];
      if (value is String) {
        found.add(value); // 빈 문자열도 인덱스 유지를 위해 추가
        print('🔍 $field 추가: $value (${value.isEmpty ? "빈 문자열" : "유효"})');
      } else {
        found.add(''); // null이면 빈 문자열로 인덱스 유지
        print('🔍 $field: null이므로 빈 문자열 추가');
      }
    }

    // 3) 나머지 이미지 필드들 스캔 (위에서 추가하지 않은 것들)
    map.forEach((key, value) {
      if (value is String && value.isNotEmpty && !found.contains(value)) {
        final lowerKey = key.toLowerCase();
        if (lowerKey.contains('image') || lowerKey.contains('img')) {
          if (!imageFields.contains(key)) {
            found.add(value);
            print('🔍 추가 이미지 $key 추가: $value');
          }
        }
      }
    });

    print('🔍 최종 images 배열: $found');
    return found.take(10).toList();
  }
}
