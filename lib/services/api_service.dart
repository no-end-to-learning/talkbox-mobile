import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // 可配置的服务器地址，从 SharedPreferences 读取或使用默认值
  static String _baseUrl = 'http://localhost:8080';

  static String get baseUrl => _baseUrl;

  static Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url);
    _instance._updateBaseUrl(url);
  }

  static Future<void> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('server_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _baseUrl = savedUrl;
      _instance._updateBaseUrl(savedUrl);
    }
  }

  late Dio _dio;
  String? _token;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final data = response.data;
        if (data is Map && data['code'] != null && data['code'] != 0) {
          return handler.reject(DioException(
            requestOptions: response.requestOptions,
            message: data['message'] ?? 'Request failed',
          ));
        }
        if (data is Map && data.containsKey('data')) {
          response.data = data['data'];
        }
        return handler.next(response);
      },
    ));
  }

  void _updateBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }

  void setToken(String? token) {
    _token = token;
  }

  String? get token => _token;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // Auth
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _dio.post('/api/auth/login', data: {
      'username': username,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> register(String username, String password, String? nickname) async {
    final response = await _dio.post('/api/auth/register', data: {
      'username': username,
      'password': password,
      if (nickname != null) 'nickname': nickname,
    });
    return response.data;
  }

  // User
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _dio.get('/api/users/me');
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.put('/api/users/me', data: data);
    return response.data;
  }

  Future<List<dynamic>> searchUsers(String query) async {
    final response = await _dio.get('/api/users/search', queryParameters: {'q': query});
    return response.data ?? [];
  }

  Future<List<dynamic>> getAllUsers() async {
    final response = await _dio.get('/api/users');
    return response.data ?? [];
  }

  // Friends
  Future<List<dynamic>> getFriends() async {
    final response = await _dio.get('/api/friends');
    return response.data ?? [];
  }

  Future<List<dynamic>> getFriendRequests() async {
    final response = await _dio.get('/api/friends/requests');
    return response.data ?? [];
  }

  Future<void> sendFriendRequest(String userId) async {
    await _dio.post('/api/friends/request', data: {'user_id': userId});
  }

  Future<void> acceptFriendRequest(String userId) async {
    await _dio.post('/api/friends/accept/$userId');
  }

  Future<void> deleteFriend(String userId) async {
    await _dio.delete('/api/friends/$userId');
  }

  // Conversations
  Future<List<dynamic>> getConversations() async {
    final response = await _dio.get('/api/conversations');
    return response.data ?? [];
  }

  Future<Map<String, dynamic>> getConversation(String id) async {
    final response = await _dio.get('/api/conversations/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> createGroup(String name, List<String> memberIds) async {
    final response = await _dio.post('/api/conversations', data: {
      'name': name,
      'member_ids': memberIds,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> startPrivateChat(String userId) async {
    final response = await _dio.post('/api/conversations/private', data: {'user_id': userId});
    return response.data;
  }

  Future<void> updateConversation(String id, {String? name}) async {
    await _dio.put('/api/conversations/$id', data: {
      if (name != null) 'name': name,
    });
  }

  Future<void> deleteConversation(String id) async {
    await _dio.delete('/api/conversations/$id');
  }

  Future<void> addMembers(String conversationId, List<String> userIds) async {
    await _dio.post('/api/conversations/$conversationId/members', data: {
      'user_ids': userIds,
    });
  }

  Future<void> removeMember(String conversationId, String userId) async {
    await _dio.delete('/api/conversations/$conversationId/members/$userId');
  }

  Future<void> addBotToConversation(String conversationId, String botId) async {
    await _dio.post('/api/conversations/$conversationId/bots/$botId');
  }

  Future<void> removeBotFromConversation(String conversationId, String botId) async {
    await _dio.delete('/api/conversations/$conversationId/bots/$botId');
  }

  // Messages
  Future<List<dynamic>> getMessages(String conversationId, {String? before, int limit = 50}) async {
    final response = await _dio.get('/api/conversations/$conversationId/messages', queryParameters: {
      'limit': limit,
      if (before != null) 'before': before,
    });
    return response.data ?? [];
  }

  Future<Map<String, dynamic>> sendMessage(String conversationId, String type, Map<String, dynamic> content, {String? replyToId}) async {
    final response = await _dio.post('/api/conversations/$conversationId/messages', data: {
      'type': type,
      'content': content,
      if (replyToId != null) 'reply_to_id': replyToId,
    });
    return response.data;
  }

  // Files
  Future<Map<String, dynamic>> uploadFile(String filePath, String fileName) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _dio.post('/api/files/upload', data: formData);
    return response.data;
  }

  String getFileUrl(String path) {
    if (path.startsWith('http')) return path;
    return '$baseUrl$path';
  }

  // Bots
  Future<List<dynamic>> getBots() async {
    final response = await _dio.get('/api/bots');
    return response.data ?? [];
  }

  Future<Map<String, dynamic>> createBot(String name, String? description) async {
    final response = await _dio.post('/api/bots', data: {
      'name': name,
      if (description != null) 'description': description,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateBot(String id, {String? name, String? description}) async {
    final response = await _dio.put('/api/bots/$id', data: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
    });
    return response.data;
  }

  Future<void> deleteBot(String id) async {
    await _dio.delete('/api/bots/$id');
  }

  Future<String> regenerateBotToken(String id) async {
    final response = await _dio.post('/api/bots/$id/token');
    return response.data['token'];
  }
}
