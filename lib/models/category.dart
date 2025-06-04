class CategoryModel {
  String get id => uuid; // For provider compatibility
  final String uuid;
  final String name;
  final String? type;
  
  const CategoryModel({
    required this.uuid,
    required this.name,
    this.type,
  });
  
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
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
  final CategoryModel? serviceCategory; // Reference to parent category
  
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
          ? CategoryModel.fromJson(json['serviceCategory'] as Map<String, dynamic>)
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