class Transaction {
  final String id;
  final String userId;
  final String
  type; // e.g., 'deposit', 'withdrawal', 'payment', 'refund', 'gig_payment', 'subscription_fee'
  final double amount;
  final String currency;
  final String status; // e.g., 'pending', 'completed', 'failed', 'cancelled'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? description;
  final String?
  paymentGatewayId; // ID from payment gateway for this transaction
  final String? relatedEntityId; // e.g., order_id, gig_id, subscription_id
  final String? relatedEntityType; // e.g., 'order', 'gig', 'subscription'

  Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.description,
    this.paymentGatewayId,
    this.relatedEntityId,
    this.relatedEntityType,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
      description: json['description'] as String?,
      paymentGatewayId: json['payment_gateway_id'] as String?,
      relatedEntityId: json['related_entity_id'] as String?,
      relatedEntityType: json['related_entity_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'amount': amount,
      'currency': currency,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'description': description,
      'payment_gateway_id': paymentGatewayId,
      'related_entity_id': relatedEntityId,
      'related_entity_type': relatedEntityType,
    };
  }
}
