class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String sellerId;
  final String? sellerName;
  final List<String> categories;
  final List<String> tags;
  final List<String> imageUrls;
  final int stockQuantity;
  final double rating;
  final int reviewCount;
  final bool isFeatured;
  final bool isAvailable;
  final Map<String, dynamic> attributes; // Color, size, material, etc.
  final String? discountType; // 'percentage', 'fixed_amount'
  final double? discountValue;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.sellerId,
    this.sellerName,
    required this.categories,
    required this.tags,
    required this.imageUrls,
    required this.stockQuantity,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isFeatured = false,
    this.isAvailable = true,
    Map<String, dynamic>? attributes,
    this.discountType,
    this.discountValue,
  }) : attributes = attributes ?? {};

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String,
      sellerId: json['seller_id'] as String,
      sellerName: json['seller_name'] as String?,
      categories:
          (json['categories'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      imageUrls:
          (json['image_urls'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      stockQuantity: json['stock_quantity'] as int,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      isFeatured: json['is_featured'] as bool? ?? false,
      isAvailable: json['is_available'] as bool? ?? true,
      attributes: json['attributes'] as Map<String, dynamic>? ?? {},
      discountType: json['discount_type'] as String?,
      discountValue: (json['discount_value'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'categories': categories,
      'tags': tags,
      'image_urls': imageUrls,
      'stock_quantity': stockQuantity,
      'rating': rating,
      'review_count': reviewCount,
      'is_featured': isFeatured,
      'is_available': isAvailable,
      'attributes': attributes,
      'discount_type': discountType,
      'discount_value': discountValue,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? currency,
    String? sellerId,
    String? sellerName,
    List<String>? categories,
    List<String>? tags,
    List<String>? imageUrls,
    int? stockQuantity,
    double? rating,
    int? reviewCount,
    bool? isFeatured,
    bool? isAvailable,
    Map<String, dynamic>? attributes,
    String? discountType,
    double? discountValue,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      imageUrls: imageUrls ?? this.imageUrls,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isFeatured: isFeatured ?? this.isFeatured,
      isAvailable: isAvailable ?? this.isAvailable,
      attributes: attributes ?? this.attributes,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
    );
  }

  // Helper methods
  bool isInStock() {
    return stockQuantity > 0;
  }

  double getDiscountedPrice() {
    if (discountType == null || discountValue == null) {
      return price;
    }

    if (discountType == 'percentage') {
      return price - (price * discountValue! / 100);
    } else if (discountType == 'fixed_amount') {
      return price - discountValue!;
    }

    return price;
  }

  bool hasDiscount() {
    return discountType != null && discountValue != null;
  }

  String getMainImageUrl() {
    return imageUrls.isNotEmpty ? imageUrls[0] : '';
  }
}
