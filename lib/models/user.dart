class User {
  final String uuid;
  final String? firstName;
  final String? lastName;
  final String email;
  final String? phoneNumber;
  final DateTime? emailVerifiedAt;
  final String? jobType; // e.g., artisan
  final String? type; // e.g., individual
  final String? location;
  final String? professionalRole;
  final String? country;
  final String? state;
  final DateTime createdAt;
  final String? status; // e.g., PENDING, VERIFIED, BLOCKED
  final String? profileImage;
  final String? coverImage;
  final String? role; // e.g., SELLER, BUYER, PROFESSIONAL, ARTISAN
  final int? profileCompletionRate;
  final String? referralCode;
  final String? referredBy;
  final bool? isSubscribed;
  final bool? termsAccepted;
  final AdditionalInfo? additionalInfo;
  final List<Portfolio>? portfolios;
  // Token is usually handled separately and not part of the User model itself
  // final String? token;

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
    this.additionalInfo,
    this.portfolios,
    this.termsAccepted,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uuid: json['uuid'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      emailVerifiedAt:
          json['emailVerifiedAt'] != null
              ? DateTime.tryParse(json['emailVerifiedAt'] as String)
              : null,
      jobType: json['jobType'] as String?,
      type: json['type'] as String?,
      location: json['location'] as String?,
      professionalRole: json['professionalRole'] as String?,
      country: json['country'] as String?,
      state: json['state'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as String?,
      profileImage: json['profileImage'] as String?,
      coverImage: json['coverImage'] as String?,
      role: json['role'] as String?,
      profileCompletionRate: json['profileCompletionRate'] as int?,
      referralCode: json['referralCode'] as String?,
      referredBy: json['referredBy'] as String?,
      isSubscribed: json['isSubscribed'] as bool?,
        additionalInfo:
          json['additionalInfo'] != null && (json['additionalInfo'] is Map)
              ? AdditionalInfo.fromJson(
                json['additionalInfo'] as Map<String, dynamic>,
              )
              : null,
      portfolios:
          json['portfolios'] != null && json['portfolios'] is List
              ? List<Portfolio>.from(
                (json['portfolios'] as List<dynamic>).map(
                  (item) => Portfolio.fromJson(item as Map<String, dynamic>),
                ),
              )
              : [],
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
    'additionalInfo': additionalInfo?.toJson(),
    'portfolios': portfolios?.map((p) => p.toJson()).toList(),
  };
}

class AdditionalInfo {
  final String? about;
  final List<String>? skills;
  final List<SubCategoryInfo>? subCategories;
  final String? preferredLanguage;
  final List<Education>? education;
  final List<ProfessionalCertification>? professionalCertification;
  final MeansOfIdentification? meansOfIdentification;
  final SocialHandles? socialHandles;

  AdditionalInfo({
    this.about,
    this.skills,
    this.subCategories,
    this.preferredLanguage,
    this.education,
    this.professionalCertification,
    this.meansOfIdentification,
    this.socialHandles,
  });

  factory AdditionalInfo.fromJson(Map<String, dynamic> json) {
    // Handle cases where skills or subCategories might be null or not a list
    var skillsList = json['skills'];
    List<String>? parsedSkills;
    if (skillsList is List) {
      parsedSkills = List<String>.from(
        skillsList.map((item) => item as String),
      );
    } else if (skillsList == null) {
      parsedSkills = []; // Or null, depending on desired behavior
    } else {
      // Handle unexpected type, perhaps log an error or assign default
      parsedSkills = [];
    }

    var subCategoriesList = json['subCategories'];
    List<SubCategoryInfo>? parsedSubCategories;
    if (subCategoriesList is List) {
      parsedSubCategories = List<SubCategoryInfo>.from(
        subCategoriesList.map(
          (item) => SubCategoryInfo.fromJson(item as Map<String, dynamic>),
        ),
      );
    } else if (subCategoriesList == null) {
      parsedSubCategories = [];
    } else {
      parsedSubCategories = [];
    }

    var educationList = json['education'];
    List<Education>? parsedEducation;
    if (educationList is List) {
      parsedEducation = List<Education>.from(
        educationList.map(
          (item) => Education.fromJson(item as Map<String, dynamic>),
        ),
      );
    } else if (educationList == null) {
      parsedEducation = [];
    } else {
      parsedEducation = [];
    }

    var profCertList = json['professionalCertification'];
    List<ProfessionalCertification>? parsedProfCerts;
    if (profCertList is List) {
      parsedProfCerts = List<ProfessionalCertification>.from(
        profCertList.map(
          (item) =>
              ProfessionalCertification.fromJson(item as Map<String, dynamic>),
        ),
      );
    } else if (profCertList == null) {
      parsedProfCerts = [];
    } else {
      parsedProfCerts = [];
    }

    return AdditionalInfo(
      about: json['about'] as String?,
      skills: parsedSkills,
      subCategories: parsedSubCategories,
      preferredLanguage: json['preferredLanguage'] as String?,
      education: parsedEducation,
      professionalCertification: parsedProfCerts,
      meansOfIdentification:
          json['meansOfIdentification'] != null &&
                  (json['meansOfIdentification'] is Map)
              ? MeansOfIdentification.fromJson(
                json['meansOfIdentification'] as Map<String, dynamic>,
              )
              : null,
      socialHandles:
          json['socialHandles'] != null && (json['socialHandles'] is Map)
              ? SocialHandles.fromJson(
                json['socialHandles'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'about': about,
    'skills': skills,
    'subCategories': subCategories?.map((s) => s.toJson()).toList(),
    'preferredLanguage': preferredLanguage,
    'education': education?.map((e) => e.toJson()).toList(),
    'professionalCertification':
        professionalCertification?.map((p) => p.toJson()).toList(),
    'meansOfIdentification': meansOfIdentification?.toJson(),
    'socialHandles': socialHandles?.toJson(),
  };
}

class SubCategoryInfo {
  final String uuid;
  final String name;
  // Add other fields if present in API (e.g., serviceCategory)

  SubCategoryInfo({required this.uuid, required this.name});

  factory SubCategoryInfo.fromJson(Map<String, dynamic> json) {
    return SubCategoryInfo(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
    );
  }
  Map<String, dynamic> toJson() => {'uuid': uuid, 'name': name};
}

class Education {
  final String? institution;
  final String? certification;
  final String? courseOfStudy;
  final String? graduationDate; // API shows year, consider String or int

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
      graduationDate:
          json['graduationDate'] as String?, // Assuming string for now
    );
  }

  Map<String, dynamic> toJson() => {
    'institution': institution,
    'certification': certification,
    'courseOfStudy': courseOfStudy,
    'graduationDate': graduationDate,
  };
}

class ProfessionalCertification {
  final String? name;
  final String? organization;
  final String? endDate; // API shows date string, consider DateTime if needed
  final FileLink? file;

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
      file:
          json['file'] != null && (json['file'] is Map)
              ? FileLink.fromJson(json['file'] as Map<String, dynamic>)
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

class MeansOfIdentification {
  final FileLink? file;

  MeansOfIdentification({this.file});

  factory MeansOfIdentification.fromJson(Map<String, dynamic> json) {
    // The structure from API sample is: "meansOfIdentification": { "file": { "name": "myId.png", "link": "..." } }
    // So, directly check for 'file' object inside.
    if (json.containsKey('file') &&
        json['file'] != null &&
        json['file'] is Map) {
      return MeansOfIdentification(
        file: FileLink.fromJson(json['file'] as Map<String, dynamic>),
      );
    }
    // Older sample had direct name/link, but updated profile shows nested file.
    // This handles the case where 'file' might be null directly under meansOfIdentification
    return MeansOfIdentification(file: null);
  }

  Map<String, dynamic> toJson() => {'file': file?.toJson()};
}

class SocialHandles {
  final String? twitter;
  final String? facebook;
  final String? linkedIn;
  final String? instagram;

  SocialHandles({this.twitter, this.facebook, this.linkedIn, this.instagram});

  factory SocialHandles.fromJson(Map<String, dynamic> json) {
    return SocialHandles(
      twitter: json['twitter'] as String?,
      facebook: json['facebook'] as String?,
      linkedIn: json['linkedIn'] as String?,
      instagram: json['instagram'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'twitter': twitter,
    'facebook': facebook,
    'linkedIn': linkedIn,
    'instagram': instagram,
  };
}

class FileLink {
  final String name;
  final String link;

  FileLink({required this.name, required this.link});

  factory FileLink.fromJson(Map<String, dynamic> json) {
    return FileLink(name: json['name'] as String, link: json['link'] as String);
  }

  Map<String, dynamic> toJson() => {'name': name, 'link': link};
}

class Portfolio {
  // Define fields for Portfolio based on API structure if available
  // For now, a placeholder
  final String? id;
  final String? title;
  final String? description;
  final String? imageUrl;

  Portfolio({this.id, this.title, this.description, this.imageUrl});

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    return Portfolio(
      id: json['id'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'imageUrl': imageUrl,
  };
}
