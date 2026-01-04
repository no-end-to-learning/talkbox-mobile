class User {
  final String id;
  final String username;
  final String nickname;
  final String avatar;

  User({
    required this.id,
    required this.username,
    required this.nickname,
    required this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      nickname: json['nickname'] ?? '',
      avatar: json['avatar'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nickname': nickname,
      'avatar': avatar,
    };
  }
}
