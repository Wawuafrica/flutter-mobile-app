import 'package:flutter/foundation.dart';

class Seller {
  final String uuid;
  final String firstName;
  final String lastName;
  final String? email;
  final String? profileImage;

  Seller({
    required this.uuid,
    required this.firstName,
    required this.lastName,
    this.email,
    this.profileImage,
  });

  factory Seller.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return Seller(uuid: '', firstName: 'Unknown', lastName: 'Seller');
    }

    // Handle profileImage - it can be either a string or an object
    String? profileImageUrl;
    try {
      if (json['profileImage'] != null) {
        if (json['profileImage'] is String) {
          profileImageUrl = json['profileImage'] as String;
        } else if (json['profileImage'] is Map<String, dynamic>) {
          final imageData = json['profileImage'] as Map<String, dynamic>;
          profileImageUrl = imageData['link'] as String?;
        }
      }
    } catch (e) {
      debugPrint('Error parsing profileImage: $e');
      profileImageUrl = null;
    }

    return Seller(
      uuid: json['uuid']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? 'Unknown',
      lastName: json['lastName']?.toString() ?? 'Seller',
      email: json['email']?.toString(),
      profileImage: profileImageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'firstName': firstName,
      'lastName': lastName,
      if (email != null) 'email': email,
      if (profileImage != null) 'profileImage': profileImage,
    };
  }

  String get fullName => '$firstName $lastName';
}

class Gig {
  final String uuid;
  final String title;
  final String description;
  final String keywords;
  final String about;
  final Seller seller;
  final List<Service> services;
  final List<Pricing> pricings;
  final List<Faq> faqs;
  final Assets assets;
  final String status;
  final List<Review> reviews;

  Gig({
    required this.uuid,
    required this.title,
    required this.description,
    required this.keywords,
    required this.about,
    required this.seller,
    required this.services,
    required this.pricings,
    required this.faqs,
    required this.assets,
    required this.status,
    required this.reviews,
  });

