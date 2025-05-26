import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final String? imageUrl;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.imageUrl,
  });

  // Firestore로 변환
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp,
      'imageUrl': imageUrl,
    };
  }

  // Firestore 문서에서 생성
  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: map['imageUrl'],
    );
  }
}

class ChatRoom {
  final String id;
  final String eventId;
  final String eventTitle;
  final List<String> participantIds;
  final DateTime createdAt;
  final DateTime? expiredAt;
  final bool isActive;

  ChatRoom({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.participantIds,
    required this.createdAt,
    this.expiredAt,
    this.isActive = true,
  });

  // Firestore로 변환
  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'eventTitle': eventTitle,
      'participantIds': participantIds,
      'createdAt': createdAt,
      'expiredAt': expiredAt,
      'isActive': isActive,
    };
  }

  // Firestore 문서에서 생성
  factory ChatRoom.fromMap(String id, Map<String, dynamic> map) {
    return ChatRoom(
      id: id,
      eventId: map['eventId'] ?? '',
      eventTitle: map['eventTitle'] ?? '',
      participantIds: List<String>.from(map['participantIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiredAt: (map['expiredAt'] as Timestamp?)?.toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  // 참가자 추가 메서드 (복사본 반환)
  ChatRoom addParticipant(String userId) {
    final newParticipants = List<String>.from(participantIds);
    if (!newParticipants.contains(userId)) {
      newParticipants.add(userId);
    }

    return ChatRoom(
      id: id,
      eventId: eventId,
      eventTitle: eventTitle,
      participantIds: newParticipants,
      createdAt: createdAt,
      expiredAt: expiredAt,
      isActive: isActive,
    );
  }
}
