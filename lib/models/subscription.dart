// subscription_models.dart
import 'user.dart';

class PaymentLink {
  final String link;

  PaymentLink({required this.link});

  factory PaymentLink.fromJson(Map<String, dynamic> json) {
    return PaymentLink(link: json['link'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'link': link};
  }
}

class SubscriptionPlan {
  final String uuid;
  final String name;
  final String? description;
  final String amount;
  final String currency;
  final String flutterwavePlanId;
  final String interval;
  final String createdAt;
  final String updatedAt;

  SubscriptionPlan({
    required this.uuid,
    required this.name,
    this.description,
    required this.amount,
    required this.currency,
    required this.flutterwavePlanId,
    required this.interval,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      amount: json['amount'] as String,
      currency: json['currency'] as String,
      flutterwavePlanId: json['flutterwave_plan_id'] as String,
      interval: json['interval'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'description': description,
      'amount': amount,
      'currency': currency,
      'flutterwave_plan_id': flutterwavePlanId,
      'interval': interval,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class Subscription {
  final int flutterwaveSubscriptionId;
  final String status;
  final String subscribedAt;
  final String expiresAt;
  final String nextBillingDate;
  final String reference;
  final int amount;
  final String uuid;
  final String updatedAt;
  final String createdAt;
  final SubscriptionPlan plan;
  final User user;

  Subscription({
    required this.flutterwaveSubscriptionId,
    required this.status,
    required this.subscribedAt,
    required this.expiresAt,
    required this.nextBillingDate,
    required this.reference,
    required this.amount,
    required this.uuid,
    required this.updatedAt,
    required this.createdAt,
    required this.plan,
    required this.user,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      flutterwaveSubscriptionId: json['flutterwave_subscription_id'] as int,
      status: json['status'] as String,
      subscribedAt: json['subscribed_at'] as String,
      expiresAt: json['expires_at'] as String,
      nextBillingDate: json['next_billing_date'] as String,
      reference: json['reference'] as String,
      amount: json['amount'] as int,
      uuid: json['uuid'] as String,
      updatedAt: json['updated_at'] as String,
      createdAt: json['created_at'] as String,
      plan: SubscriptionPlan.fromJson(json['plan'] as Map<String, dynamic>),
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'flutterwave_subscription_id': flutterwaveSubscriptionId,
      'status': status,
      'subscribed_at': subscribedAt,
      'expires_at': expiresAt,
      'next_billing_date': nextBillingDate,
      'reference': reference,
      'amount': amount,
      'uuid': uuid,
      'updated_at': updatedAt,
      'created_at': createdAt,
      'plan': plan.toJson(),
      'user': user.toJson(),
    };
  }
}
