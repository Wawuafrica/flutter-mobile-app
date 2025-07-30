class SubscriptionIap {
  final String id;
  final String planId;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final String? platform;
  final String? productId;
  final String? purchaseId;
  final String? originalTransactionId; // For iOS
  final bool isFromBackend; // Track if this came from backend verification

  SubscriptionIap({
    required this.id,
    required this.planId,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.platform,
    this.productId,
    this.purchaseId,
    this.originalTransactionId,
    this.isFromBackend = false,
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
      purchaseId: json['purchase_id']?.toString() ?? json['purchaseId']?.toString(),
      originalTransactionId: json['original_transaction_id']?.toString() ?? 
                           json['originalTransactionId']?.toString(),
      isFromBackend: json['is_from_backend'] == true || json['isFromBackend'] == true,
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
      'purchase_id': purchaseId,
      'original_transaction_id': originalTransactionId,
      'is_from_backend': isFromBackend,
    };
  }

  // Status checkers
  bool get isActive => status.toLowerCase() == 'active' && DateTime.now().isBefore(endDate);
  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isCanceled => status.toLowerCase() == 'canceled';
  bool get isRefunded => status.toLowerCase() == 'refunded';

  // Time-based helpers
  bool get isNearExpiration {
    if (!isActive) return false;
    final daysUntilExpiration = endDate.difference(DateTime.now()).inDays;
    return daysUntilExpiration <= 7; // Within 7 days of expiration
  }

  int get daysRemaining {
    if (!isActive) return 0;
    return endDate.difference(DateTime.now()).inDays;
  }

  Duration get timeRemaining {
    if (!isActive) return Duration.zero;
    return endDate.difference(DateTime.now());
  }

  // Subscription period helpers
  Duration get subscriptionDuration => endDate.difference(startDate);
  
  bool get isYearlySubscription => subscriptionDuration.inDays >= 360;
  bool get isMonthlySubscription => subscriptionDuration.inDays >= 28 && subscriptionDuration.inDays <= 32;

  // Progress calculation (0.0 to 1.0)
  double get usageProgress {
    if (!isActive) return 1.0;
    
    final totalDuration = endDate.difference(startDate);
    final usedDuration = DateTime.now().difference(startDate);
    
    if (totalDuration.inSeconds == 0) return 0.0;
    
    final progress = usedDuration.inSeconds / totalDuration.inSeconds;
    return progress.clamp(0.0, 1.0);
  }

  // Display helpers
  String get statusDisplayText {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'expired':
        return 'Expired';
      case 'pending':
        return 'Pending';
      case 'canceled':
        return 'Canceled';
      case 'refunded':
        return 'Refunded';
      default:
        return 'Unknown';
    }
  }

  String get platformDisplayText {
    switch (platform?.toLowerCase()) {
      case 'ios':
        return 'App Store';
      case 'android':
        return 'Google Play';
      default:
        return 'Unknown Platform';
    }
  }

  String get formattedEndDate {
    return '${endDate.day}/${endDate.month}/${endDate.year}';
  }

  String get formattedStartDate {
    return '${startDate.day}/${startDate.month}/${startDate.year}';
  }

  // Renewal helpers
  bool get willAutoRenew {
    // This would depend on the actual store subscription status
    // For now, assume active subscriptions will auto-renew unless canceled
    return isActive && !isCanceled;
  }

  // Copy method for updates
  SubscriptionIap copyWith({
    String? id,
    String? planId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? platform,
    String? productId,
    String? purchaseId,
    String? originalTransactionId,
    bool? isFromBackend,
  }) {
    return SubscriptionIap(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      platform: platform ?? this.platform,
      productId: productId ?? this.productId,
      purchaseId: purchaseId ?? this.purchaseId,
      originalTransactionId: originalTransactionId ?? this.originalTransactionId,
      isFromBackend: isFromBackend ?? this.isFromBackend,
    );
  }

  @override
  String toString() {
    return 'SubscriptionIap(id: $id, planId: $planId, status: $status, '
           'isActive: $isActive, endDate: $formattedEndDate, platform: $platform)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is SubscriptionIap &&
        other.id == id &&
        other.planId == planId &&
        other.status == status &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.platform == platform &&
        other.productId == productId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        planId.hashCode ^
        status.hashCode ^
        startDate.hashCode ^
        endDate.hashCode ^
        platform.hashCode ^
        productId.hashCode;
  }
}