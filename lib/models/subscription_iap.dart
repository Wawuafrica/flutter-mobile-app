// Add this to your SubscriptionIap model if it doesn't have these fields
class SubscriptionIap {
  final String id;
  final String planId;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final String? platform;
  final String? productId;

  SubscriptionIap({
    required this.id,
    required this.planId,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.platform,
    this.productId,
  });

  factory SubscriptionIap.fromJson(Map<String, dynamic> json) {
    return SubscriptionIap(
      id: json['id']?.toString() ?? '',
      planId: json['plan_id']?.toString() ?? json['planId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'unknown',
      startDate: json['start_date'] != null 
          ? DateTime.parse(json['start_date'].toString())
          : json['startDate'] != null
              ? DateTime.parse(json['startDate'].toString())
              : DateTime.now(),
      endDate: json['end_date'] != null 
          ? DateTime.parse(json['end_date'].toString())
          : json['endDate'] != null
              ? DateTime.parse(json['endDate'].toString())
              : DateTime.now().add(const Duration(days: 365)),
      platform: json['platform']?.toString(),
      productId: json['product_id']?.toString() ?? json['productId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'status': status,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'platform': platform,
      'product_id': productId,
    };
  }

  bool get isActive => status.toLowerCase() == 'active' && DateTime.now().isBefore(endDate);
  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isPending => status.toLowerCase() == 'pending';
}