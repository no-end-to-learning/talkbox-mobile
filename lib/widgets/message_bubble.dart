import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/message.dart';
import '../services/api_service.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isSelf;
  final VoidCallback? onReply;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSelf,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSelf) ...[
            CircleAvatar(
              radius: 18,
              child: Text(message.sender.nickname.isNotEmpty ? message.sender.nickname[0] : 'U'),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isSelf)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.sender.nickname,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        if (message.sender.isBot)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Text(
                              'Bot',
                              style: TextStyle(fontSize: 10, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (message.replyTo != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${message.replyTo!.senderName}: ${message.replyTo!.preview}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                GestureDetector(
                  onLongPress: onReply,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    padding: _getPadding(),
                    decoration: BoxDecoration(
                      color: isSelf ? Theme.of(context).colorScheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _buildContent(context),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),
          ),
          if (isSelf) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              child: Text(message.sender.nickname.isNotEmpty ? message.sender.nickname[0] : 'U'),
            ),
          ],
        ],
      ),
    );
  }

  EdgeInsets _getPadding() {
    if (message.isImage || message.isVideo) {
      return const EdgeInsets.all(4);
    }
    return const EdgeInsets.symmetric(horizontal: 12, vertical: 10);
  }

  Widget _buildContent(BuildContext context) {
    switch (message.type) {
      case 'text':
        return _buildTextContent(context);
      case 'image':
        return _buildImageContent(context);
      case 'video':
        return _buildVideoContent(context);
      case 'file':
        return _buildFileContent(context);
      case 'card':
        return _buildCardContent(context);
      default:
        return Text(
          '[不支持的消息类型]',
          style: TextStyle(color: isSelf ? Colors.white : Colors.black),
        );
    }
  }

  Widget _buildTextContent(BuildContext context) {
    return Text(
      message.textContent,
      style: TextStyle(
        color: isSelf ? Colors.white : Colors.black,
        fontSize: 15,
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    final url = ApiService().getFileUrl(message.content['url'] ?? '');
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 200,
        fit: BoxFit.cover,
        placeholder: (_, __) => const SizedBox(
          width: 200,
          height: 150,
          child: Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (_, __, ___) => const Icon(Icons.error),
      ),
    );
  }

  Widget _buildVideoContent(BuildContext context) {
    return Container(
      width: 200,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(Icons.play_circle_outline, size: 48, color: Colors.white),
      ),
    );
  }

  Widget _buildFileContent(BuildContext context) {
    final name = message.content['name'] ?? '文件';
    final size = _formatSize(message.content['size'] ?? 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.insert_drive_file,
          color: isSelf ? Colors.white : Colors.grey,
          size: 36,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(
                color: isSelf ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              size,
              style: TextStyle(
                color: isSelf ? Colors.white70 : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardContent(BuildContext context) {
    final color = _parseColor(message.content['color']) ?? Theme.of(context).colorScheme.primary;
    final title = message.content['title'] ?? '';
    final content = message.content['content'];
    final note = message.content['note'];
    final url = message.content['url'];

    return GestureDetector(
      onTap: url != null ? () => _launchUrl(url) : null,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        padding: const EdgeInsets.only(left: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelf ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
            if (content != null) ...[
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(
                  color: isSelf ? Colors.white70 : Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
            if (note != null) ...[
              const SizedBox(height: 4),
              Text(
                note,
                style: TextStyle(
                  color: isSelf ? Colors.white60 : Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color? _parseColor(String? colorStr) {
    if (colorStr == null) return null;
    try {
      return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
    } catch (e) {
      return null;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
