class Certification {
  final int id;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Certification({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory Certification.fromJson(Map<String, dynamic> json) {
    return Certification(
      id: json['id'],
      name: json['name'],
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
  }
}
