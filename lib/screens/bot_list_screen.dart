import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/bot.dart';
import '../services/api_service.dart';

class BotListScreen extends StatefulWidget {
  const BotListScreen({super.key});

  @override
  State<BotListScreen> createState() => _BotListScreenState();
}

class _BotListScreenState extends State<BotListScreen> {
  final ApiService _api = ApiService();
  List<Bot> _bots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBots();
  }

  Future<void> _loadBots() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getBots();
      setState(() => _bots = data.map((b) => Bot.fromJson(b)).toList());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createBot() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建 Bot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('创建'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      try {
        final data = await _api.createBot(
          nameController.text,
          descController.text.isEmpty ? null : descController.text,
        );
        final bot = Bot.fromJson(data);
        _showTokenDialog(bot.token!);
        _loadBots();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: $e')),
        );
      }
    }
  }

  Future<void> _deleteBot(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个 Bot 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _api.deleteBot(id);
      _loadBots();
    }
  }

  void _showTokenDialog(String token) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bot Token'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '请妥善保管 Token，不要泄露给他人',
              style: TextStyle(color: Colors.orange, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                token,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: token));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已复制到剪贴板')),
              );
            },
            child: const Text('复制'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bot 管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createBot,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bots.isEmpty
              ? const Center(child: Text('暂无 Bot，点击右上角创建'))
              : RefreshIndicator(
                  onRefresh: _loadBots,
                  child: ListView.builder(
                    itemCount: _bots.length,
                    itemBuilder: (context, index) {
                      final bot = _bots[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(child: Text(bot.name[0])),
                          title: Text(bot.name),
                          subtitle: Text(bot.description.isEmpty ? '暂无描述' : bot.description),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: const Text('查看 Token'),
                                onTap: () {
                                  if (bot.token != null) {
                                    Future.delayed(Duration.zero, () => _showTokenDialog(bot.token!));
                                  }
                                },
                              ),
                              PopupMenuItem(
                                child: const Text('删除', style: TextStyle(color: Colors.red)),
                                onTap: () => Future.delayed(Duration.zero, () => _deleteBot(bot.id)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
