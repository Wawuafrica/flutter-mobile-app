class Gig {
  final String uuid;
  final String title;
  final String description;
  final String keywords;
  final String about;
  final List<Service> services;
  final List<Pricing> pricings;
  final List<Faq> faqs;
  final Assets assets;
  final String status;

  Gig({
    required this.uuid,
    required this.title,
    required this.description,
    required this.keywords,
    required this.about,
    required this.services,
    required this.pricings,
    required this.faqs,
    required this.assets,
    required this.status,
  });

  factory Gig.fromJson(Map<String, dynamic> json) {
    return Gig(
      uuid: json['uuid'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      keywords: json['keywords'] as String? ?? '',
      about: json['about'] as String? ?? '',
      services: (json['services'] as List<dynamic>?)
              ?.map((e) => Service.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pricings: (json['pricings'] as List<dynamic>?)
              ?.map((e) => Pricing.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      faqs: (json['faqs'] as List<dynamic>?)
              ?.map((e) => Faq.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      assets: Assets.fromJson(json['assets'] as Map<String, dynamic>? ?? {}),
      status: json['status'] as String? ?? 'PENDING',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'title': title,
      'description': description,
      'keywords': keywords,
      'about': about,
      'services': services.map((s) => s.toJson()).toList(),
      'pricings': pricings.map((p) => p.toJson()).toList(),
      'faqs': faqs.map((f) => f.toJson()).toList(),
      'assets': assets.toJson(),
      'status': status,
    };
  }

  DateTime get createdAt {
    if (services.isNotEmpty && services[0].createdAt.isNotEmpty) {
      return DateTime.tryParse(services[0].createdAt) ?? DateTime.now();
    }
    if (pricings.isNotEmpty && pricings[0].createdAt.isNotEmpty) {
      return DateTime.tryParse(pricings[0].createdAt) ?? DateTime.now();
    }
    return DateTime.now();
  }

  bool isPending() => status == 'PENDING';
  bool isVerified() => status == 'VERIFIED';
  bool isArchived() => status == 'ARCHIVED';
  bool isRejected() => status == 'REJECTED';
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

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      uuid: json['uuid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String?,
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

  factory Pricing.fromJson(Map<String, dynamic> json) {
    return Pricing(
      uuid: json['uuid'] as String? ?? '',
      userId: json['userId'] as int? ?? 0,
      gigId: json['gigId'] as int? ?? 0,
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => Feature.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      package: Package.fromJson(json['package'] as Map<String, dynamic>? ?? {}),
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

  factory Feature.fromJson(Map<String, dynamic> json) {
    return Feature(
      name: json['name'] as String? ?? '',
      value: json['value'] as String? ?? '',
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

  Package({required this.name, required this.amount, required this.description});

  factory Package.fromJson(Map<String, dynamic> json) {
    return Package(
      name: json['name'] as String? ?? '',
      amount: json['amount'] as String? ?? '0',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'description': description,
    };
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

  factory Faq.fromJson(Map<String, dynamic> json) {
    return Faq(
      uuid: json['uuid'] as String? ?? '',
      userId: json['userId'] as int? ?? 0,
      gigId: json['gigId'] as int? ?? 0,
      attributes: (json['attributes'] as List<dynamic>?)
              ?.map((e) => Attribute.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
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

  factory Attribute.fromJson(Map<String, dynamic> json) {
    return Attribute(
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
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

  factory Assets.fromJson(Map<String, dynamic> json) {
    return Assets(
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => Photo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      video: json['video'] != null ? Video.fromJson(json['video'] as Map<String, dynamic>) : null,
      pdf: json['pdf'] != null ? Pdf.fromJson(json['pdf'] as Map<String, dynamic>) : null,
    );
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

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      name: json['name'] as String? ?? '',
      link: json['link'] as String? ?? '',
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

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      name: json['name'] as String? ?? '',
      link: json['link'] as String? ?? '',
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

  factory Pdf.fromJson(Map<String, dynamic> json) {
    return Pdf(
      name: json['name'] as String? ?? '',
      link: json['link'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'link': link};
  }
}