import 'package:flutter/foundation.dart';
import '../models/bot.dart';
import '../services/api_service.dart';

class BotProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Bot> _bots = [];
  bool _isLoading = false;

  List<Bot> get bots => _bots;
  bool get isLoading => _isLoading;

  Future<void> fetchBots() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.getBots();
      _bots = data.map((b) => Bot.fromJson(b)).toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Bot> createBot(String name, String? description) async {
    final data = await _api.createBot(name, description);
    final bot = Bot.fromJson(data);
    _bots.insert(0, bot);
    notifyListeners();
    return bot;
  }

  Future<void> updateBot(String id, {String? name, String? description}) async {
    await _api.updateBot(id, name: name, description: description);
    await fetchBots();
  }

  Future<void> deleteBot(String id) async {
    await _api.deleteBot(id);
    _bots = _bots.where((b) => b.id != id).toList();
    notifyListeners();
  }

  Future<String> regenerateToken(String id) async {
    final token = await _api.regenerateBotToken(id);
    return token;
  }
}
