class WawuAfricaCategory {
  final int id;
  final String name;
  final String imageUrl;

  WawuAfricaCategory({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory WawuAfricaCategory.fromJson(Map<String, dynamic> json) {
    return WawuAfricaCategory(
      id: json['id'],
      name: json['name'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
    };
  }
}

class WawuAfricaSubCategory {
  final int id;
  final int wawuAfricaCategoryId;
  final String name;

  WawuAfricaSubCategory({
    required this.id,
    required this.wawuAfricaCategoryId,
    required this.name,
  });

  factory WawuAfricaSubCategory.fromJson(Map<String, dynamic> json) {
    return WawuAfricaSubCategory(
      id: json['id'],
      wawuAfricaCategoryId: json['wawu_africa_category_id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wawu_africa_category_id': wawuAfricaCategoryId,
      'name': name,
    };
  }
}

class WawuAfricaInstitution {
  final int id;
  final int wawuAfricaSubCategoryId;
  final String name;
  final String description;
  final String profileImageUrl;
  final String coverImageUrl;

  WawuAfricaInstitution({
    required this.id,
    required this.wawuAfricaSubCategoryId,
    required this.name,
    required this.description,
    required this.profileImageUrl,
    required this.coverImageUrl,
  });

  factory WawuAfricaInstitution.fromJson(Map<String, dynamic> json) {
    return WawuAfricaInstitution(
      id: json['id'],
      wawuAfricaSubCategoryId: json['wawu_africa_sub_category_id'],
      name: json['name'],
      description: json['description'],
      profileImageUrl: json['profile_image_url'],
      coverImageUrl: json['cover_image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wawu_africa_sub_category_id': wawuAfricaSubCategoryId,
      'name': name,
      'description': description,
      'profile_image_url': profileImageUrl,
      'cover_image_url': coverImageUrl,
    };
  }
}

class WawuAfricaInstitutionContent {
  final int id;
  final int wawuAfricaInstitutionId;
  final String name;
  final String imageUrl;
  final String description;
  final String requirements;
  final String keyBenefits;

  WawuAfricaInstitutionContent({
    required this.id,
    required this.wawuAfricaInstitutionId,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.requirements,
    required this.keyBenefits,
  });

  factory WawuAfricaInstitutionContent.fromJson(Map<String, dynamic> json) {
    return WawuAfricaInstitutionContent(
      id: json['id'],
      wawuAfricaInstitutionId: json['wawu_africa_institution_id'],
      name: json['name'],
      imageUrl: json['image_url'],
      description: json['description'],
      requirements: json['requirements'],
      keyBenefits: json['key_benefits'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wawu_africa_institution_id': wawuAfricaInstitutionId,
      'name': name,
      'image_url': imageUrl,
      'description': description,
      'requirements': requirements,
      'key_benefits': keyBenefits,
    };
  }
}

class WawuAfricaUserContentRegistration {
  final int id;
  final String userId;
  final String userFullName;
  final String userEmail;
  final int wawuAfricaInstitutionContentId;
  final DateTime registrationDate;

  WawuAfricaUserContentRegistration({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.userEmail,
    required this.wawuAfricaInstitutionContentId,
    required this.registrationDate,
  });

  factory WawuAfricaUserContentRegistration.fromJson(Map<String, dynamic> json) {
    return WawuAfricaUserContentRegistration(
      id: json['id'],
      userId: json['user_id'],
      userFullName: json['user_full_name'],
      userEmail: json['user_email'],
      wawuAfricaInstitutionContentId: json['wawu_africa_institution_content_id'],
      registrationDate: DateTime.parse(json['registration_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_full_name': userFullName,
      'user_email': userEmail,
      'wawu_africa_institution_content_id': wawuAfricaInstitutionContentId,
      'registration_date': registrationDate.toIso8601String(),
    };
  }
}