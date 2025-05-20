class Mentorship {
  // Placeholder for mentorship program details
  final String? id;
  final String? title;
  final String? description;
  // Add other relevant fields based on future API structure

  Mentorship({
    this.id,
    this.title,
    this.description,
    // Initialize other fields
  });

  factory Mentorship.fromJson(Map<String, dynamic> json) {
    return Mentorship(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      // Map other fields
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      // Map other fields
    };
  }
}
