import 'package:cloud_firestore/cloud_firestore.dart';

class CouponModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final int discountAmount;
  final int minimumPurchase;
  final DateTime validFrom;
  final DateTime validUntil;
  final bool used;
  final String? appliedTo;
  final DateTime createdAt;
  final DateTime? usedAt;

  CouponModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.discountAmount,
    this.minimumPurchase = 0,
    required this.validFrom,
    required this.validUntil,
    this.used = false,
    this.appliedTo,
    DateTime? createdAt,
    this.usedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Firestore에서 데이터 변환
  factory CouponModel.fromMap(String id, Map<String, dynamic> map) {
    return CouponModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      discountAmount: map['discountAmount'] ?? 0,
      minimumPurchase: map['minimumPurchase'] ?? 0,
      validFrom: (map['validFrom'] as Timestamp?)?.toDate() ?? DateTime.now(),
      validUntil: (map['validUntil'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 30)),
      used: map['used'] ?? false,
      appliedTo: map['appliedTo'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      usedAt: (map['usedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Firestore에 저장할 데이터로 변환
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'discountAmount': discountAmount,
      'minimumPurchase': minimumPurchase,
      'validFrom': validFrom,
      'validUntil': validUntil,
      'used': used,
      'appliedTo': appliedTo,
      'createdAt': createdAt,
      'usedAt': usedAt,
    };
  }

  // 사용됨으로 표시
  CouponModel markAsUsed(String eventId) {
    return CouponModel(
      id: id,
      userId: userId,
      title: title,
      description: description,
      discountAmount: discountAmount,
      minimumPurchase: minimumPurchase,
      validFrom: validFrom,
      validUntil: validUntil,
      used: true,
      appliedTo: eventId,
      createdAt: createdAt,
      usedAt: DateTime.now(),
    );
  }

  // 쿠폰 유효성 검사
  bool isValid() {
    final now = DateTime.now();
    return !used && now.isAfter(validFrom) && now.isBefore(validUntil);
  }

  // 특정 금액에 적용 가능한지 확인
  bool isApplicableTo(int amount) {
    return amount >= minimumPurchase;
  }
}
