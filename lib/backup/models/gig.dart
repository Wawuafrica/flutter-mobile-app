class Gig {
  final String id;
  final String title;
  final String description;
  final String ownerId;
  final double budget;
  final String currency; // e.g., 'USD', 'NGN'
  final DateTime createdAt;
  final DateTime deadline;
  final String status; // e.g., 'open', 'assigned', 'completed'
  final List<String> categories;
  final String? assignedTo;
  final List<String> skills;
  final String location;
  final Map<String, dynamic> additionalDetails;

  Gig({
    required this.id,
    required this.title,
    required this.description,
    required this.ownerId,
    required this.budget,
    required this.currency,
    required this.createdAt,
    required this.deadline,
    required this.status,
    required this.categories,
    this.assignedTo,
    required this.skills,
    required this.location,
    Map<String, dynamic>? additionalDetails,
  }) : additionalDetails = additionalDetails ?? {};

  factory Gig.fromJson(Map<String, dynamic> json) {
    return Gig(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      ownerId: json['owner_id'] as String,
      budget: (json['budget'] as num).toDouble(),
      currency: json['currency'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      deadline: DateTime.parse(json['deadline'] as String),
      status: json['status'] as String,
      categories:
          (json['categories'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      assignedTo: json['assigned_to'] as String?,
      skills:
          (json['skills'] as List<dynamic>).map((e) => e as String).toList(),
      location: json['location'] as String,
      additionalDetails:
          json['additional_details'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'owner_id': ownerId,
      'budget': budget,
      'currency': currency,
      'created_at': createdAt.toIso8601String(),
      'deadline': deadline.toIso8601String(),
      'status': status,
      'categories': categories,
      'assigned_to': assignedTo,
      'skills': skills,
      'location': location,
      'additional_details': additionalDetails,
    };
  }

  Gig copyWith({
    String? id,
    String? title,
    String? description,
    String? ownerId,
    double? budget,
    String? currency,
    DateTime? createdAt,
    DateTime? deadline,
    String? status,
    List<String>? categories,
    String? assignedTo,
    List<String>? skills,
    String? location,
    Map<String, dynamic>? additionalDetails,
  }) {
    return Gig(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      budget: budget ?? this.budget,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      categories: categories ?? this.categories,
      assignedTo: assignedTo ?? this.assignedTo,
      skills: skills ?? this.skills,
      location: location ?? this.location,
      additionalDetails: additionalDetails ?? this.additionalDetails,
    );
  }

  bool isOpen() {
    return status == 'open';
  }

  bool isAssigned() {
    return status == 'assigned';
  }

  bool isCompleted() {
    return status == 'completed';
  }

  bool isExpired() {
    return DateTime.now().isAfter(deadline);
  }
}
