import 'plan.dart'; // Assuming plan.dart is created for the Plan model

class Subscription {
  final String id;
  final String userId;
  final String planId;
  final Plan? plan; // Optionally embed the plan details
  final DateTime startDate;
  final DateTime? endDate;
  final String status; // e.g., 'active', 'cancelled', 'expired', 'trialing'
  final DateTime? trialEndsAt;
  final DateTime? cancelledAt;
  final String? paymentGatewaySubscriptionId; // ID from Stripe, PayPal, etc.

  Subscription({
    required this.id,
    required this.userId,
    required this.planId,
    this.plan,
    required this.startDate,
    this.endDate,
    required this.status,
    this.trialEndsAt,
    this.cancelledAt,
    this.paymentGatewaySubscriptionId,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      planId: json['plan_id'] as String,
      plan:
          json['plan'] != null
              ? Plan.fromJson(json['plan'] as Map<String, dynamic>)
              : null,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate:
          json['end_date'] != null
              ? DateTime.parse(json['end_date'] as String)
              : null,
      status: json['status'] as String,
      trialEndsAt:
          json['trial_ends_at'] != null
              ? DateTime.parse(json['trial_ends_at'] as String)
              : null,
      cancelledAt:
          json['cancelled_at'] != null
              ? DateTime.parse(json['cancelled_at'] as String)
              : null,
      paymentGatewaySubscriptionId:
          json['payment_gateway_subscription_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan_id': planId,
      'plan': plan?.toJson(),
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'status': status,
      'trial_ends_at': trialEndsAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'payment_gateway_subscription_id': paymentGatewaySubscriptionId,
    };
  }
}
