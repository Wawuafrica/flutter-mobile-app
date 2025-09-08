import 'package:flutter/foundation.dart' show kIsWeb;

// Helper function to proxy URLs for web to avoid CORS errors
String _proxyUrlForWeb(String url) {
  if (kIsWeb && url.isNotEmpty && !url.startsWith('http://localhost')) {
    if (url.startsWith('https://corsproxy.io/?')) {
      return url;
    }
    return 'https://corsproxy.io/?${Uri.encodeComponent(url)}';
  }
  return url;
}

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
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      imageUrl: _proxyUrlForWeb(json['image_url'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'image_url': imageUrl};
  }
}

class WawuAfricaSubCategory {
  final int id;
  final int wawuAfricaCategoryId;
  final String name;
  final String imageUrl;

  WawuAfricaSubCategory({
    required this.id,
    required this.wawuAfricaCategoryId,
    required this.name,
    required this.imageUrl,
  });

  factory WawuAfricaSubCategory.fromJson(Map<String, dynamic> json) {
    return WawuAfricaSubCategory(
      id: json['id'] as int? ?? 0,
      wawuAfricaCategoryId: json['wawu_africa_category_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      imageUrl: _proxyUrlForWeb(json['image_url'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wawu_africa_category_id': wawuAfricaCategoryId,
      'name': name,
      'image_url': imageUrl,
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
      id: json['id'] as int? ?? 0,
      wawuAfricaSubCategoryId: json['wawu_africa_sub_category_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      profileImageUrl: _proxyUrlForWeb(
        json['profile_image_url'] as String? ?? '',
      ),
      coverImageUrl: _proxyUrlForWeb(json['cover_image_url'] as String? ?? ''),
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
      id: json['id'] as int? ?? 0,
      wawuAfricaInstitutionId: json['wawu_africa_institution_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      imageUrl: _proxyUrlForWeb(json['image_url'] as String? ?? ''),
      description: json['description'] as String? ?? '',
      requirements: json['requirements'] as String? ?? '',
      keyBenefits: json['key_benefits'] as String? ?? '',
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

  factory WawuAfricaUserContentRegistration.fromJson(
    Map<String, dynamic> json,
  ) {
    return WawuAfricaUserContentRegistration(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as String? ?? '',
      userFullName: json['user_full_name'] as String? ?? '',
      userEmail: json['user_email'] as String? ?? '',
      wawuAfricaInstitutionContentId:
          json['wawu_africa_institution_content_id'] as int? ?? 0,
      registrationDate:
          json['registration_date'] != null
              ? DateTime.tryParse(json['registration_date']) ?? DateTime.now()
              : DateTime.now(),
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
