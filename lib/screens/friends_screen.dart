import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friend_provider.dart';
import '../providers/conversation_provider.dart';
import '../models/user.dart';
import 'chat_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<User> _filterUsers(List<User> users) {
    if (_searchQuery.isEmpty) return users;
    final query = _searchQuery.toLowerCase();
    return users.where((user) {
      return user.nickname.toLowerCase().contains(query) ||
          user.username.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _startChat(String userId) async {
    final convId = await context.read<ConversationProvider>().startPrivateChat(userId);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(conversationId: convId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final friendProvider = context.watch<FriendProvider>();
    final filteredUsers = _filterUsers(friendProvider.users);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索成员',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
        ),
        Expanded(
          child: filteredUsers.isEmpty
              ? Center(
                  child: Text(_searchQuery.isEmpty ? '暂无成员' : '无匹配结果'),
                )
              : RefreshIndicator(
                  onRefresh: friendProvider.fetchUsers,
                  child: ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(user.nickname.isNotEmpty ? user.nickname[0] : 'U'),
                        ),
                        title: Text(user.nickname),
                        subtitle: Text('@${user.username}'),
                        onTap: () => _startChat(user.id),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
