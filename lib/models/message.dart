class Message {
  final String id;
  final String conversationId;
  final Sender sender;
  final String type;
  final Map<String, dynamic> content;
  final String? replyToId;
  final ReplyInfo? replyTo;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.type,
    required this.content,
    this.replyToId,
    this.replyTo,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      sender: Sender.fromJson(json['sender'] ?? {}),
      type: json['type'] ?? 'text',
      content: json['content'] ?? {},
      replyToId: json['reply_to_id'],
      replyTo: json['reply_to'] != null ? ReplyInfo.fromJson(json['reply_to']) : null,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get textContent => content['text'] ?? '';

  bool get isText => type == 'text';
  bool get isImage => type == 'image';
  bool get isVideo => type == 'video';
  bool get isFile => type == 'file';
  bool get isCard => type == 'card';
}

class Sender {
  final String id;
  final String type;
  final String nickname;
  final String avatar;

  Sender({
    required this.id,
    required this.type,
    required this.nickname,
    required this.avatar,
  });

  factory Sender.fromJson(Map<String, dynamic> json) {
    return Sender(
      id: json['id'] ?? '',
      type: json['type'] ?? 'user',
      nickname: json['nickname'] ?? '',
      avatar: json['avatar'] ?? '',
    );
  }

  bool get isBot => type == 'bot';
}

class ReplyInfo {
  final String id;
  final String type;
  final Map<String, dynamic> content;
  final String senderName;

  ReplyInfo({
    required this.id,
    required this.type,
    required this.content,
    required this.senderName,
  });

  factory ReplyInfo.fromJson(Map<String, dynamic> json) {
    return ReplyInfo(
      id: json['id'] ?? '',
      type: json['type'] ?? 'text',
      content: json['content'] ?? {},
      senderName: json['sender_name'] ?? '',
    );
  }

  String get preview {
    if (type == 'text') {
      final text = content['text'] ?? '';
      return text.length > 30 ? '${text.substring(0, 30)}...' : text;
    }
    return '[$type]';
  }
}
