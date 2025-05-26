// lib/models/user.dart

// import 'dart:convert'; // Added for jsonEncode/jsonDecode if you use it directly here, though typically used in services

class User {
  final String uuid;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
  final DateTime? emailVerifiedAt;
  final String? jobType;
  final String? type; // Keeping this here as it's in your provided model, though 'role' is newer
  final String? location;
  final String? professionalRole;
  final String? country;
  final String? state;
  final DateTime? createdAt;
  final String? status;
  final String? profileImage;
  final String? coverImage;
  final String? role; // This is the new field for account type
  final int? profileCompletionRate;
  final String? referralCode;
  final String? referredBy;
  final bool? isSubscribed;
  final bool? termsAccepted;
  final AdditionalInfo? additionalInfo;
  final List<Portfolio>? portfolios;
  final List<DeliveryAddress>? deliveryAddresses;
  // If your API response sends a 'token' directly within the user object, add it here:
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
    this.profileImage,
    this.coverImage,
    this.role,
    this.profileCompletionRate,
    this.referralCode,
    this.referredBy,
    this.isSubscribed,
    this.termsAccepted,
    this.additionalInfo,
    this.portfolios,
    this.deliveryAddresses,
    this.token, // Added token here
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
      emailVerifiedAt:
          json['emailVerifiedAt'] != null
              ? DateTime.tryParse(json['emailVerifiedAt'])
              : null,
      jobType: json['jobType'] as String?,
      type: json['type'] as String?, // Keep 'type' if it's still in some responses
      location: json['location'] as String?,
      professionalRole: json['professionalRole'] as String?,
      country: json['country'] as String?,
      state: json['state'] as String?,
      createdAt: createdAt,
      status: json['status'] as String?,
      profileImage: json['profileImage'] as String?,
      coverImage: json['coverImage'] as String?,
      role: json['role'] as String?, // This maps to the 'role' from your latest backend response
      profileCompletionRate: json['profileCompletionRate'] as int?,
      referralCode: json['referralCode'] as String?,
      referredBy: json['referredBy'] as String?,
      isSubscribed: json['isSubscribed'] as bool?,
      termsAccepted: json['termsAccepted'] as bool?,
      additionalInfo:
          json['additionalInfo'] != null && json['additionalInfo'] is Map
              ? AdditionalInfo.fromJson(json['additionalInfo'])
              : null,
      portfolios:
          (json['portfolios'] as List<dynamic>?)
              ?.map((e) => Portfolio.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      deliveryAddresses:
          (json['deliveryAddresses'] as List<dynamic>?)
              ?.map((e) => DeliveryAddress.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      token: json['token'] as String?, // Parse token if it comes with user data
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
    'location': location,
    'professionalRole': professionalRole,
    'country': country,
    'state': state,
    'createdAt': createdAt?.toIso8601String(),
    'status': status,
    'profileImage': profileImage,
    'coverImage': coverImage,
    'role': role,
    'profileCompletionRate': profileCompletionRate,
    'referralCode': referralCode,
    'referredBy': referredBy,
    'isSubscribed': isSubscribed,
    'termsAccepted': termsAccepted,
    'additionalInfo': additionalInfo?.toJson(),
    'portfolios': portfolios?.map((e) => e.toJson()).toList(),
    'deliveryAddresses': deliveryAddresses?.map((e) => e.toJson()).toList(),
    'token': token, // Include token in toJson if it's part of the user object
  };

  // copyWith method for convenient object updates
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
    String? profileImage,
    String? coverImage,
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
      profileImage: profileImage ?? this.profileImage,
      coverImage: coverImage ?? this.coverImage,
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

class AdditionalInfo {
  final String? bio;
  final String? language;
  final String? website;
  final List<Education>? education;
  // Add other fields from backend 'additionalInfo' if any, e.g., skills, certifications
  final List<String>? skills;
  final List<String>? professionalCertification; // Assuming this is a list of strings/objects
  final String? preferredLanguage; // Assuming this maps to language
  final String? about; // Matches your backend data

  AdditionalInfo({
    this.bio,
    this.language,
    this.website,
    this.education,
    this.skills,
    this.professionalCertification,
    this.preferredLanguage,
    this.about,
  });

  factory AdditionalInfo.fromJson(Map<String, dynamic> json) {
    return AdditionalInfo(
      bio: json['bio'] as String?,
      language: json['language'] as String?, // Might map to preferredLanguage
      website: json['website'] as String?,
      education: (json['education'] as List<dynamic>?)
              ?.map((e) => Education.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      // Map new fields from backend response
      skills: (json['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      professionalCertification: (json['professionalCertification'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      preferredLanguage: json['preferredLanguage'] as String?,
      about: json['about'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'bio': bio,
    'language': language,
    'website': website,
    'education': education?.map((e) => e.toJson()).toList(),
    'skills': skills,
    'professionalCertification': professionalCertification,
    'preferredLanguage': preferredLanguage,
    'about': about,
  };
}

class Education {
  final String? school;
  final String? degree;
  final String? fieldOfStudy;
  final String? startYear;
  final String? endYear;

  Education({
    this.school,
    this.degree,
    this.fieldOfStudy,
    this.startYear,
    this.endYear,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      school: json['school'] as String?,
      degree: json['degree'] as String?,
      fieldOfStudy: json['fieldOfStudy'] as String?,
      startYear: json['startYear']?.toString(),
      endYear: json['endYear']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'school': school,
    'degree': degree,
    'fieldOfStudy': fieldOfStudy,
    'startYear': startYear,
    'endYear': endYear,
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
      id: json['id'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      link: json['link'] as String?,
      images:
          (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
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
      id: json['id'] as String?,
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