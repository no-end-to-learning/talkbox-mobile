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
  List<User> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await context.read<FriendProvider>().searchUsers(_searchController.text);
      setState(() => _searchResults = results);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _addFriend(String userId) async {
    try {
      await context.read<FriendProvider>().sendRequest(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('好友请求已发送')),
      );
      setState(() {
        _searchResults.removeWhere((u) => u.id == userId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送失败: $e')),
      );
    }
  }

  Future<void> _acceptRequest(String userId) async {
    await context.read<FriendProvider>().acceptRequest(userId);
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索用户',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchResults = []);
                },
              ),
            ),
            onSubmitted: (_) => _search(),
          ),
        ),
        if (_isSearching)
          const LinearProgressIndicator(),
        if (_searchResults.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('搜索结果', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          ..._searchResults.map((user) => ListTile(
            leading: CircleAvatar(child: Text(user.nickname.isNotEmpty ? user.nickname[0] : 'U')),
            title: Text(user.nickname),
            subtitle: Text('@${user.username}'),
            trailing: TextButton(
              onPressed: () => _addFriend(user.id),
              child: const Text('添加'),
            ),
          )),
          const Divider(),
        ],
        if (friendProvider.requests.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('好友请求', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          ...friendProvider.requests.map((req) => ListTile(
            leading: CircleAvatar(child: Text(req.friend.nickname.isNotEmpty ? req.friend.nickname[0] : 'U')),
            title: Text(req.friend.nickname),
            trailing: FilledButton(
              onPressed: () => _acceptRequest(req.friend.id),
              child: const Text('接受'),
            ),
          )),
          const Divider(),
        ],
        Expanded(
          child: friendProvider.friends.isEmpty
              ? const Center(child: Text('暂无好友'))
              : RefreshIndicator(
                  onRefresh: () async {
                    await friendProvider.fetchFriends();
                    await friendProvider.fetchRequests();
                  },
                  child: ListView.builder(
                    itemCount: friendProvider.friends.length,
                    itemBuilder: (context, index) {
                      final friend = friendProvider.friends[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(friend.friend.nickname.isNotEmpty ? friend.friend.nickname[0] : 'U'),
                        ),
                        title: Text(friend.friend.nickname),
                        subtitle: Text('@${friend.friend.username}'),
                        onTap: () => _startChat(friend.friend.id),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
