import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class Friend {
  final String id;
  final String viserId;
  final String friendId;
  final String status;
  final User friend;

  Friend({
    required this.id,
    required this.viserId,
    required this.friendId,
    required this.status,
    required this.friend,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] ?? '',
      viserId: json['user_id'] ?? '',
      friendId: json['friend_id'] ?? '',
      status: json['status'] ?? 'pending',
      friend: User.fromJson(json['friend'] ?? {}),
    );
  }
}

class FriendProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Friend> _friends = [];
  List<Friend> _requests = [];
  bool _isLoading = false;

  List<Friend> get friends => _friends;
  List<Friend> get requests => _requests;
  bool get isLoading => _isLoading;

  Future<void> fetchFriends() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.getFriends();
      _friends = data.map((f) => Friend.fromJson(f)).toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRequests() async {
    final data = await _api.getFriendRequests();
    _requests = data.map((f) => Friend.fromJson(f)).toList();
    notifyListeners();
  }

  Future<void> sendRequest(String userId) async {
    await _api.sendFriendRequest(userId);
  }

  Future<void> acceptRequest(String userId) async {
    await _api.acceptFriendRequest(userId);
    await fetchFriends();
    await fetchRequests();
  }

  Future<void> deleteFriend(String userId) async {
    await _api.deleteFriend(userId);
    _friends.removeWhere((f) => f.friendId == userId);
    notifyListeners();
  }

  Future<List<User>> searchUsers(String query) async {
    final data = await _api.searchUsers(query);
    return data.map((u) => User.fromJson(u)).toList();
  }
}
