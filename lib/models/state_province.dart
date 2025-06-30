class StateProvince {
  final int id;
  final String name;

  StateProvince({required this.id, required this.name});

  factory StateProvince.fromJson(Map<String, dynamic> json) => StateProvince(
        id: json['id'],
        name: json['name'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}
