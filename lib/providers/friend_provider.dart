import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class FriendProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<User> _users = [];
  bool _isLoading = false;

  List<User> get users => _users;
  bool get isLoading => _isLoading;

  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.getAllUsers();
      _users = data.map((u) => User.fromJson(u)).toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