  factory Gig.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return Gig(
        uuid: '',
        title: 'No Title',
        description: '',
        keywords: '',
        about: '',
        seller: Seller.fromJson(null),
        services: [],
        pricings: [],
        faqs: [],
        assets: Assets.fromJson(null),
        status: 'PENDING',
        reviews: [],
      );
    }

    // Handle seller data with extra safety
    Seller seller;
    try {
      seller = Seller.fromJson(json['seller'] as Map<String, dynamic>?);
    } catch (e) {
      debugPrint('Error parsing seller data: $e');
      seller = Seller.fromJson(null);
    }

    // Handle services with extra safety
    List<Service> services = [];
    try {
      if (json['services'] != null && json['services'] is List) {
        services =
            (json['services'] as List<dynamic>)
                .where((e) => e != null)
                .map(
                  (e) => Service.fromJson(e is Map<String, dynamic> ? e : null),
                )
                .toList();
      }
    } catch (e) {
      debugPrint('Error parsing services: $e');
      services = [];
    }

    // Handle pricings with extra safety
    List<Pricing> pricings = [];
    try {
      if (json['pricings'] != null && json['pricings'] is List) {
        pricings =
            (json['pricings'] as List<dynamic>)
                .where((e) => e != null)
                .map(
                  (e) => Pricing.fromJson(e is Map<String, dynamic> ? e : null),
                )
                .toList();
      }
    } catch (e) {
      debugPrint('Error parsing pricings: $e');
      pricings = [];
    }

    // Handle faqs with extra safety
    List<Faq> faqs = [];
    try {
      if (json['faqs'] != null && json['faqs'] is List) {
        faqs =
            (json['faqs'] as List<dynamic>)
                .where((e) => e != null)
                .map((e) => Faq.fromJson(e is Map<String, dynamic> ? e : null))
                .toList();
      }
    } catch (e) {
      debugPrint('Error parsing faqs: $e');
      faqs = [];
    }

    // Handle reviews with extra safety
    List<Review> reviews = [];
    try {
      if (json['reviews'] != null && json['reviews'] is List) {
        reviews =
            (json['reviews'] as List<dynamic>)
                .where((e) => e != null)
                .map(
                  (e) => Review.fromJson(e is Map<String, dynamic> ? e : null),
                )
                .toList();
      }
    } catch (e) {
      debugPrint('Error parsing reviews: $e');
      reviews = [];
    }

    // Handle assets with extra safety
    Assets assets;
    try {
      assets = Assets.fromJson(json['assets'] as Map<String, dynamic>?);
    } catch (e) {
      debugPrint('Error parsing assets: $e');
      assets = Assets.fromJson(null);
    }

    return Gig(
      uuid: json['uuid']?.toString() ?? '',
      title: json['title']?.toString() ?? 'No Title',
      description: json['description']?.toString() ?? '',
      keywords: json['keywords']?.toString() ?? '',
      about: json['about']?.toString() ?? '',
      seller: seller,
      services: services,
      pricings: pricings,
      faqs: faqs,
      assets: assets,
      status: json['status']?.toString() ?? 'PENDING',
      reviews: reviews,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'title': title,
      'description': description,
      'keywords': keywords,
      'about': about,
      'seller': seller.toJson(),
      'services': services.map((s) => s.toJson()).toList(),
      'pricings': pricings.map((p) => p.toJson()).toList(),
      'faqs': faqs.map((f) => f.toJson()).toList(),
      'assets': assets.toJson(),
      'status': status,
      'reviews': reviews.map((r) => r.toJson()).toList(),
    };
  }

  DateTime get createdAt {
    try {
      if (services.isNotEmpty && services[0].createdAt.isNotEmpty) {
        return DateTime.tryParse(services[0].createdAt) ?? DateTime.now();
      }
      if (pricings.isNotEmpty && pricings[0].createdAt.isNotEmpty) {
        return DateTime.tryParse(pricings[0].createdAt) ?? DateTime.now();
      }
    } catch (e) {
      debugPrint('Error parsing createdAt: $e');
    }
    return DateTime.now();
  }

  bool isPending() => status == 'PENDING';
  bool isVerified() => status == 'VERIFIED';
  bool isArchived() => status == 'ARCHIVED';
  bool isRejected() => status == 'REJECTED';

  // Helper methods for reviews
  double get averageRating {
    if (reviews.isEmpty) return 0.0;
    try {
      final total = reviews.fold<int>(0, (sum, review) => sum + review.rating);
      return total / reviews.length;
    } catch (e) {
      debugPrint('Error calculating average rating: $e');
      return 0.0;
    }
  }

  int get totalReviews => reviews.length;
}

class Review {
  final String uuid;
  final int rating;
  final String review;
  final ReviewUser user;
  final String createdAt;

  Review({
    required this.uuid,
    required this.rating,
    required this.review,
    required this.user,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return Review(
        uuid: '',
        rating: 0,
        review: '',
        user: ReviewUser.fromJson(null),
        createdAt: '',
      );
    }

    return Review(
      uuid: json['uuid']?.toString() ?? '',
      rating: _parseToInt(json['rating']) ?? 0,
      review: json['review']?.toString() ?? '',
      user: ReviewUser.fromJson(json['user'] as Map<String, dynamic>?),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'rating': rating,
      'review': review,
      'user': user.toJson(),
      'createdAt': createdAt,
    };
  }

  DateTime get createdAtDateTime {
    try {
      return DateTime.tryParse(createdAt) ?? DateTime.now();
    } catch (e) {
      debugPrint('Error parsing createdAt: $e');
      return DateTime.now();
    }
  }
}

class ReviewUser {
  final String uuid;
  final String firstName;
  final String lastName;
  final String email;
  final String? profilePicture;

