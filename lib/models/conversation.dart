import 'user.dart';

class Conversation {
  final String id;
  final String type;
  final String name;
  final String avatar;
  final String? ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Member>? members;

  Conversation({
    required this.id,
    required this.type,
    required this.name,
    required this.avatar,
    this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    this.members,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? '',
      type: json['type'] ?? 'private',
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? '',
      ownerId: json['owner_id'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      members: json['members'] != null
          ? (json['members'] as List).map((m) => Member.fromJson(m)).toList()
          : null,
    );
  }

  bool get isGroup => type == 'group';
}

class Member {
  final String id;
  final String userId;
  final String role;
  final String? nickname;
  final User user;

  Member({
    required this.id,
    required this.userId,
    required this.role,
    this.nickname,
    required this.user,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      role: json['role'] ?? 'member',
      nickname: json['nickname'],
      user: User.fromJson(json['user'] ?? {}),
    );
  }
}
