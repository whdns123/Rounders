class TermsModel {
  final String id;
  final String title;
  final String content;
  final DateTime lastUpdated;
  final String version;

  TermsModel({
    required this.id,
    required this.title,
    required this.content,
    required this.lastUpdated,
    required this.version,
  });

  factory TermsModel.fromMap(Map<String, dynamic> map) {
    return TermsModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      lastUpdated: DateTime.parse(
        map['lastUpdated'] ?? DateTime.now().toString(),
      ),
      version: map['version'] ?? '1.0',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'lastUpdated': lastUpdated.toIso8601String(),
      'version': version,
    };
  }
}
