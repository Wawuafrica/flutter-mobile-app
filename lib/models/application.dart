import '../models/gig.dart';

class GigApplication {
  final String id;
  final String gigId;
  final String userId;
  final String? coverLetter;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime appliedAt;
  final double? proposedBudget; // Budget proposed by the applicant
  final String? applicantName; // Name of the applicant
  final String? applicantAvatar; // Avatar URL of the applicant
  final Gig? gig; // Optional nested gig data

  GigApplication({
    required this.id,
    required this.gigId,
    required this.userId,
    this.coverLetter,
    this.status = 'pending',
    required this.appliedAt,
    this.proposedBudget,
    this.applicantName,
    this.applicantAvatar,
    this.gig,
  });

  factory GigApplication.fromJson(Map<String, dynamic> json) {
    return GigApplication(
      id: json['id'] as String,
      gigId: json['gig_id'] as String,
      userId: json['user_id'] as String,
      coverLetter: json['cover_letter'] as String?,
      status: json['status'] as String? ?? 'pending',
      appliedAt: json['applied_at'] != null
          ? DateTime.parse(json['applied_at'] as String)
          : DateTime.now(),
      proposedBudget: json['proposed_budget'] != null
          ? (json['proposed_budget'] as num).toDouble()
          : null,
      applicantName: json['applicant_name'] as String?,
      applicantAvatar: json['applicant_avatar'] as String?,
      gig: json['gig'] != null ? Gig.fromJson(json['gig'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gig_id': gigId,
      'user_id': userId,
      'cover_letter': coverLetter,
      'status': status,
      'applied_at': appliedAt.toIso8601String(),
      if (proposedBudget != null) 'proposed_budget': proposedBudget,
      if (applicantName != null) 'applicant_name': applicantName,
      if (applicantAvatar != null) 'applicant_avatar': applicantAvatar,
      if (gig != null) 'gig': gig!.toJson(),
    };
  }
}

/// Checks if the application is pending
bool isPending(GigApplication application) {
  return application.status == 'pending';
}

/// Checks if the application is accepted
bool isAccepted(GigApplication application) {
  return application.status == 'accepted';
}

/// Checks if the application is rejected
bool isRejected(GigApplication application) {
  return application.status == 'rejected';
}
