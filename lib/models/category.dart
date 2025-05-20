class Category {
  final String uuid;
  final String name;
  final String? slug;
  final String? description;
  final String? icon;
  
  const Category({
    required this.uuid,
    required this.name,
    this.slug,
    this.description,
    this.icon,
  });
  
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      uuid: json['uuid'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      icon: json['icon'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'slug': slug,
      'description': description,
      'icon': icon,
    };
  }
}

class SubCategory {
  final String uuid;
  final String name;
  final String? slug;
  final String? description;
  final String? icon;
  final String? categoryId; // Reference to parent category
  
  const SubCategory({
    required this.uuid,
    required this.name,
    this.slug,
    this.description,
    this.icon,
    this.categoryId,
  });
  
  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      uuid: json['uuid'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      icon: json['icon'],
      categoryId: json['category_id'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'slug': slug,
      'description': description,
      'icon': icon,
      'category_id': categoryId,
    };
  }
}

class Service {
  final String uuid;
  final String name;
  final String? description;
  final String? subCategoryId; // Reference to parent sub-category
  
  const Service({
    required this.uuid,
    required this.name,
    this.description,
    this.subCategoryId,
  });
  
  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      uuid: json['uuid'],
      name: json['name'],
      description: json['description'],
      subCategoryId: json['subcategory_id'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'description': description,
      'subcategory_id': subCategoryId,
    };
  }
}
