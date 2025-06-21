// lib/models/user.dart

// Keep this if you use jsonEncode/jsonDecode elsewhere, otherwise can remove

class User {
  final String uuid;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
  final DateTime? emailVerifiedAt;
  final String? jobType;
  final String? type;
  final String? location; // Assuming 'address' in JSON maps to 'location' in your model
  final String? professionalRole;
  final String? country;
  final String? state;
  final DateTime? createdAt;
  final String? status;
  final String? profileImage; // REVERTED to String? - will store the 'link'
  final String? coverImage;   // REVERTED to String? - will store the 'link'
  final String? role;
  final int? profileCompletionRate;
  final String? referralCode;
  final String? referredBy;
  final bool? isSubscribed;
  final bool? termsAccepted;
  final AdditionalInfo? additionalInfo;
  final List<Portfolio>? portfolios;
  final List<DeliveryAddress>? deliveryAddresses;
  final String? token;

  User({
    required this.uuid,
    this.firstName,
    this.lastName,
    required this.email,
    this.phoneNumber,
    this.emailVerifiedAt,
    this.jobType,
    this.type,
    this.location,
    this.professionalRole,
    this.country,
    this.state,
    required this.createdAt,
    this.status,
    this.profileImage, // Now String?
    this.coverImage,   // Now String?
    this.role,
    this.profileCompletionRate,
    this.referralCode,
    this.referredBy,
    this.isSubscribed,
    this.termsAccepted,
    this.additionalInfo,
    this.portfolios,
    this.deliveryAddresses,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final uuid = json['uuid'];
    if (uuid == null) {
      throw FormatException('Missing required field: uuid');
    }
    final email = json['email'];
    if (email == null) {
      throw FormatException('Missing required field: email');
    }
    final createdAtStr = json['createdAt'];
    if (createdAtStr == null) {
      throw FormatException('Missing required field: createdAt');
    }
    DateTime createdAt;
    try {
      createdAt = DateTime.parse(createdAtStr);
    } catch (e) {
      throw FormatException('Invalid createdAt format: $createdAtStr');
    }

    return User(
      uuid: uuid as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: email as String,
      phoneNumber: json['phoneNumber'] as String?,
      emailVerifiedAt: json['emailVerifiedAt'] != null
          ? DateTime.tryParse(json['emailVerifiedAt'])
          : null,
      jobType: json['jobType'] as String?,
      type: json['type'] as String?,
      location: json['address'] as String?, // Mapping 'address' from JSON to 'location'
      professionalRole: json['professionalRole'] as String?,
      country: json['country'] as String?,
      state: json['state'] as String?,
      createdAt: createdAt,
      status: json['status'] as String?,
      // CORRECTED: Extracting only the 'link' for profileImage
      profileImage: (json['profileImage'] is Map<String, dynamic>)
          ? (json['profileImage'] as Map<String, dynamic>)['link'] as String?
          : null,
      // CORRECTED: Extracting only the 'link' for coverImage
      coverImage: (json['coverImage'] is Map<String, dynamic>)
          ? (json['coverImage'] as Map<String, dynamic>)['link'] as String?
          : null,
      role: json['role'] as String?,
      profileCompletionRate: json['profileCompletionRate'] as int?,
      referralCode: json['referralCode'] as String?,
      referredBy: json['referredBy'] as String?,
      isSubscribed: json['isSubscribed'] as bool?,
      termsAccepted: json['termsAccepted'] as bool?,
      additionalInfo: json['additionalInfo'] != null && json['additionalInfo'] is Map
          ? AdditionalInfo.fromJson(json['additionalInfo'] as Map<String, dynamic>)
          : null,
      portfolios: (json['portfolios'] as List<dynamic>?)
              ?.map((e) => Portfolio.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      deliveryAddresses: (json['deliveryAddresses'] as List<dynamic>?)
              ?.map((e) => DeliveryAddress.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phoneNumber': phoneNumber,
        'emailVerifiedAt': emailVerifiedAt?.toIso8601String(),
        'jobType': jobType,
        'type': type,
        'address': location, // Mapping 'location' back to 'address' for JSON
        'professionalRole': professionalRole,
        'country': country,
        'state': state,
        'createdAt': createdAt?.toIso8601String(),
        'status': status,
        // When converting to JSON, if you expect the backend to receive the full object,
        // you'd need to convert the String link back into an ImageInfo object.
        // However, if the backend just needs the link, this is sufficient.
        // For now, assuming you just send the string link back if that's what's stored.
        'profileImage': profileImage, // Now String
        'coverImage': coverImage,     // Now String
        'role': role,
        'profileCompletionRate': profileCompletionRate,
        'referralCode': referralCode,
        'referredBy': referredBy,
        'isSubscribed': isSubscribed,
        'termsAccepted': termsAccepted,
        'additionalInfo': additionalInfo?.toJson(),
        'portfolios': portfolios?.map((e) => e.toJson()).toList(),
        'deliveryAddresses': deliveryAddresses?.map((e) => e.toJson()).toList(),
        'token': token,
      };

  User copyWith({
    String? uuid,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    DateTime? emailVerifiedAt,
    String? jobType,
    String? type,
    String? location,
    String? professionalRole,
    String? country,
    String? state,
    DateTime? createdAt,
    String? status,
    String? profileImage, // REVERTED type in copyWith
    String? coverImage,   // REVERTED type in copyWith
    String? role,
    int? profileCompletionRate,
    String? referralCode,
    String? referredBy,
    bool? isSubscribed,
    bool? termsAccepted,
    AdditionalInfo? additionalInfo,
    List<Portfolio>? portfolios,
    List<DeliveryAddress>? deliveryAddresses,
    String? token,
  }) {
    return User(
      uuid: uuid ?? this.uuid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      jobType: jobType ?? this.jobType,
      type: type ?? this.type,
      location: location ?? this.location,
      professionalRole: professionalRole ?? this.professionalRole,
      country: country ?? this.country,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      profileImage: profileImage ?? this.profileImage, // Use original type
      coverImage: coverImage ?? this.coverImage,     // Use original type
      role: role ?? this.role,
      profileCompletionRate: profileCompletionRate ?? this.profileCompletionRate,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      portfolios: portfolios ?? this.portfolios,
      deliveryAddresses: deliveryAddresses ?? this.deliveryAddresses,
      token: token ?? this.token,
    );
  }
}

// --- Nested Models (These were largely correct and are kept) ---

// Represents the {name: ..., link: ...} structure for files like professionalCertifications
// This model IS still needed because `file` fields within other objects ARE {name: ..., link: ...}
class ImageInfo {
  final String? name;
  final String? link;

  ImageInfo({this.name, this.link});

  factory ImageInfo.fromJson(Map<String, dynamic> json) {
    return ImageInfo(
      name: json['name'] as String?,
      link: json['link'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'link': link,
      };
}

// Represents the professionalCertification object structure
class ProfessionalCertification {
  final String? name;
  final String? organization;
  final String? endDate;
  final ImageInfo? file; // This 'file' IS the {name: ..., link: ...} structure

  ProfessionalCertification({
    this.name,
    this.organization,
    this.endDate,
    this.file,
  });

  factory ProfessionalCertification.fromJson(Map<String, dynamic> json) {
    return ProfessionalCertification(
      name: json['name'] as String?,
      organization: json['organization'] as String?,
      endDate: json['endDate'] as String?,
      file: json['file'] != null && json['file'] is Map
          ? ImageInfo.fromJson(json['file'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'organization': organization,
        'endDate': endDate,
        'file': file?.toJson(),
      };
}

// Represents the meansOfIdentification object structure
class MeansOfIdentification {
  final ImageInfo? file; // This 'file' IS the {name: ..., link: ...} structure

  MeansOfIdentification({this.file});

  factory MeansOfIdentification.fromJson(Map<String, dynamic> json) {
    return MeansOfIdentification(
      file: json['file'] != null && json['file'] is Map
          ? ImageInfo.fromJson(json['file'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'file': file?.toJson(),
      };
}

// Represents the subCategories structure inside AdditionalInfo
class ServiceSubCategory {
  final String? uuid;
  final String? name;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? pivot; // Generic map for pivot table data
  final String? serviceCategory; // Assuming this is a simple string, adjust if it's an object

  ServiceSubCategory({
    this.uuid,
    this.name,
    this.createdAt,
    this.updatedAt,
    this.pivot,
    this.serviceCategory,
  });

  factory ServiceSubCategory.fromJson(Map<String, dynamic> json) {
    return ServiceSubCategory(
      uuid: json['uuid'] as String?,
      name: json['name'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      pivot: json['pivot'] as Map<String, dynamic>?,
      serviceCategory: json['serviceCategory'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'name': name,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'pivot': pivot,
        'serviceCategory': serviceCategory,
      };
}

class AdditionalInfo {
  final String? about; // Matches your backend data
  final String? bio; // If backend has 'bio' instead of 'about'
  final List<String>? skills;
  final List<ServiceSubCategory>? subCategories;
  final String? preferredLanguage;
  final List<Education>? education;
  final List<ProfessionalCertification>? professionalCertification; // List of objects
  final MeansOfIdentification? meansOfIdentification; // Object
  final Map<String, String>? socialHandles; // Map of social media links
  final String? language; // If language comes outside preferredLanguage
  final String? website;

  AdditionalInfo({
    this.about,
    this.bio,
    this.skills,
    this.subCategories,
    this.preferredLanguage,
    this.education,
    this.professionalCertification,
    this.meansOfIdentification,
    this.socialHandles,
    this.language,
    this.website,
  });

  factory AdditionalInfo.fromJson(Map<String, dynamic>? json) {  // Changed to Map<String, dynamic>? to handle null input
    if (json == null) {
      return AdditionalInfo();  // Return a default instance if json is null
    }
    Map<String, String>? parseSocialHandles(Map<String, dynamic>? socialJson) {
      if (socialJson == null) return null;
      return socialJson.map((key, value) => MapEntry(key, value.toString()));
    }
    return AdditionalInfo(
      about: json['about'] as String?,
      bio: json['bio'] as String?,
      skills: (json['skills'] is List) ? (json['skills'] as List<dynamic>?)?.map((e) => e?.toString()).whereType<String>().toList() : null,
      subCategories: (json['subCategories'] is List) ? (json['subCategories'] as List<dynamic>?)?.map((e) => e is Map<String, dynamic> ? ServiceSubCategory.fromJson(e) : null).whereType<ServiceSubCategory>().toList() : null,
      preferredLanguage: json['preferredLanguage'] as String?,
      education: (json['education'] is List) ? (json['education'] as List<dynamic>?)?.map((e) => e is Map<String, dynamic> ? Education.fromJson(e) : null).whereType<Education>().toList() : null,
      professionalCertification: (json['professionalCertification'] is List) ? (json['professionalCertification'] as List<dynamic>?)?.map((e) => e is Map<String, dynamic> ? ProfessionalCertification.fromJson(e) : null).whereType<ProfessionalCertification>().toList() : null,
      meansOfIdentification: (json['meansOfIdentification'] is Map<String, dynamic>) ? MeansOfIdentification.fromJson(json['meansOfIdentification'] as Map<String, dynamic>) : null,
      socialHandles: (json['socialHandles'] is Map) ? parseSocialHandles(json['socialHandles'] as Map<String, dynamic>) : null,
      language: json['language'] as String?,
      website: json['website'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'about': about,
        'bio': bio,
        'skills': skills,
        'subCategories': subCategories?.map((e) => e.toJson()).toList(),
        'preferredLanguage': preferredLanguage,
        'education': education?.map((e) => e.toJson()).toList(),
        'professionalCertification':
            professionalCertification?.map((e) => e.toJson()).toList(),
        'meansOfIdentification': meansOfIdentification?.toJson(),
        'socialHandles': socialHandles,
        'language': language,
        'website': website,
      };
}

class Education {
  final String? institution; // Changed from 'school' based on your data
  final String? certification; // Changed from 'degree'
  final String? courseOfStudy; // Changed from 'fieldOfStudy'
  final String? graduationDate; // Changed from 'endYear' and type

  Education({
    this.institution,
    this.certification,
    this.courseOfStudy,
    this.graduationDate,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      institution: json['institution'] as String?,
      certification: json['certification'] as String?,
      courseOfStudy: json['courseOfStudy'] as String?,
      graduationDate: json['graduationDate']?.toString(), // Ensure it's String
    );
  }

  Map<String, dynamic> toJson() => {
        'institution': institution,
        'certification': certification,
        'courseOfStudy': courseOfStudy,
        'graduationDate': graduationDate,
      };
}

class Portfolio {
  final String? id;
  final String? title;
  final String? description;
  final String? link;
  final List<String>? images; // This should ideally be List<String> for URLs

  Portfolio({this.id, this.title, this.description, this.link, this.images});

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    return Portfolio(
      id: json['id']?.toString(), // Ensure ID is parsed as string if it's int in JSON
      title: json['title'] as String?,
      description: json['description'] as String?,
      link: json['link'] as String?,
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'link': link,
        'images': images,
      };
}

class DeliveryAddress {
  final String? id;
  final String? label;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final bool? isDefault;

  DeliveryAddress({
    this.id,
    this.label,
    this.address,
    this.city,
    this.state,
    this.country,
    this.isDefault,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      id: json['id']?.toString(), // Ensure ID is parsed as string if it's int in JSON
      label: json['label'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      isDefault: json['isDefault'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'address': address,
        'city': city,
        'state': state,
        'country': country,
        'isDefault': isDefault,
      };
}