class Institution {
  final int id;
  final String name;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Institution({
    required this.id,
    required this.name,
    required this.createdAt,
    this.updatedAt,
  });

  factory Institution.fromJson(Map<String, dynamic> json) {
    return Institution(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
  }
}
