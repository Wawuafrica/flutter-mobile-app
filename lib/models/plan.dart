class Feature {
  final int id;
  final String uuid;
  final String name;
  final String description;
  final String value;
  final int paymentPlanId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Feature({
    required this.id,
    required this.uuid,
    required this.name,
    required this.description,
    required this.value,
    required this.paymentPlanId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Feature.fromJson(Map<String, dynamic> json) {
    return Feature(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      value: json['value'] as String,
      paymentPlanId: json['payment_plan_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'description': description,
      'value': value,
      'payment_plan_id': paymentPlanId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Plan {
  final String uuid;
  final String name;
  final String? description;
  final double amount;
  final String currency;
  final String interval;
  final List<Feature>? features;
  final DateTime createdAt;
  final DateTime updatedAt;

  Plan({
    required this.uuid,
    required this.name,
    this.description,
    required this.amount,
    required this.currency,
    required this.interval,
    this.features,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      amount: double.parse(json['amount'] as String),
      currency: json['currency'] as String,
      interval: json['interval'] as String,
      features: json['features'] != null
          ? (json['features'] as List)
              .map((feature) => Feature.fromJson(feature as Map<String, dynamic>))
              .toList()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'description': description,
      'amount': amount.toString(),
      'currency': currency,
      'interval': interval,
      'features': features?.map((feature) => feature.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}