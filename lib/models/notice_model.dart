class NoticeModel {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final bool isNew;
  final String? imageUrl;

  NoticeModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.isNew = false,
    this.imageUrl,
  });

  factory NoticeModel.fromMap(Map<String, dynamic> map) {
    return NoticeModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      isNew: map['isNew'] ?? false,
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'isNew': isNew,
      'imageUrl': imageUrl,
    };
  }

  NoticeModel copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    bool? isNew,
    String? imageUrl,
  }) {
    return NoticeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isNew: isNew ?? this.isNew,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
