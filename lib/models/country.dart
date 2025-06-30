class Country {
  final int id;
  final String name;
  final String? flag;

  Country({required this.id, required this.name, this.flag});

  factory Country.fromJson(Map<String, dynamic> json) => Country(
        id: json['id'],
        name: json['name'],
        flag: json['flag'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (flag != null) 'flag': flag,
      };
}

