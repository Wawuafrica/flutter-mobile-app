class User {
  final String uuid;
  final String? firstName;
  final String? lastName;
  final String email;
  final String? phoneNumber;
  final DateTime? emailVerifiedAt;
  final String? jobType;
  final String? type;
  final String? location;
  final String? professionalRole;
  final String? country;
  final String? state;
  final DateTime createdAt;
  final String? status;
  final String? profileImage;
  final String? coverImage;
  final String? role;
  final int? profileCompletionRate;
  final String? referralCode;
  final String? referredBy;
  final bool? isSubscribed;
  final bool? termsAccepted;
  final AdditionalInfo? additionalInfo;
  final List<Portfolio>? portfolios;
  final List<DeliveryAddress>? deliveryAddresses;

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
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uuid: json['uuid'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      emailVerifiedAt: json['emailVerifiedAt'] != null
          ? DateTime.tryParse(json['emailVerifiedAt'])
          : null,
      jobType: json['jobType'] as String?,
      type: json['type'] as String?,
      location: json['location'] as String?,
      professionalRole: json['professionalRole'] as String?,
      country: json['country'] as String?,
      state: json['state'] as String?,
      createdAt: DateTime.parse(json['createdAt']),
      status: json['status'] as String?,
      profileImage: json['profileImage'] as String?,
      coverImage: json['coverImage'] as String?,
      role: json['role'] as String?,
      profileCompletionRate: json['profileCompletionRate'] as int?,
      referralCode: json['referralCode'] as String?,
      referredBy: json['referredBy'] as String?,
      isSubscribed: json['isSubscribed'] as bool?,
      termsAccepted: json['termsAccepted'] as bool?,
      additionalInfo: json['additionalInfo'] != null
          ? AdditionalInfo.fromJson(json['additionalInfo'])
          : null,
      portfolios: (json['portfolios'] as List<dynamic>?)
              ?.map((e) => Portfolio.fromJson(e))
              .toList() ??
          [],
      deliveryAddresses: (json['deliveryAddresses'] as List<dynamic>?)
              ?.map((e) => DeliveryAddress.fromJson(e))
              .toList() ??
          [],
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
        'createdAt': createdAt.toIso8601String(),
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
      };
}

class AdditionalInfo {
  final String? bio;
  final String? language;
  final String? website;
  final List<Education>? education;

  AdditionalInfo({
    this.bio,
    this.language,
    this.website,
    this.education,
  });

  factory AdditionalInfo.fromJson(Map<String, dynamic> json) {
    return AdditionalInfo(
      bio: json['bio'] as String?,
      language: json['language'] as String?,
      website: json['website'] as String?,
      education: (json['education'] as List<dynamic>?)
              ?.map((e) => Education.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'bio': bio,
        'language': language,
        'website': website,
        'education': education?.map((e) => e.toJson()).toList(),
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
  final List<String>? images;

  Portfolio({
    this.id,
    this.title,
    this.description,
    this.link,
    this.images,
  });

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
