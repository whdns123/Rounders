import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name; // 실명
  final String? nickname; // 닉네임 (선택사항)
  final String gender;
  final String ageGroup;
  final String location;
  final String phone;
  final String? photoURL;
  final String? job; // 직업 (선택사항)
  final String? major; // 전공 (선택사항)
  final List<String> participatedMeetings;
  final List<String> hostedMeetings;
  final List<String> tags;
  final DateTime createdAt;
  final int totalScore;
  final int meetingsPlayed;
  final int wins; // 우승 횟수
  final int losses; // 패배 횟수
  final String tier;
  final String role; // "user", "host", "admin"
  final String hostStatus; // "none", "pending", "approved", "rejected"
  final DateTime? hostAppliedAt;
  final DateTime? hostSince;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.nickname,
    required this.gender,
    required this.ageGroup,
    required this.location,
    required this.phone,
    this.photoURL,
    this.job,
    this.major,
    List<String>? participatedMeetings,
    List<String>? hostedMeetings,
    List<String>? tags,
    DateTime? createdAt,
    this.totalScore = 0,
    this.meetingsPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.tier = '브론즈',
    this.role = 'user',
    this.hostStatus = 'none',
    this.hostAppliedAt,
    this.hostSince,
  }) : participatedMeetings = participatedMeetings ?? [],
       hostedMeetings = hostedMeetings ?? [],
       tags = tags ?? [],
       createdAt = createdAt ?? DateTime.now();

  // Firestore에서 데이터 변환
  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      nickname: map['nickname'],
      gender: map['gender'] ?? '',
      ageGroup: map['ageGroup'] ?? '',
      location: map['location'] ?? '',
      phone: map['phone'] ?? '',
      photoURL: map['photoURL'],
      job: map['job'],
      major: map['major'],
      participatedMeetings: List<String>.from(
        map['participatedMeetings'] ?? [],
      ),
      hostedMeetings: List<String>.from(map['hostedMeetings'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalScore: map['totalScore'] ?? 0,
      meetingsPlayed: map['meetingsPlayed'] ?? 0,
      wins: map['wins'] ?? 0,
      losses: map['losses'] ?? 0,
      tier: map['tier'] ?? '브론즈',
      role: map['role'] ?? 'user',
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
      'nickname': nickname,
      'gender': gender,
      'ageGroup': ageGroup,
      'location': location,
      'phone': phone,
      'photoURL': photoURL,
      'job': job,
      'major': major,
      'participatedMeetings': participatedMeetings,
      'hostedMeetings': hostedMeetings,
      'tags': tags,
      'createdAt': createdAt,
      'totalScore': totalScore,
      'meetingsPlayed': meetingsPlayed,
      'wins': wins,
      'losses': losses,
      'tier': tier,
      'role': role,
      'hostStatus': hostStatus,
      'hostAppliedAt': hostAppliedAt,
      'hostSince': hostSince,
    };
  }

  // 업데이트된 사용자 정보 반환 (변경된 필드만 업데이트)
  UserModel copyWith({
    String? name,
    String? nickname,
    String? gender,
    String? ageGroup,
    String? location,
    String? phone,
    String? photoURL,
    String? job,
    String? major,
    int? totalScore,
    int? meetingsPlayed,
    int? wins,
    int? losses,
    String? tier,
    String? role,
    String? hostStatus,
    DateTime? hostAppliedAt,
    DateTime? hostSince,
  }) {
    return UserModel(
      id: id,
      email: email,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      gender: gender ?? this.gender,
      ageGroup: ageGroup ?? this.ageGroup,
      location: location ?? this.location,
      phone: phone ?? this.phone,
      photoURL: photoURL ?? this.photoURL,
      job: job ?? this.job,
      major: major ?? this.major,
      participatedMeetings: participatedMeetings,
      hostedMeetings: hostedMeetings,
      tags: tags,
      createdAt: createdAt,
      totalScore: totalScore ?? this.totalScore,
      meetingsPlayed: meetingsPlayed ?? this.meetingsPlayed,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      tier: tier ?? this.tier,
      role: role ?? this.role,
      hostStatus: hostStatus ?? this.hostStatus,
      hostAppliedAt: hostAppliedAt ?? this.hostAppliedAt,
      hostSince: hostSince ?? this.hostSince,
    );
  }

  // 편의 메서드 추가
  bool get isHost => role == 'host';
  bool get isAdmin => role == 'admin';
  bool get isUser => role == 'user';

  // 승률 계산
  double get winRate {
    if (meetingsPlayed == 0) return 0.0;
    return (wins / meetingsPlayed * 100);
  }

  // 평균 점수 계산
  double get averageScore {
    if (meetingsPlayed == 0) return 0.0;
    return totalScore / meetingsPlayed;
  }
}
