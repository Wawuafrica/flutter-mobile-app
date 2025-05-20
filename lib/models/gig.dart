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
  final String categoryId; // Primary category ID
  final String? subCategoryId; // Sub-category ID
  final String serviceId; // Service ID (level 3 category)
  final String? assignedTo;
  final List<String> skills;
  final String location;
  final Map<String, dynamic> additionalDetails;
  final String? ownerName; // Name of the gig creator
  final String? ownerAvatar; // Avatar URL of the gig creator

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
    required this.categoryId,
    this.subCategoryId,
    required this.serviceId,
    this.assignedTo,
    required this.skills,
    required this.location,
    Map<String, dynamic>? additionalDetails,
    this.ownerName,
    this.ownerAvatar,
  }) : additionalDetails = additionalDetails ?? {};

  factory Gig.fromJson(Map<String, dynamic> json) {
    // Handle skills which might be a comma-separated string or a list
    List<String> parseSkills() {
      if (json['skills'] == null) return [];
      
      if (json['skills'] is String) {
        // Handle comma-separated string
        return (json['skills'] as String)
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      } else if (json['skills'] is List) {
        // Handle list format
        return (json['skills'] as List)
            .map((e) => e.toString())
            .toList();
      }
      return [];
    }

    return Gig(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      ownerId: json['owner_id'] as String? ?? json['user_id'] as String? ?? '',
      budget: (json['budget'] is num) ? (json['budget'] as num).toDouble() : 0.0,
      currency: json['currency'] as String? ?? 'USD',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : DateTime.now().add(const Duration(days: 7)),
      status: json['status'] as String? ?? 'open',
      categoryId: json['category_id'] as String? ?? '',
      subCategoryId: json['subcategory_id'] as String?,
      serviceId: json['service_id'] as String? ?? '',
      assignedTo: json['assigned_to'] as String?,
      skills: parseSkills(),
      location: json['location'] as String? ?? '',
      ownerName: json['owner_name'] as String?,
      ownerAvatar: json['owner_avatar'] as String?,
      additionalDetails: json['additional_details'] is Map<String, dynamic>
          ? json['additional_details'] as Map<String, dynamic>
          : {},
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
      'category_id': categoryId,
      'subcategory_id': subCategoryId,
      'service_id': serviceId,
      'assigned_to': assignedTo,
      'skills': skills,
      'location': location,
      'additional_details': additionalDetails,
      if (ownerName != null) 'owner_name': ownerName,
      if (ownerAvatar != null) 'owner_avatar': ownerAvatar,
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
    String? categoryId,
    String? subCategoryId,
    String? serviceId,
    String? assignedTo,
    List<String>? skills,
    String? location,
    Map<String, dynamic>? additionalDetails,
    String? ownerName,
    String? ownerAvatar,
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
      categoryId: categoryId ?? this.categoryId,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      serviceId: serviceId ?? this.serviceId,
      assignedTo: assignedTo ?? this.assignedTo,
      skills: skills ?? this.skills,
      location: location ?? this.location,
      additionalDetails: additionalDetails ?? this.additionalDetails,
      ownerName: ownerName ?? this.ownerName,
      ownerAvatar: ownerAvatar ?? this.ownerAvatar,
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
