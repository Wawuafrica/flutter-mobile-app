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

class ProductImage {
  final String name;
  final String link;

  ProductImage({required this.name, required this.link});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      name: json['name'] as String,
      link: json['link'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'link': link};
  }
}

class Product {
  final String id; // uuid from API
  final String name;
  final String description;
  final String category;
  final List<String> tags;
  final String shortDescription;
  final String status; // AVAILABLE, DISABLED
  final String type; // PUBLISHED, DRAFT
  final String visibility; // public, private
  final String? publishAt;
  final String manufacturerName;
  final String manufacturerBrand;
  final double price;
  final String currency;
  final double? discount;
  final List<ProductImage> images;
  final List<ProductVariant> variants;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.tags,
    required this.shortDescription,
    required this.status,
    required this.type,
    required this.visibility,
    this.publishAt,
    required this.manufacturerName,
    required this.manufacturerBrand,
    required this.price,
    required this.currency,
    this.discount,
    required this.images,
    this.variants = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['uuid'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      tags: List<String>.from(json['tags'] as List),
      shortDescription: json['shortDescription'] as String,
      status: json['status'] as String,
      type: json['type'] as String,
      visibility: json['visibility'] as String,
      publishAt: json['publishAt'] as String?,
      manufacturerName: json['manufacturerName'] as String,
      manufacturerBrand: json['manufacturerBrand'] as String,
      price: double.parse(json['price'].toString()),
      currency: json['currency'] as String,
      discount:
          json['discount'] != null
              ? double.parse(json['discount'].toString())
              : null,
      images:
          (json['images'] as List<dynamic>?)
              ?.map((img) => ProductImage.fromJson(img as Map<String, dynamic>))
              .toList() ??
          [],
      variants:
          (json['variants'] as List<dynamic>?)
              ?.map(
                (variant) =>
                    ProductVariant.fromJson(variant as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': id,
      'name': name,
      'description': description,
      'category': category,
      'tags': tags,
      'shortDescription': shortDescription,
      'status': status,
      'type': type,
      'visibility': visibility,
      'publishAt': publishAt,
      'manufacturerName': manufacturerName,
      'manufacturerBrand': manufacturerBrand,
      'price': price.toString(),
      'currency': currency,
      'discount': discount?.toString(),
      'images': images.map((img) => img.toJson()).toList(),
      'variants': variants.map((variant) => variant.toJson()).toList(),
    };
  }

  // Helper methods
  bool get isAvailable => status == 'AVAILABLE';
  bool get isPublished => type == 'PUBLISHED';
  bool get isPublic => visibility == 'public';

  double getDiscountedPrice() {
    return discount ?? price;
  }

  double getSavingsAmount() {
    if (discount == null) return 0.0;
    return price - discount!;
  }

  double getSavingsPercentage() {
    if (discount == null) return 0.0;
    return ((price - discount!) / price) * 100;
  }

  bool hasDiscount() {
    return discount != null && discount! < price;
  }

  String get primaryImageUrl {
    return images.isNotEmpty ? images.first.link : '';
  }

  List<String> get imageUrls {
    return images.map((img) => img.link).toList();
  }

  // For backwards compatibility with existing cart logic
  bool isInStock() {
    // Since the API doesn't provide stock quantity, assume available products are in stock
    return isAvailable;
  }

  // For backwards compatibility - assuming infinite stock for available products
  int get stockQuantity => isAvailable ? 999999 : 0;

  // For backwards compatibility - assuming available products are featured
  bool get isFeatured => isAvailable && isPublished;
}
