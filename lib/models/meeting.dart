import 'package:cloud_firestore/cloud_firestore.dart';

class Meeting {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime scheduledDate;
  final int maxParticipants;
  final int currentParticipants;
  final String hostId;
  final String hostName;
  final int price;
  final String? imageUrl;
  final List<String> participants;
  final bool isCompleted;
  final bool hasResults;
  final List<String> imageUrls;
  final String requiredLevel;

  Meeting({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.scheduledDate,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.hostId,
    required this.hostName,
    required this.price,
    this.imageUrl,
    required this.participants,
    this.isCompleted = false,
    this.hasResults = false,
    this.imageUrls = const [],
    this.requiredLevel = '모두',
  });

  // Firestore용 변환 메서드
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'scheduledDate': scheduledDate,
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'hostId': hostId,
      'hostName': hostName,
      'price': price,
      'imageUrl': imageUrl,
      'participants': participants,
      'isCompleted': isCompleted,
      'hasResults': hasResults,
      'imageUrls': imageUrls,
      'requiredLevel': requiredLevel,
    };
  }

  // Firestore 문서 스냅샷에서 모델 객체 생성
  factory Meeting.fromMap(String id, Map<String, dynamic> map) {
    // Timestamp를 DateTime으로 변환하는 로직 추가
    DateTime parsedDate;
    if (map['scheduledDate'] is Timestamp) {
      parsedDate = (map['scheduledDate'] as Timestamp).toDate();
    } else if (map['scheduledDate'] is DateTime) {
      parsedDate = map['scheduledDate'] as DateTime;
    } else {
      parsedDate = DateTime.now(); // 기본값
    }

    return Meeting(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      scheduledDate: parsedDate,
      maxParticipants: map['maxParticipants'] ?? 0,
      currentParticipants: map['currentParticipants'] ?? 0,
      hostId: map['hostId'] ?? '',
      hostName: map['hostName'] ?? '',
      price: map['price'] ?? 0,
      imageUrl: map['imageUrl'],
      participants: List<String>.from(map['participants'] ?? []),
      isCompleted: map['isCompleted'] ?? false,
      hasResults: map['hasResults'] ?? false,
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      requiredLevel: map['requiredLevel'] ?? '모두',
    );
  }

  // Firestore 문서에서 Meeting 객체 생성
  factory Meeting.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Timestamp를 DateTime으로 변환하는 로직 추가
    DateTime parsedDate;
    if (data['scheduledDate'] is Timestamp) {
      parsedDate = (data['scheduledDate'] as Timestamp).toDate();
    } else if (data['scheduledDate'] is DateTime) {
      parsedDate = data['scheduledDate'] as DateTime;
    } else {
      parsedDate = DateTime.now(); // 기본값
    }

    return Meeting(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      scheduledDate: parsedDate,
      maxParticipants: data['maxParticipants'] ?? 0,
      currentParticipants: data['currentParticipants'] ?? 0,
      hostId: data['hostId'] ?? '',
      hostName: data['hostName'] ?? '',
      price: data['price'] ?? 0,
      imageUrl: data['imageUrl'],
      participants: List<String>.from(data['participants'] ?? []),
      isCompleted: data['isCompleted'] ?? false,
      hasResults: data['hasResults'] ?? false,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      requiredLevel: data['requiredLevel'] ?? '모두',
    );
  }

  // Meeting 객체를 Firestore 문서로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'hostId': hostId,
      'hostName': hostName,
      'price': price,
      'imageUrl': imageUrl,
      'participants': participants,
      'isCompleted': isCompleted,
      'hasResults': hasResults,
      'imageUrls': imageUrls,
      'requiredLevel': requiredLevel,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // 참가자 추가 메서드 (복사본 반환)
  Meeting addParticipant(String userId) {
    final newParticipants = List<String>.from(participants);
    newParticipants.add(userId);

    return Meeting(
      id: id,
      title: title,
      description: description,
      location: location,
      scheduledDate: scheduledDate,
      maxParticipants: maxParticipants,
      currentParticipants: currentParticipants + 1,
      hostId: hostId,
      hostName: hostName,
      price: price,
      imageUrl: imageUrl,
      participants: newParticipants,
      isCompleted: isCompleted,
      hasResults: hasResults,
      imageUrls: imageUrls,
      requiredLevel: requiredLevel,
    );
  }

  // 참가자 제거 메서드 (복사본 반환)
  Meeting removeParticipant(String userId) {
    final newParticipants = List<String>.from(participants);
    newParticipants.remove(userId);

    return Meeting(
      id: id,
      title: title,
      description: description,
      location: location,
      scheduledDate: scheduledDate,
      maxParticipants: maxParticipants,
      currentParticipants: currentParticipants - 1,
      hostId: hostId,
      hostName: hostName,
      price: price,
      imageUrl: imageUrl,
      participants: newParticipants,
      isCompleted: isCompleted,
      hasResults: hasResults,
      imageUrls: imageUrls,
      requiredLevel: requiredLevel,
    );
  }

  // 동등성 비교를 위한 equals 메서드
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Meeting) return false;
    return id == other.id;
  }

  // hashCode 메서드
  @override
  int get hashCode => id.hashCode;
}
