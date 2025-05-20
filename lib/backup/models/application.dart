class GigApplication {
  final String id;
  final String gigId;
  final String userId;
  final String? coverLetter;
  final String? status; // e.g., 'pending', 'accepted', 'rejected'
  final DateTime? appliedAt;
  // Add fields for applicant details if not just using userId to fetch them
  // final User? applicant; // Example: if applicant details are embedded

  GigApplication({
    required this.id,
    required this.gigId,
    required this.userId,
    this.coverLetter,
    this.status,
    this.appliedAt,
    // this.applicant,
  });

  factory GigApplication.fromJson(Map<String, dynamic> json) {
    return GigApplication(
      id: json['id'] as String,
      gigId: json['gig_id'] as String,
      userId: json['user_id'] as String,
      coverLetter: json['cover_letter'] as String?,
      status: json['status'] as String?,
      appliedAt:
          json['applied_at'] != null
              ? DateTime.tryParse(json['applied_at'])
              : null,
      // applicant: json['applicant'] != null ? User.fromJson(json['applicant']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gig_id': gigId,
      'user_id': userId,
      'cover_letter': coverLetter,
      'status': status,
      'applied_at': appliedAt?.toIso8601String(),
      // 'applicant': applicant?.toJson(),
    };
  }
}

// If User model is needed and not imported, a placeholder or import is required.
// For now, assuming User model will be imported where GigApplication is used.
