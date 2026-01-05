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
    try {
      return _conversations.firstWhere((c) => c.id == _currentConversationId);
    } catch (e) {
      return null;
    }
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

  // 群组管理
  Future<void> updateGroup(String conversationId, {String? name}) async {
    await _api.updateConversation(conversationId, name: name);
    await fetchConversation(conversationId);
  }

  Future<void> dissolveGroup(String conversationId) async {
    await _api.deleteConversation(conversationId);
    _conversations = _conversations.where((c) => c.id != conversationId).toList();
    if (_currentConversationId == conversationId) {
      _currentConversationId = null;
    }
    notifyListeners();
  }

  Future<void> addMember(String conversationId, String userId) async {
    await _api.addMembers(conversationId, [userId]);
    await fetchConversation(conversationId);
  }

  Future<void> removeMember(String conversationId, String userId) async {
    await _api.removeMember(conversationId, userId);
    await fetchConversation(conversationId);
  }

  Future<void> addBot(String conversationId, String botId) async {
    await _api.addBotToConversation(conversationId, botId);
    await fetchConversation(conversationId);
  }

  Future<void> removeBot(String conversationId, String botId) async {
    await _api.removeBotFromConversation(conversationId, botId);
    await fetchConversation(conversationId);
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
