import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/conversation_provider.dart';
import '../providers/message_provider.dart';
import '../models/message.dart';
import '../widgets/message_bubble.dart';
import 'group_settings_screen.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Message? _replyTo;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await context.read<ConversationProvider>().fetchConversation(widget.conversationId);
    await context.read<MessageProvider>().fetchMessages(widget.conversationId);
    _scrollToBottom();
  }

  void _onScroll() {
    if (_scrollController.position.pixels < 50) {
      final messages = context.read<MessageProvider>().getMessages(widget.conversationId);
      if (messages.isNotEmpty) {
        context.read<MessageProvider>().fetchMessages(
          widget.conversationId,
          before: messages.first.createdAt.toIso8601String(),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    await context.read<MessageProvider>().sendMessage(
      widget.conversationId,
      'text',
      {'text': text},
      replyToId: _replyTo?.id,
    );

    setState(() => _replyTo = null);
    _scrollToBottom();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    final file = result.files.first;
    if (file.path == null) return;

    try {
      final res = await context.read<MessageProvider>().uploadFile(file.path!, file.name);

      String type = 'file';
      Map<String, dynamic> content = {
        'url': res['url'],
        'name': res['name'],
        'size': res['size'],
        'mime_type': res['mime_type'],
      };

      final mimeType = res['mime_type'] ?? '';
      if (mimeType.startsWith('image/')) {
        type = 'image';
        content = {'url': res['url'], 'width': 0, 'height': 0, 'size': res['size']};
      } else if (mimeType.startsWith('video/')) {
        type = 'video';
        content = {'url': res['url'], 'duration': 0, 'size': res['size']};
      }

      await context.read<MessageProvider>().sendMessage(widget.conversationId, type, content);
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('上传失败: $e')),
      );
    }
  }

  String _formatTimeGroup(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDay = DateTime(time.year, time.month, time.day);

    if (messageDay == today) {
      return '今天 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDay == yesterday) {
      return '昨天 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (now.year == time.year) {
      return '${time.month}月${time.day}日 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.year}年${time.month}月${time.day}日';
    }
  }

  bool _shouldShowTime(List<Message> messages, int index) {
    if (index == 0) return true;
    final current = messages[index].createdAt;
    final previous = messages[index - 1].createdAt;
    return current.difference(previous).inMinutes > 5;
  }

  @override
  Widget build(BuildContext context) {
    final messageProvider = context.watch<MessageProvider>();
    final authProvider = context.watch<AuthProvider>();
    final conversationProvider = context.watch<ConversationProvider>();
    final messages = messageProvider.getMessages(widget.conversationId);
    final conversation = conversationProvider.currentConversation;

    final isGroup = conversation?.isGroup ?? false;
    String title = '聊天';
    if (conversation != null) {
      if (isGroup) {
        title = conversation.name.isNotEmpty ? conversation.name : '群聊';
      } else {
        final other = conversation.members?.firstWhere(
          (m) => m.user.id != authProvider.user?.id,
          orElse: () => conversation.members!.first,
        );
        title = other?.user.nickname ?? '私聊';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            if (isGroup && conversation?.members != null)
              Text(
                '${conversation!.members!.length} 人',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          if (isGroup)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupSettingsScreen(conversationId: widget.conversationId),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text('暂无消息'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isSelf = msg.sender.id == authProvider.user?.id && !msg.sender.isBot;
                      final showTime = _shouldShowTime(messages, index);

                      return Column(
                        children: [
                          if (showTime)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                _formatTimeGroup(msg.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                          MessageBubble(
                            message: msg,
                            isSelf: isSelf,
                            onReply: () => setState(() => _replyTo = msg),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          if (_replyTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '回复 ${_replyTo!.sender.nickname}: ${_replyTo!.isText ? _replyTo!.textContent : "[${_replyTo!.type}]"}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _replyTo = null),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _pickFile,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: '输入消息...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
