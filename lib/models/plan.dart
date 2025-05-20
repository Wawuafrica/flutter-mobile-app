class Plan {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String currency;
  final String interval; // e.g., 'month', 'year'
  final int?
  intervalCount; // e.g., 1 for monthly, 3 for quarterly if interval is 'month'
  final List<String>? features;
  final bool isActive;
  final int? trialPeriodDays;

  Plan({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.currency,
    required this.interval,
    this.intervalCount,
    this.features,
    this.isActive = true,
    this.trialPeriodDays,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String,
      interval: json['interval'] as String,
      intervalCount: json['interval_count'] as int?,
      features:
          json['features'] != null
              ? List<String>.from(json['features'].map((x) => x as String))
              : null,
      isActive: json['is_active'] as bool? ?? true,
      trialPeriodDays: json['trial_period_days'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'interval': interval,
      'interval_count': intervalCount,
      'features': features,
      'is_active': isActive,
      'trial_period_days': trialPeriodDays,
    };
  }
}
