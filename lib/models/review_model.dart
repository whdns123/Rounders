import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final String userLevel;
  final String meetingId;
  final String meetingTitle;
  final String meetingLocation;
  final DateTime meetingDate;
  final String meetingImage;
  final int rating; // 1-5 별점
  final String content;
  final List<String> images;
  final DateTime createdAt;
  final List<String> helpfulVotes; // 도움이 됐다고 투표한 사용자 ID 목록
  final int participantCount; // 모임 참여 인원

  ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userLevel,
    required this.meetingId,
    required this.meetingTitle,
    required this.meetingLocation,
    required this.meetingDate,
    required this.meetingImage,
    required this.rating,
    required this.content,
    required this.images,
    required this.createdAt,
    required this.helpfulVotes,
    required this.participantCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userLevel': userLevel,
      'meetingId': meetingId,
      'meetingTitle': meetingTitle,
      'meetingLocation': meetingLocation,
      'meetingDate': Timestamp.fromDate(meetingDate),
      'meetingImage': meetingImage,
      'rating': rating,
      'content': content,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'helpfulVotes': helpfulVotes,
      'participantCount': participantCount,
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userLevel: map['userLevel'] ?? '',
      meetingId: map['meetingId'] ?? '',
      meetingTitle: map['meetingTitle'] ?? '',
      meetingLocation: map['meetingLocation'] ?? '',
      meetingDate:
          (map['meetingDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      meetingImage: map['meetingImage'] ?? '',
      rating: map['rating'] ?? 5,
      content: map['content'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      helpfulVotes: List<String>.from(map['helpfulVotes'] ?? []),
      participantCount: map['participantCount'] ?? 0,
    );
  }

  ReviewModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userLevel,
    String? meetingId,
    String? meetingTitle,
    String? meetingLocation,
    DateTime? meetingDate,
    String? meetingImage,
    int? rating,
    String? content,
    List<String>? images,
    DateTime? createdAt,
    List<String>? helpfulVotes,
    int? participantCount,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userLevel: userLevel ?? this.userLevel,
      meetingId: meetingId ?? this.meetingId,
      meetingTitle: meetingTitle ?? this.meetingTitle,
      meetingLocation: meetingLocation ?? this.meetingLocation,
      meetingDate: meetingDate ?? this.meetingDate,
      meetingImage: meetingImage ?? this.meetingImage,
      rating: rating ?? this.rating,
      content: content ?? this.content,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      helpfulVotes: helpfulVotes ?? this.helpfulVotes,
      participantCount: participantCount ?? this.participantCount,
    );
  }
}
