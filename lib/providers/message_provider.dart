import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class MessageProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final WebSocketService _ws = WebSocketService();

  final Map<String, List<Message>> _messages = {};
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<Message> getMessages(String conversationId) {
    return _messages[conversationId] ?? [];
  }

  void initWebSocket(Function(String) onNewMessage) {
    _ws.onMessage = (data) {
      final msg = Message.fromJson(data);
      addMessage(msg);
      onNewMessage(msg.conversationId);
    };
  }

  Future<List<Message>> fetchMessages(String conversationId, {String? before}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.getMessages(conversationId, before: before);
      final list = data.map((m) => Message.fromJson(m)).toList().reversed.toList();

      if (before != null) {
        final existing = _messages[conversationId] ?? [];
        _messages[conversationId] = [...list, ...existing];
      } else {
        _messages[conversationId] = list;
      }

      return list;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String conversationId, String type, Map<String, dynamic> content, {String? replyToId}) async {
    await _api.sendMessage(conversationId, type, content, replyToId: replyToId);
    await fetchMessages(conversationId);
  }

  void addMessage(Message message) {
    final list = _messages[message.conversationId] ?? [];
    if (!list.any((m) => m.id == message.id)) {
      list.add(message);
      _messages[message.conversationId] = list;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> uploadFile(String filePath, String fileName) async {
    return await _api.uploadFile(filePath, fileName);
  }
}
