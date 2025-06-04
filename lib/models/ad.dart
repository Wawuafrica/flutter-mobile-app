class Ad {
  final String uuid;
  final String link;
  final String page;
  final String callToAction;
  final String timeframe;
  final Media media;
  final DateTime createdAt;
  final DateTime updatedAt;

  Ad({
    required this.uuid,
    required this.link,
    required this.page,
    required this.callToAction,
    required this.timeframe,
    required this.media,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Ad.fromJson(Map<String, dynamic> json) {
    return Ad(
      uuid: json['uuid'] ?? '',
      link: json['link'] ?? '',
      page: json['page'] ?? '',
      callToAction: json['call_to_action'] ?? '',
      timeframe: json['timeframe'] ?? '',
      media: Media.fromJson(json['media'] ?? {}),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toString()),
    );
  }
}

class Media {
  final String name;
  final String link;

  Media({
    required this.name,
    required this.link,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      name: json['name'] ?? '',
      link: json['link'] ?? '',
    );
  }
}