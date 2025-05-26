import 'package:cloud_firestore/cloud_firestore.dart';

enum ReservationStatus {
  pending, // 대기 중
  accepted, // 승인됨
  rejected, // 거절됨
  canceled, // 취소됨
  completed // 완료됨
}

class ReservationModel {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String userPhone;
  final String userGender;
  final String userAgeGroup;
  final bool isPaid;
  final int amount;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String status; // 예약 상태
  final DateTime? canceledAt; // 취소 시간
  final String? review; // 후기
  final int? rating; // 평점 (1-5)
  final bool attended; // 출석 여부
  final int? rank; // 등수 (1, 2, 3 등)
  final int? score; // 점수

  ReservationModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.userGender,
    required this.userAgeGroup,
    required this.amount,
    this.isPaid = false,
    DateTime? createdAt,
    this.paidAt,
    this.status = 'pending',
    this.canceledAt,
    this.review,
    this.rating,
    this.attended = false,
    this.rank,
    this.score,
  }) : this.createdAt = createdAt ?? DateTime.now();

  // Firestore에서 데이터 변환
  factory ReservationModel.fromMap(String id, Map<String, dynamic> map) {
    return ReservationModel(
      id: id,
      eventId: map['eventId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhone: map['userPhone'] ?? '',
      userGender: map['userGender'] ?? '',
      userAgeGroup: map['userAgeGroup'] ?? '',
      amount: map['amount'] ?? 0,
      isPaid: map['isPaid'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paidAt: (map['paidAt'] as Timestamp?)?.toDate(),
      status: map['status'] ?? 'pending',
      canceledAt: (map['canceledAt'] as Timestamp?)?.toDate(),
      review: map['review'],
      rating: map['rating'],
      attended: map['attended'] ?? false,
      rank: map['rank'],
      score: map['score'],
    );
  }

  // 사용자 정보로부터 예약 생성 (Firestore에 저장할 때 사용)
  static ReservationModel fromUserAndEvent({
    required String userId,
    required String userName,
    required String userPhone,
    required String userGender,
    required String userAgeGroup,
    required String eventId,
    required int amount,
  }) {
    return ReservationModel(
      id: '', // Firestore에서 자동 생성
      eventId: eventId,
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      userGender: userGender,
      userAgeGroup: userAgeGroup,
      amount: amount,
    );
  }

  // Firestore에 저장할 데이터로 변환
  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'userGender': userGender,
      'userAgeGroup': userAgeGroup,
      'amount': amount,
      'isPaid': isPaid,
      'createdAt': createdAt,
      'paidAt': paidAt,
      'status': status,
      'canceledAt': canceledAt,
      'review': review,
      'rating': rating,
      'attended': attended,
      'rank': rank,
      'score': score,
    };
  }

  // 결제 완료 상태로 업데이트
  ReservationModel markAsPaid() {
    return ReservationModel(
      id: this.id,
      eventId: this.eventId,
      userId: this.userId,
      userName: this.userName,
      userPhone: this.userPhone,
      userGender: this.userGender,
      userAgeGroup: this.userAgeGroup,
      amount: this.amount,
      isPaid: true,
      createdAt: this.createdAt,
      paidAt: DateTime.now(),
      status: 'accepted',
      canceledAt: this.canceledAt,
      review: this.review,
      rating: this.rating,
      attended: this.attended,
      rank: this.rank,
      score: this.score,
    );
  }

  // 취소 상태로 업데이트
  ReservationModel markAsCanceled() {
    return ReservationModel(
      id: this.id,
      eventId: this.eventId,
      userId: this.userId,
      userName: this.userName,
      userPhone: this.userPhone,
      userGender: this.userGender,
      userAgeGroup: this.userAgeGroup,
      amount: this.amount,
      isPaid: this.isPaid,
      createdAt: this.createdAt,
      paidAt: this.paidAt,
      status: 'canceled',
      canceledAt: DateTime.now(),
      review: this.review,
      rating: this.rating,
      attended: this.attended,
      rank: this.rank,
      score: this.score,
    );
  }

  // 후기 추가
  ReservationModel addReview(String review, int rating) {
    return ReservationModel(
      id: this.id,
      eventId: this.eventId,
      userId: this.userId,
      userName: this.userName,
      userPhone: this.userPhone,
      userGender: this.userGender,
      userAgeGroup: this.userAgeGroup,
      amount: this.amount,
      isPaid: this.isPaid,
      createdAt: this.createdAt,
      paidAt: this.paidAt,
      status: this.status,
      canceledAt: this.canceledAt,
      review: review,
      rating: rating,
      attended: this.attended,
      rank: this.rank,
      score: this.score,
    );
  }

  // 출석 상태 업데이트
  ReservationModel updateAttendance(bool attended) {
    return ReservationModel(
      id: this.id,
      eventId: this.eventId,
      userId: this.userId,
      userName: this.userName,
      userPhone: this.userPhone,
      userGender: this.userGender,
      userAgeGroup: this.userAgeGroup,
      amount: this.amount,
      isPaid: this.isPaid,
      createdAt: this.createdAt,
      paidAt: this.paidAt,
      status: this.status,
      canceledAt: this.canceledAt,
      review: this.review,
      rating: this.rating,
      attended: attended,
      rank: this.rank,
      score: this.score,
    );
  }

  // 등수 및 점수 업데이트
  ReservationModel updateResult({int? rank, int? score}) {
    return ReservationModel(
      id: this.id,
      eventId: this.eventId,
      userId: this.userId,
      userName: this.userName,
      userPhone: this.userPhone,
      userGender: this.userGender,
      userAgeGroup: this.userAgeGroup,
      amount: this.amount,
      isPaid: this.isPaid,
      createdAt: this.createdAt,
      paidAt: this.paidAt,
      status: 'completed',
      canceledAt: this.canceledAt,
      review: this.review,
      rating: this.rating,
      attended: this.attended,
      rank: rank ?? this.rank,
      score: score ?? this.score,
    );
  }
}
