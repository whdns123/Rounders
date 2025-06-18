class LicenseModel {
  final String name;
  final String version;
  final String description;
  final String licenseType;
  final String licenseText;
  final String homepage;
  final String repository;

  LicenseModel({
    required this.name,
    required this.version,
    required this.description,
    required this.licenseType,
    required this.licenseText,
    required this.homepage,
    required this.repository,
  });

  factory LicenseModel.fromMap(Map<String, dynamic> map) {
    return LicenseModel(
      name: map['name'] ?? '',
      version: map['version'] ?? '',
      description: map['description'] ?? '',
      licenseType: map['licenseType'] ?? '',
      licenseText: map['licenseText'] ?? '',
      homepage: map['homepage'] ?? '',
      repository: map['repository'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'version': version,
      'description': description,
      'licenseType': licenseType,
      'licenseText': licenseText,
      'homepage': homepage,
      'repository': repository,
    };
  }
}
