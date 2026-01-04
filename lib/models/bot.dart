class Bot {
  final String id;
  final String name;
  final String avatar;
  final String description;
  final String? token;
  final DateTime createdAt;

  Bot({
    required this.id,
    required this.name,
    required this.avatar,
    required this.description,
    this.token,
    required this.createdAt,
  });

  factory Bot.fromJson(Map<String, dynamic> json) {
    return Bot(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? '',
      description: json['description'] ?? '',
      token: json['token'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
