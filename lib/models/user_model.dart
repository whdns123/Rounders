import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String gender;
  final String ageGroup;
  final String location;
  final String phone;
  final String? photoURL;
  final List<String> participatedMeetings;
  final List<String> hostedMeetings;
  final List<String> tags;
  final DateTime createdAt;
  final int totalScore;
  final int meetingsPlayed;
  final String tier;
  final bool isHost;
  final String hostStatus; // "none", "pending", "approved", "rejected"
  final DateTime? hostAppliedAt;
  final DateTime? hostSince;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.gender,
    required this.ageGroup,
    required this.location,
    required this.phone,
    this.photoURL,
    List<String>? participatedMeetings,
    List<String>? hostedMeetings,
    List<String>? tags,
    DateTime? createdAt,
    this.totalScore = 0,
    this.meetingsPlayed = 0,
    this.tier = '브론즈',
    this.isHost = false,
    this.hostStatus = 'none',
    this.hostAppliedAt,
    this.hostSince,
  })  : participatedMeetings = participatedMeetings ?? [],
        hostedMeetings = hostedMeetings ?? [],
        tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now();

  // Firestore에서 데이터 변환
  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      gender: map['gender'] ?? '',
      ageGroup: map['ageGroup'] ?? '',
      location: map['location'] ?? '',
      phone: map['phone'] ?? '',
      photoURL: map['photoURL'],
      participatedMeetings:
          List<String>.from(map['participatedMeetings'] ?? []),
      hostedMeetings: List<String>.from(map['hostedMeetings'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalScore: map['totalScore'] ?? 0,
      meetingsPlayed: map['meetingsPlayed'] ?? 0,
      tier: map['tier'] ?? '브론즈',
      isHost: map['isHost'] ?? false,
      hostStatus: map['hostStatus'] ?? 'none',
      hostAppliedAt: (map['hostAppliedAt'] as Timestamp?)?.toDate(),
      hostSince: (map['hostSince'] as Timestamp?)?.toDate(),
    );
  }

  // Firestore에 저장할 데이터로 변환
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'gender': gender,
      'ageGroup': ageGroup,
      'location': location,
      'phone': phone,
      'photoURL': photoURL,
      'participatedMeetings': participatedMeetings,
      'hostedMeetings': hostedMeetings,
      'tags': tags,
      'createdAt': createdAt,
      'totalScore': totalScore,
      'meetingsPlayed': meetingsPlayed,
      'tier': tier,
      'isHost': isHost,
      'hostStatus': hostStatus,
      'hostAppliedAt': hostAppliedAt,
      'hostSince': hostSince,
    };
  }

  // 업데이트된 사용자 정보 반환 (변경된 필드만 업데이트)
  UserModel copyWith({
    String? name,
    String? gender,
    String? ageGroup,
    String? location,
    String? phone,
    String? photoURL,
    int? totalScore,
    int? meetingsPlayed,
    String? tier,
    bool? isHost,
    String? hostStatus,
    DateTime? hostAppliedAt,
    DateTime? hostSince,
  }) {
    return UserModel(
      id: id,
      email: email,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      ageGroup: ageGroup ?? this.ageGroup,
      location: location ?? this.location,
      phone: phone ?? this.phone,
      photoURL: photoURL ?? this.photoURL,
      participatedMeetings: participatedMeetings,
      hostedMeetings: hostedMeetings,
      tags: tags,
      createdAt: createdAt,
      totalScore: totalScore ?? this.totalScore,
      meetingsPlayed: meetingsPlayed ?? this.meetingsPlayed,
      tier: tier ?? this.tier,
      isHost: isHost ?? this.isHost,
      hostStatus: hostStatus ?? this.hostStatus,
      hostAppliedAt: hostAppliedAt ?? this.hostAppliedAt,
      hostSince: hostSince ?? this.hostSince,
    );
  }
}
