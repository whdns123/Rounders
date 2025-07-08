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
  final int tierScore; // 티어 점수 (게임 결과 기반)
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
    this.tierScore = 0,
    this.meetingsPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.tier = 'clover',
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
      tierScore: map['tierScore'] ?? 0,
      meetingsPlayed: map['meetingsPlayed'] ?? 0,
      wins: map['wins'] ?? 0,
      losses: map['losses'] ?? 0,
      tier: map['tier'] ?? 'clover',
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
      'tierScore': tierScore,
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
    int? tierScore,
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
      tierScore: tierScore ?? this.tierScore,
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

  // 평균 등수 계산 (tierScore 기반으로 추정)
  double get averageRank {
    if (meetingsPlayed == 0) return 0.0;

    // tierScore를 meetingsPlayed로 나눠서 게임당 평균 점수 계산
    // 1등(5점), 2등(3점), 3등(2점), 4등(0점) 기준으로 역산
    final avgScorePerGame = tierScore / meetingsPlayed;

    if (avgScorePerGame >= 4.5) return 1.0; // 거의 1등
    if (avgScorePerGame >= 3.5) return 1.5; // 1~2등 사이
    if (avgScorePerGame >= 2.5) return 2.0; // 평균 2등
    if (avgScorePerGame >= 1.5) return 2.5; // 2~3등 사이
    if (avgScorePerGame >= 0.5) return 3.0; // 평균 3등
    return 3.5; // 대부분 4등
  }

  // 티어 계산 (점수 기반)
  String calculateTierFromScore(int score) {
    if (score >= 30) return 'spade';
    if (score >= 20) return 'heart';
    if (score >= 10) return 'diamond';
    return 'clover';
  }

  // 현재 티어 (tierScore 기반)
  String get calculatedTier => calculateTierFromScore(tierScore);

  // 티어 이름 (한국어)
  String get tierDisplayName {
    switch (tier) {
      case 'spade':
        return '스페이드';
      case 'heart':
        return '하트';
      case 'diamond':
        return '다이아';
      case 'clover':
        return '클로버';
      default:
        return '클로버';
    }
  }

  // 티어 아이콘 경로
  String get tierIconPath {
    return 'assets/images/$tier.png';
  }

  // 다음 티어까지 필요한 점수
  int get pointsToNextTier {
    final currentTierMin = (tierScore ~/ 10) * 10;
    final nextTierMin = currentTierMin + 10;
    if (tierScore >= 30) return 0; // 최대 티어일 때
    return nextTierMin - tierScore;
  }

  // 게임 결과에 따른 점수 증가
  UserModel addTierScore(int rank) {
    int scoreToAdd = 0;
    switch (rank) {
      case 1:
        scoreToAdd = 5; // 1등: +5점
        break;
      case 2:
        scoreToAdd = 3; // 2등: +3점
        break;
      case 3:
        scoreToAdd = 2; // 3등: +2점
        break;
      default:
        scoreToAdd = 0; // 4등 이하는 점수 없음
    }

    final newTierScore = tierScore + scoreToAdd;
    final newTier = calculateTierFromScore(newTierScore);

    return copyWith(tierScore: newTierScore, tier: newTier);
  }
}
