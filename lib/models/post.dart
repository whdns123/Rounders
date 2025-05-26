import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final List<String> imageUrls;
  final String description;
  final String eventId;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final List<String> likes;

  Post({
    required this.id,
    required this.imageUrls,
    required this.description,
    required this.eventId,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.likes,
  });

  // Firestore에서 데이터를 가져올 때 사용
  factory Post.fromMap(String id, Map<String, dynamic> data) {
    return Post(
      id: id,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      description: data['description'] ?? '',
      eventId: data['eventId'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdByName: data['createdByName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      likes: List<String>.from(data['likes'] ?? []),
    );
  }

  // Firestore에 저장할 때 사용
  Map<String, dynamic> toFirestore() {
    return {
      'imageUrls': imageUrls,
      'description': description,
      'eventId': eventId,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
    };
  }

  // 좋아요 추가/제거를 위한 복사 메서드
  Post copyWith({
    String? id,
    List<String>? imageUrls,
    String? description,
    String? eventId,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    List<String>? likes,
  }) {
    return Post(
      id: id ?? this.id,
      imageUrls: imageUrls ?? this.imageUrls,
      description: description ?? this.description,
      eventId: eventId ?? this.eventId,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
    );
  }

  // 좋아요 토글
  Post toggleLike(String userId) {
    List<String> newLikes = List.from(likes);
    if (newLikes.contains(userId)) {
      newLikes.remove(userId);
    } else {
      newLikes.add(userId);
    }
    return copyWith(likes: newLikes);
  }

  // 사용자가 좋아요했는지 확인
  bool isLikedBy(String userId) {
    return likes.contains(userId);
  }
}

class Comment {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
  });

  // Firestore에서 데이터를 가져올 때 사용
  factory Comment.fromMap(String id, Map<String, dynamic> data) {
    return Comment(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Firestore에 저장할 때 사용
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
