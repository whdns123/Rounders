class GameResult {
  final String userId;
  final String userName;
  final int score;
  final int rank;
  final List<String> tags;

  GameResult({
    required this.userId,
    required this.userName,
    required this.score,
    required this.rank,
    required this.tags,
  });

  // Firestore용 변환 메서드
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'score': score,
      'rank': rank,
      'tags': tags,
    };
  }

  // Firestore 문서에서 객체 생성
  factory GameResult.fromMap(Map<String, dynamic> map) {
    return GameResult(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      score: map['score'] ?? 0,
      rank: map['rank'] ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  // 태그 추가 메서드 (복사본 반환)
  GameResult addTag(String tag) {
    final newTags = List<String>.from(tags);
    if (!newTags.contains(tag)) {
      newTags.add(tag);
    }

    return GameResult(
      userId: userId,
      userName: userName,
      score: score,
      rank: rank,
      tags: newTags,
    );
  }

  // 태그 제거 메서드 (복사본 반환)
  GameResult removeTag(String tag) {
    final newTags = List<String>.from(tags);
    newTags.remove(tag);

    return GameResult(
      userId: userId,
      userName: userName,
      score: score,
      rank: rank,
      tags: newTags,
    );
  }
}
