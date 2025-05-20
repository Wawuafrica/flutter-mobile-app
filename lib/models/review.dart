class Review {
  final String id;
  final String reviewerId; // User ID of the person who wrote the review
  final String reviewedId; // User ID of the person being reviewed
  final String gigId; // ID of the gig this review is associated with
  final double rating; // e.g., 1.0 to 5.0
  final String comment; // Review content
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Optional additional fields from API
  final String? reviewerName; // Name of the reviewer
  final String? reviewerAvatar; // Avatar URL of the reviewer
  final String? reviewedName; // Name of the person being reviewed
  final String? reviewedAvatar; // Avatar URL of the person being reviewed

  Review({
    required this.id,
    required this.reviewerId,
    required this.reviewedId,
    required this.gigId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.updatedAt,
    this.reviewerName,
    this.reviewerAvatar,
    this.reviewedName,
    this.reviewedAvatar,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      reviewerId: json['reviewer_id'] as String? ?? json['user_id'] as String? ?? '',
      reviewedId: json['reviewed_id'] as String? ?? '',
      gigId: json['gig_id'] as String? ?? '',
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : 0.0,
      comment: json['comment'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      reviewerName: json['reviewer_name'] as String?,
      reviewerAvatar: json['reviewer_avatar'] as String?,
      reviewedName: json['reviewed_name'] as String?,
      reviewedAvatar: json['reviewed_avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reviewer_id': reviewerId,
      'reviewed_id': reviewedId,
      'gig_id': gigId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (reviewerName != null) 'reviewer_name': reviewerName,
      if (reviewerAvatar != null) 'reviewer_avatar': reviewerAvatar,
      if (reviewedName != null) 'reviewed_name': reviewedName,
      if (reviewedAvatar != null) 'reviewed_avatar': reviewedAvatar,
    };
  }
}

/// Helper method to check if the rating is positive (4-5 stars)
bool isPositiveRating(Review review) {
  return review.rating >= 4.0;
}

/// Helper method to check if the rating is neutral (3 stars)
bool isNeutralRating(Review review) {
  return review.rating >= 3.0 && review.rating < 4.0;
}

/// Helper method to check if the rating is negative (1-2 stars)
bool isNegativeRating(Review review) {
  return review.rating < 3.0;
}
