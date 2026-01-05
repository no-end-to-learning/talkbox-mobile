import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_service.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  Timer? _pingTimer;
  bool _isConnected = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  String? _currentToken;

  Function(Map<String, dynamic>)? onMessage;
  Function(Map<String, dynamic>)? onMentioned;
  Function(bool)? onConnectionChanged;

  bool get isConnected => _isConnected;

  void connect(String token) {
    if (_isConnected || _isConnecting) return;
    _isConnecting = true;
    _currentToken = token;

    final wsUrl = ApiService.baseUrl.replaceFirst('http', 'ws') + '/ws?token=$token';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        (data) {
          // 收到第一条消息时确认连接成功
          if (!_isConnected) {
            _isConnected = true;
            _isConnecting = false;
            _reconnectAttempts = 0;
            onConnectionChanged?.call(true);
            _startPing();
          }

          final msg = jsonDecode(data);
          _handleMessage(msg);
        },
        onError: (error) {
          _disconnect();
          _tryReconnect();
        },
        onDone: () {
          _disconnect();
          _tryReconnect();
        },
      );

      // 发送初始 ping 来确认连接
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_isConnecting && !_isConnected) {
          send({'action': 'ping'});
        }
      });
    } catch (e) {
      _isConnecting = false;
      _tryReconnect();
    }
  }

  void _handleMessage(Map<String, dynamic> msg) {
    switch (msg['event']) {
      case 'new_message':
        onMessage?.call(msg['data']);
        break;
      case 'mentioned':
        onMentioned?.call(msg['data']);
        break;
      case 'pong':
        break;
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      send({'action': 'ping'});
    });
  }

  void _disconnect() {
    _isConnected = false;
    _isConnecting = false;
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    onConnectionChanged?.call(false);
  }

  void _tryReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts || _currentToken == null) {
      return;
    }

    _reconnectAttempts++;

    Future.delayed(const Duration(seconds: 3), () {
      if (_currentToken != null) {
        connect(_currentToken!);
      }
    });
  }

  void send(Map<String, dynamic> data) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void sendMessage(String conversationId, String type, Map<String, dynamic> content, {String? replyToId}) {
    send({
      'action': 'send_message',
      'conversation_id': conversationId,
      'type': type,
      'content': content,
      if (replyToId != null) 'reply_to_id': replyToId,
    });
  }

  void disconnect() {
    _reconnectAttempts = _maxReconnectAttempts;
    _currentToken = null;
    _disconnect();
  }
}
