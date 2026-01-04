import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final WebSocketService _ws = WebSocketService();

  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _api.token != null && _user != null;

  Future<void> init() async {
    await _api.loadToken();
    if (_api.token != null) {
      await fetchCurrentUser();
    }
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.login(username, password);
      await _api.saveToken(data['token']);
      _user = User.fromJson(data['user']);
      _ws.connect(data['token']);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String username, String password, String? nickname) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.register(username, password, nickname);
      await _api.saveToken(data['token']);
      _user = User.fromJson(data['user']);
      _ws.connect(data['token']);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCurrentUser() async {
    try {
      final data = await _api.getCurrentUser();
      _user = User.fromJson(data);
      _ws.connect(_api.token!);
      notifyListeners();
    } catch (e) {
      await logout();
    }
  }

  Future<void> updateProfile({String? nickname}) async {
    final data = await _api.updateProfile({
      if (nickname != null) 'nickname': nickname,
    });
    _user = User.fromJson(data);
    notifyListeners();
  }

  Future<void> logout() async {
    await _api.clearToken();
    _user = null;
    _ws.disconnect();
    notifyListeners();
  }
}
