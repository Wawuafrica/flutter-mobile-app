class Review {
  final String id;
  final String reviewerId; // User ID of the person who wrote the review
  // final User? reviewer; // Optionally embed reviewer details
  final String
  entityId; // ID of the entity being reviewed (e.g., product, gig, user)
  final String entityType; // Type of entity: 'product', 'gig', 'user'
  final double rating; // e.g., 1.0 to 5.0
  final String? comment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Review({
    required this.id,
    required this.reviewerId,
    // this.reviewer,
    required this.entityId,
    required this.entityType,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      reviewerId: json['reviewer_id'] as String,
      // reviewer: json['reviewer'] != null ? User.fromJson(json['reviewer']) : null,
      entityId: json['entity_id'] as String,
      entityType: json['entity_type'] as String,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reviewer_id': reviewerId,
      // 'reviewer': reviewer?.toJson(),
      'entity_id': entityId,
      'entity_type': entityType,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

// If User model is needed and not imported, a placeholder or import is required.
