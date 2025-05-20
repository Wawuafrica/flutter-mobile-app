class ProductVariant {
  final String id;
  final String productId;
  final String name; // e.g., 'Color', 'Size'
  final String value; // e.g., 'Red', 'XL'
  final double
  priceModifier; // Can be additive or multiplicative, depending on API logic
  final int? stockQuantity;
  final String? sku;
  // Add other relevant fields like 'image_url'

  ProductVariant({
    required this.id,
    required this.productId,
    required this.name,
    required this.value,
    this.priceModifier = 0.0,
    this.stockQuantity,
    this.sku,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      name: json['name'] as String,
      value: json['value'] as String,
      priceModifier: (json['price_modifier'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: json['stock_quantity'] as int?,
      sku: json['sku'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'value': value,
      'price_modifier': priceModifier,
      'stock_quantity': stockQuantity,
      'sku': sku,
    };
  }
}
