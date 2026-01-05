import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    // 先从本地恢复用户信息
    await _loadSavedUser();
    if (_api.token != null && _user != null) {
      // 有缓存的用户信息，先连接 WebSocket
      _ws.connect(_api.token!);
      // 后台刷新用户信息
      fetchCurrentUser();
    } else if (_api.token != null) {
      // 没有缓存，需要从服务器获取
      await fetchCurrentUser();
    }
  }

  Future<void> _loadSavedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('user');
      if (saved != null) {
        _user = User.fromJson(jsonDecode(saved));
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson()));
  }

  Future<void> _clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.login(username, password);
      await _api.saveToken(data['token']);
      _user = User.fromJson(data['user']);
      await _saveUser(_user!);
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
      await _saveUser(_user!);
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
      await _saveUser(_user!);
      if (_api.token != null) {
        _ws.connect(_api.token!);
      }
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
    await _saveUser(_user!);
    notifyListeners();
  }

  Future<void> logout() async {
    await _api.clearToken();
    await _clearUser();
    _user = null;
    _ws.disconnect();
    notifyListeners();
  }
}