  ReviewUser({
    required this.uuid,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.profilePicture,
  });

  factory ReviewUser.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ReviewUser(
        uuid: '',
        firstName: 'Unknown',
        lastName: 'User',
        email: '',
      );
    }

    // Handle profilePicture - it can be either a string or an object
    String? profilePictureUrl;
    try {
      if (json['profilePicture'] != null) {
        if (json['profilePicture'] is String) {
          profilePictureUrl = json['profilePicture'] as String;
        } else if (json['profilePicture'] is Map<String, dynamic>) {
          final imageData = json['profilePicture'] as Map<String, dynamic>;
          profilePictureUrl = imageData['link'] as String?;
        }
      }
    } catch (e) {
      debugPrint('Error parsing profilePicture: $e');
      profilePictureUrl = null;
    }

    return ReviewUser(
      uuid: json['uuid']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? 'Unknown',
      lastName: json['lastName']?.toString() ?? 'User',
      email: json['email']?.toString() ?? '',
      profilePicture: profilePictureUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      if (profilePicture != null) 'profilePicture': profilePicture,
    };
  }

  String get fullName => '$firstName $lastName';
}

class Service {
  final String uuid;
  final String name;
  final String createdAt;
  final String? updatedAt;

  Service({
    required this.uuid,
    required this.name,
    required this.createdAt,
    this.updatedAt,
  });

  factory Service.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return Service(uuid: '', name: 'Unknown Service', createdAt: '');
    }

    return Service(
      uuid: json['uuid']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Service',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }
}

class Pricing {
  final String uuid;
  final int userId;
  final int gigId;
  final List<Feature> features;
  final String createdAt;
  final String updatedAt;
  final Package package;

  Pricing({
    required this.uuid,
    required this.userId,
    required this.gigId,
    required this.features,
    required this.createdAt,
    required this.updatedAt,
    required this.package,
  });

  factory Pricing.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return Pricing(
        uuid: '',
        userId: 0,
        gigId: 0,
        features: [],
        createdAt: '',
        updatedAt: '',
        package: Package.fromJson(null),
      );
    }

    // Handle features with extra safety
    List<Feature> features = [];
    try {
      if (json['features'] != null && json['features'] is List) {
        features =
            (json['features'] as List<dynamic>)
                .where((e) => e != null)
                .map(
                  (e) => Feature.fromJson(e is Map<String, dynamic> ? e : null),
                )
                .toList();
      }
    } catch (e) {
      debugPrint('Error parsing features: $e');
      features = [];
    }

    return Pricing(
      uuid: json['uuid']?.toString() ?? '',
      userId: _parseToInt(json['userId']) ?? 0,
      gigId: _parseToInt(json['gigId']) ?? 0,
      features: features,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      package: Package.fromJson(json['package'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'userId': userId,
      'gigId': gigId,
      'features': features.map((f) => f.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'package': package.toJson(),
    };
  }
}

class Feature {
  final String name;
  final String value;

  Feature({required this.name, required this.value});

  factory Feature.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return Feature(name: '', value: '');
    }

    return Feature(
      name: json['name']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'value': value};
  }
}

class Package {
  final String name;
  final String amount;
  final String description;

  Package({
    required this.name,
    required this.amount,
    required this.description,
  });

  factory Package.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return Package(name: 'Unknown Package', amount: '0', description: '');
    }

    return Package(
      name: json['name']?.toString() ?? 'Unknown Package',
      amount: json['amount']?.toString() ?? '0',
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'amount': amount, 'description': description};
  }
}

class Faq {
  final String uuid;
  final int userId;
  final int gigId;
  final List<Attribute> attributes;
  final String createdAt;
  final String updatedAt;

