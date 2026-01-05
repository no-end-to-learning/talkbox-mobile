import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/conversation_provider.dart';
import '../providers/friend_provider.dart';
import '../models/bot.dart';
import '../services/api_service.dart';

class GroupSettingsScreen extends StatefulWidget {
  final String conversationId;

  const GroupSettingsScreen({super.key, required this.conversationId});

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  final _nameController = TextEditingController();
  List<Bot> _bots = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await context.read<ConversationProvider>().fetchConversation(widget.conversationId);
      await context.read<FriendProvider>().fetchUsers();
      final bots = await ApiService().getBots();
      setState(() {
        _bots = bots.map((b) => Bot.fromJson(b)).toList();
      });
      final conv = context.read<ConversationProvider>().currentConversation;
      if (conv != null) {
        _nameController.text = conv.name;
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateGroupName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    try {
      await context.read<ConversationProvider>().updateGroup(widget.conversationId, name: name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('群名称已更新')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败: $e')),
        );
      }
    }
  }

  Future<void> _removeMember(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除成员'),
        content: const Text('确定要移除该成员吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('确定')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await context.read<ConversationProvider>().removeMember(widget.conversationId, userId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('移除失败: $e')),
        );
      }
    }
  }

  Future<void> _addMember(String userId) async {
    try {
      await context.read<ConversationProvider>().addMember(widget.conversationId, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('成员已添加')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e')),
        );
      }
    }
  }

  Future<void> _addBot(String botId) async {
    try {
      await context.read<ConversationProvider>().addBot(widget.conversationId, botId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bot 已添加')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e')),
        );
      }
    }
  }

  Future<void> _dissolveGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('解散群聊'),
        content: const Text('确定要解散该群聊吗？此操作不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('解散'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await context.read<ConversationProvider>().dissolveGroup(widget.conversationId);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('解散失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final conversationProvider = context.watch<ConversationProvider>();
    final friendProvider = context.watch<FriendProvider>();
    final conversation = conversationProvider.currentConversation;

    if (_isLoading || conversation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('群设置')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isOwner = conversation.ownerId == authProvider.user?.id;
    final members = conversation.members ?? [];
    final memberIds = members.map((m) => m.user.id).toSet();
    final availableUsers = friendProvider.users.where((u) => !memberIds.contains(u.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('群设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 群名称
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('群名称', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: '请输入群名称',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: _updateGroupName, child: const Text('保存')),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 群成员
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('群成员 (${members.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...members.map((member) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text(member.user.nickname.isNotEmpty ? member.user.nickname[0] : 'U')),
                    title: Row(
                      children: [
                        Text(member.user.nickname),
                        if (member.role == 'owner')
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('群主', style: TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                        if (member.role == 'admin')
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('管理员', style: TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                      ],
                    ),
                    subtitle: Text('@${member.user.username}'),
                    trailing: isOwner && member.user.id != authProvider.user?.id
                        ? IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () => _removeMember(member.user.id),
                          )
                        : null,
                  )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 添加成员
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('添加成员', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  if (availableUsers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('暂无可添加的用户', style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ...availableUsers.map((user) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(child: Text(user.nickname.isNotEmpty ? user.nickname[0] : 'U')),
                      title: Text(user.nickname),
                      subtitle: Text('@${user.username}'),
                      trailing: ElevatedButton(
                        onPressed: () => _addMember(user.id),
                        child: const Text('添加'),
                      ),
                    )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 添加 Bot
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('添加 Bot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  if (_bots.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('暂无可添加的 Bot', style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ..._bots.map((bot) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple.shade100,
                        child: Text(bot.name.isNotEmpty ? bot.name[0] : 'B'),
                      ),
                      title: Text(bot.name),
                      subtitle: Text(bot.description.isNotEmpty ? bot.description : 'Bot'),
                      trailing: ElevatedButton(
                        onPressed: () => _addBot(bot.id),
                        child: const Text('添加'),
                      ),
                    )),
                ],
              ),
            ),
          ),

          // 解散群聊
          if (isOwner) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _dissolveGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('解散群聊'),
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
