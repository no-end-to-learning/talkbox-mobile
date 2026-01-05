import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/conversation_provider.dart';
import '../providers/friend_provider.dart';
import '../providers/message_provider.dart';
import '../models/conversation.dart';
import 'chat_screen.dart';
import 'friends_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final conversationProvider = context.read<ConversationProvider>();
    final friendProvider = context.read<FriendProvider>();
    final messageProvider = context.read<MessageProvider>();

    await conversationProvider.fetchConversations();
    await friendProvider.fetchUsers();

    messageProvider.initWebSocket((convId) {
      conversationProvider.updateConversationTime(convId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? '会话' : _currentIndex == 1 ? '通讯录' : '设置'),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.group_add),
              onPressed: _showCreateGroupDialog,
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _ConversationList(),
          FriendsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat), label: '会话'),
          NavigationDestination(icon: Icon(Icons.people), label: '通讯录'),
          NavigationDestination(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }

  void _showCreateGroupDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建群聊'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '群名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              await context.read<ConversationProvider>().createGroup(controller.text, []);
              Navigator.pop(context);
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
}

class _ConversationList extends StatelessWidget {
  const _ConversationList();

  @override
  Widget build(BuildContext context) {
    final conversationProvider = context.watch<ConversationProvider>();
    final messageProvider = context.watch<MessageProvider>();
    final authProvider = context.watch<AuthProvider>();

    if (conversationProvider.isLoading && conversationProvider.conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (conversationProvider.conversations.isEmpty) {
      return const Center(child: Text('暂无会话'));
    }

    return RefreshIndicator(
      onRefresh: () => conversationProvider.fetchConversations(),
      child: ListView.builder(
        itemCount: conversationProvider.conversations.length,
        itemBuilder: (context, index) {
          final conv = conversationProvider.conversations[index];
          final name = _getConversationName(conv, authProvider.user?.id);
          final messages = messageProvider.getMessages(conv.id);
          final lastMessage = messages.isNotEmpty ? messages.last : null;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'G',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Row(
              children: [
                Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
                Text(
                  _formatTime(conv.updatedAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
            subtitle: Text(
              lastMessage != null ? _getMessagePreview(lastMessage) : '暂无消息',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            onTap: () {
              conversationProvider.setCurrentConversation(conv.id);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(conversationId: conv.id),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getMessagePreview(dynamic message) {
    if (message.isText) {
      return '${message.sender.nickname}: ${message.textContent}';
    }
    String typeLabel = '';
    switch (message.type) {
      case 'image':
        typeLabel = '[图片]';
        break;
      case 'video':
        typeLabel = '[视频]';
        break;
      case 'file':
        typeLabel = '[文件]';
        break;
      case 'card':
        typeLabel = '[卡片]';
        break;
      default:
        typeLabel = '[消息]';
    }
    return '${message.sender.nickname}: $typeLabel';
  }

  String _getConversationName(Conversation conv, String? currentUserId) {
    if (conv.isGroup) {
      return conv.name.isNotEmpty ? conv.name : '群聊';
    }
    final member = conv.members?.firstWhere(
      (m) => m.viserId != currentUserId,
      orElse: () => conv.members!.first,
    );
    return member?.user.nickname ?? '私聊';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    return '${time.month}/${time.day}';
  }
}
