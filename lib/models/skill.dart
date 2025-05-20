class Skill {
  final String id;
  final String name;
  // Add any other relevant fields like 'proficiency', 'experience_years', etc.

  Skill({required this.id, required this.name});

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(id: json['id'] as String, name: json['name'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
