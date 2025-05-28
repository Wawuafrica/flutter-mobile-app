class Category {
  String get id => uuid; // For provider compatibility
  final String uuid;
  final String name;
  final String? type;
  
  const Category({
    required this.uuid,
    required this.name,
    this.type,
  });
  
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      uuid: json['uuid'],
      name: json['name'],
      type: json['type'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'type': type,
    };
  }
}

class SubCategory {
  String get id => uuid; // For provider compatibility
  final String uuid;
  final String name;
  final Category? serviceCategory; // Reference to parent category
  
  const SubCategory({
    required this.uuid,
    required this.name,
    this.serviceCategory,
  });
  
  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      uuid: json['uuid'],
      name: json['name'],
      serviceCategory: json['serviceCategory'] != null
          ? Category.fromJson(json['serviceCategory'] as Map<String, dynamic>)
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'serviceCategory': serviceCategory?.toJson(),
    };
  }
}

class Service {
  String get id => uuid; // For provider compatibility
  final String uuid;
  final String name;
  final String? subCategoryId; // Reference to parent sub-category
  
  const Service({
    required this.uuid,
    required this.name,
    this.subCategoryId,
  });
  
  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      uuid: json['uuid'],
      name: json['name'],
      subCategoryId: json['service_sub_category_id'] ?? json['subcategory_id'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'service_sub_category_id': subCategoryId,
    };
  }
}