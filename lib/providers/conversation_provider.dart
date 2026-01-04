import 'package:flutter/foundation.dart';
import '../models/conversation.dart';
import '../services/api_service.dart';

class ConversationProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Conversation> _conversations = [];
  String? _currentConversationId;
  bool _isLoading = false;

  List<Conversation> get conversations => _conversations;
  String? get currentConversationId => _currentConversationId;
  bool get isLoading => _isLoading;

  Conversation? get currentConversation {
    if (_currentConversationId == null) return null;
    return _conversations.firstWhere(
      (c) => c.id == _currentConversationId,
      orElse: () => _conversations.first,
    );
  }

  Future<void> fetchConversations() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.getConversations();
      _conversations = data.map((c) => Conversation.fromJson(c)).toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Conversation> fetchConversation(String id) async {
    final data = await _api.getConversation(id);
    final conv = Conversation.fromJson(data);

    final index = _conversations.indexWhere((c) => c.id == id);
    if (index >= 0) {
      _conversations[index] = conv;
      notifyListeners();
    }

    return conv;
  }

  Future<String> createGroup(String name, List<String> memberIds) async {
    final data = await _api.createGroup(name, memberIds);
    await fetchConversations();
    return data['id'];
  }

  Future<String> startPrivateChat(String userId) async {
    final data = await _api.startPrivateChat(userId);
    await fetchConversations();
    return data['conversation_id'];
  }

  void setCurrentConversation(String? id) {
    _currentConversationId = id;
    notifyListeners();
  }

  void updateConversationTime(String conversationId) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index > 0) {
      final conv = _conversations.removeAt(index);
      _conversations.insert(0, conv);
      notifyListeners();
    }
  }
}
