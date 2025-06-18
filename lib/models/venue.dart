import 'package:cloud_firestore/cloud_firestore.dart';

class Venue {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String? website;
  final String? instagram;
  final List<String> operatingHours; // ["월-금: 11:00-22:30", "토-일: 10:00-23:00"]
  final List<String> imageUrls;
  final List<VenueMenu> menu;
  final String hostId; // 이 장소를 등록한 호스트 ID
  final DateTime createdAt;

  Venue({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.website,
    this.instagram,
    required this.operatingHours,
    required this.imageUrls,
    required this.menu,
    required this.hostId,
    required this.createdAt,
  });

  // Firestore에서 데이터 변환
  factory Venue.fromMap(String id, Map<String, dynamic> map) {
    return Venue(
      id: id,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      website: map['website'],
      instagram: map['instagram'],
      operatingHours: List<String>.from(map['operatingHours'] ?? []),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      menu:
          (map['menu'] as List<dynamic>?)
              ?.map((item) => VenueMenu.fromMap(item))
              .toList() ??
          [],
      hostId: map['hostId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Firestore에 저장할 데이터로 변환
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'website': website,
      'instagram': instagram,
      'operatingHours': operatingHours,
      'imageUrls': imageUrls,
      'menu': menu.map((item) => item.toMap()).toList(),
      'hostId': hostId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class VenueMenu {
  final String name;
  final String description;
  final double price;
  final String? imageUrl;

  VenueMenu({
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
  });

  factory VenueMenu.fromMap(Map<String, dynamic> map) {
    return VenueMenu(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
    };
  }
}
