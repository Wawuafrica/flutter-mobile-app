class ChatUser {
  final String id;
  final String name;
  final String? avatar;

  ChatUser({required this.id, required this.name, this.avatar});

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['uuid'] as String,
      // Build full name from first_name and last_name since API doesn't provide 'name'
      name: '${json['first_name'] as String} ${json['last_name'] as String}',
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'uuid': id, 'name': name, 'avatar': avatar};
  }
}