  Faq({
    required this.uuid,
    required this.userId,
    required this.gigId,
    required this.attributes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Faq.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return Faq(
        uuid: '',
        userId: 0,
        gigId: 0,
        attributes: [],
        createdAt: '',
        updatedAt: '',
      );
    }

    // Handle attributes with extra safety
    List<Attribute> attributes = [];
    try {
      if (json['attributes'] != null && json['attributes'] is List) {
        attributes =
            (json['attributes'] as List<dynamic>)
                .where((e) => e != null)
                .map(
                  (e) =>
                      Attribute.fromJson(e is Map<String, dynamic> ? e : null),
                )
                .toList();
      }
    } catch (e) {
      debugPrint('Error parsing attributes: $e');
      attributes = [];
    }

    return Faq(
      uuid: json['uuid']?.toString() ?? '',
      userId: _parseToInt(json['userId']) ?? 0,
      gigId: _parseToInt(json['gigId']) ?? 0,
      attributes: attributes,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'userId': userId,
      'gigId': gigId,
      'attributes': attributes.map((a) => a.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class Attribute {
  final String question;
  final String answer;

  Attribute({required this.question, required this.answer});

  factory Attribute.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return Attribute(question: '', answer: '');
    }

    return Attribute(
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'question': question, 'answer': answer};
  }
}

class Assets {
  final List<Photo> photos;
  final Video? video;
  final Pdf? pdf;

  Assets({required this.photos, this.video, this.pdf});

  factory Assets.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return Assets(photos: []);
    }

    // Handle photos with extra safety
    List<Photo> photos = [];
    try {
      if (json['photos'] != null && json['photos'] is List) {
        photos =
            (json['photos'] as List<dynamic>)
                .where((e) => e != null)
                .map(
                  (e) => Photo.fromJson(e is Map<String, dynamic> ? e : null),
                )
                .toList();
      }
    } catch (e) {
      debugPrint('Error parsing photos: $e');
      photos = [];
    }

    // Handle video with extra safety - can be string, object, or null
    Video? video;
    try {
      if (json['video'] != null) {
        if (json['video'] is String) {
          // If video is a string (URL), create Video object with the URL
          final videoUrl = json['video'] as String;
          video = Video(name: 'video', link: videoUrl);
        } else if (json['video'] is Map<String, dynamic>) {
          // If video is an object, parse it normally
          video = Video.fromJson(json['video'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('Error parsing video: $e');
      video = null;
    }

    // Handle pdf with extra safety - can be string, object, or null
    Pdf? pdf;
    try {
      if (json['pdf'] != null) {
        if (json['pdf'] is String) {
          // If pdf is a string (URL), create Pdf object with the URL
          final pdfUrl = json['pdf'] as String;
          pdf = Pdf(name: 'document', link: pdfUrl);
        } else if (json['pdf'] is Map<String, dynamic>) {
          // If pdf is an object, parse it normally
          pdf = Pdf.fromJson(json['pdf'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('Error parsing pdf: $e');
      pdf = null;
    }

    return Assets(photos: photos, video: video, pdf: pdf);
  }

  Map<String, dynamic> toJson() {
    return {
      'photos': photos.map((p) => p.toJson()).toList(),
      if (video != null) 'video': video!.toJson(),
      if (pdf != null) 'pdf': pdf!.toJson(),
    };
  }
}

class Photo {
  final String name;
  final String link;

  Photo({required this.name, required this.link});

  factory Photo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return Photo(name: '', link: '');
    }

    return Photo(
      name: json['name']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'link': link};
  }
}

class Video {
  final String name;
  final String link;

  Video({required this.name, required this.link});

  factory Video.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return Video(name: '', link: '');
    }

    return Video(
      name: json['name']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'link': link};
  }
}

class Pdf {
  final String name;
  final String link;

  Pdf({required this.name, required this.link});

  factory Pdf.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return Pdf(name: '', link: '');
    }

    return Pdf(
      name: json['name']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'link': link};
  }
}

// Helper function to safely parse integers
int? _parseToInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  if (value is double) return value.toInt();
  return null;
}
