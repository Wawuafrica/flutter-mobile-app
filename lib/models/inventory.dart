class Inventory {
  final String productId;
  final String? variantId; // If inventory is tracked per variant
  final int quantity;
  final String? location;
  final DateTime? lastRestockedDate;

  Inventory({
    required this.productId,
    this.variantId,
    required this.quantity,
    this.location,
    this.lastRestockedDate,
  });

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      productId: json['product_id'] as String,
      variantId: json['variant_id'] as String?,
      quantity: json['quantity'] as int,
      location: json['location'] as String?,
      lastRestockedDate:
          json['last_restocked_date'] != null
              ? DateTime.tryParse(json['last_restocked_date'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'variant_id': variantId,
      'quantity': quantity,
      'location': location,
      'last_restocked_date': lastRestockedDate?.toIso8601String(),
    };
  }
}
