import 'plan.dart';
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

// lib/models/subscription.dart

class Subscription {
  final int? flutterwaveSubscriptionId;
  final String? status;
  final String? subscribedAt;
  final String? expiresAt;
  final String? nextBillingDate;
  final String? reference;
  final double? amount; // Changed to double? to handle int and string values
  final String? uuid;
  final String? updatedAt;
  final String? createdAt;
  final Plan? plan;
  final User? user;

  Subscription({
    this.flutterwaveSubscriptionId,
    this.status,
    this.subscribedAt,
    this.expiresAt,
    this.nextBillingDate,
    this.reference,
    this.amount,
    this.uuid,
    this.updatedAt,
    this.createdAt,
    this.plan,
    this.user,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    // Robustly parse 'amount' which can be a String or num
    dynamic amountValue = json['amount'];
    double? parsedAmount;
    if (amountValue is String) {
      parsedAmount = double.tryParse(amountValue);
    } else if (amountValue is num) {
      parsedAmount = amountValue.toDouble();
    }

    // Robustly parse 'flutterwave_subscription_id' which can be a String or int
    dynamic idValue = json['flutterwave_subscription_id'];
    int? parsedId;
    if (idValue is String) {
      parsedId = int.tryParse(idValue);
    } else if (idValue is num) {
      parsedId = idValue.toInt();
    }

    return Subscription(
      flutterwaveSubscriptionId: parsedId, // Use the safely parsed ID
      status: json['status'] as String?,
      subscribedAt: json['subscribed_at'] as String?,
      expiresAt: json['expires_at'] as String?,
      nextBillingDate: json['next_billing_date'] as String?,
      reference: json['reference'] as String?,
      amount: parsedAmount, // Use the safely parsed amount
      uuid: json['uuid'] as String?,
      updatedAt: json['updated_at'] as String?,
      createdAt: json['created_at'] as String?,
      plan: json['plan'] != null
          ? Plan.fromJson(json['plan'] as Map<String, dynamic>)
          : null,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}
