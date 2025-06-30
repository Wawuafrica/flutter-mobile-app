class LinkItem {
  final int id;
  final String name;
  final String link;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LinkItem({
    required this.id,
    required this.name,
    required this.link,
    this.createdAt,
    this.updatedAt,
  });

  factory LinkItem.fromJson(Map<String, dynamic> json) => LinkItem(
        id: json['id'] as int,
        name: json['name'] as String,
        link: json['link'] as String,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
        updatedAt: json['updated_at'] != null && json['updated_at'] != '' ? DateTime.tryParse(json['updated_at']) : null,
      );
}
