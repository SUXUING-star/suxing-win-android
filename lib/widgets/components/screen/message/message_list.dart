// lib/widgets/components/screen/message/message_list.dart
import 'package:flutter/material.dart';
import '../../../../models/message/message.dart';
import '../../../../models/message/message_type.dart';
import '../../../../services/main/message/message_service.dart';

class MessageList extends StatelessWidget {
  final List<Message> messages;
  final MessageService messageService;
  final Function(Message) onMessageTap;
  final Message? selectedMessage;
  final bool isCompact;

  const MessageList({
    Key? key,
    required this.messages,
    required this.messageService,
    required this.onMessageTap,
    this.selectedMessage,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return message.isGrouped
            ? _buildGroupedMessageItem(context, message)
            : _buildSingleMessageItem(context, message);
      },
    );
  }

  Widget _buildEmptyState({String message = '暂无消息'}) {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mark_email_read, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(message, style: TextStyle(fontSize: 18, color: Colors.grey)),
              SizedBox(height: 8),
              Text('下拉刷新以检查新消息', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ],
          ),
        ),
        // 添加一个透明的ListView以支持下拉刷新
        ListView(children: [Container(height: 800)]),
      ],
    );
  }

  // 构建分组消息项
  Widget _buildGroupedMessageItem(BuildContext context, Message message) {
    final horizontalPadding = isCompact ? 8.0 : 16.0;
    final verticalPadding = isCompact ? 4.0 : 8.0;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      // 未读消息突出显示
      elevation: message.isRead ? 1 : 3,
      color: (selectedMessage?.id == message.id)
          ? Colors.blue[100]
          : (message.isRead ? null : Colors.blue[50]),
      child: ExpansionTile(
        leading: Icon(
          Icons.group,
          color: message.isRead ? Colors.grey : Colors.blue,
          size: isCompact ? 20 : 24,
        ),
        title: Text(
          '${message.groupCount} 条消息',
          style: TextStyle(
            fontWeight: message.isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: isCompact ? 14 : 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.getPreviewContent(),
              style: TextStyle(fontSize: isCompact ? 12 : 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Text(
              '${_formatDateTime(message.displayTime)}',
              style: TextStyle(fontSize: isCompact ? 11 : 12),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, size: isCompact ? 20 : 24),
          onPressed: () => _showDeleteDialog(context, message),
        ),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(fontSize: isCompact ? 14 : 16),
                ),
                if (message.references != null && message.references!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '最近回复: ${message.lastContent ?? ""}',
                      style: TextStyle(
                          fontSize: isCompact ? 12 : 13,
                          color: Colors.grey[600]
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    child: Text('查看详情'),
                    onPressed: () => onMessageTap(message),
                  ),
                ),
              ],
            ),
          ),
        ],
        onExpansionChanged: (expanded) {
          if (expanded && !message.isRead) {
            messageService.markAsRead(message.id);
          }
        },
      ),
    );
  }

  // 构建单条消息项
  // 构建单条消息项
  Widget _buildSingleMessageItem(BuildContext context, Message message) {
    final horizontalPadding = isCompact ? 8.0 : 16.0;
    final verticalPadding = isCompact ? 4.0 : 8.0;

    // 确定消息图标
    IconData messageIcon;
    if (message.type.toLowerCase().contains("follow")) {
      messageIcon = message.isRead ? Icons.person : Icons.person_add;
    } else {
      messageIcon = message.isRead ? Icons.mark_email_read : Icons.mark_email_unread;
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      // 未读消息突出显示
      elevation: message.isRead ? 1 : 3,
      color: (selectedMessage?.id == message.id)
          ? Colors.blue[100]
          : (message.isRead ? null : Colors.blue[50]),
      child: ListTile(
        leading: Icon(
          messageIcon,
          color: message.isRead ? Colors.grey : Colors.blue,
          size: isCompact ? 20 : 24,
        ),
        title: Text(
          message.content,
          style: TextStyle(
            fontWeight: message.isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: isCompact ? 14 : 16,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${_formatDateTime(message.createTime)}',
          style: TextStyle(fontSize: isCompact ? 11 : 12),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, size: isCompact ? 20 : 24),
          onPressed: () => _showDeleteDialog(context, message),
        ),
        onTap: () => onMessageTap(message),
      ),
    );
  }

  // 显示删除确认对话框
  void _showDeleteDialog(BuildContext context, Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除消息'),
        content: Text('确定要删除这条消息吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await messageService.deleteMessage(message.id);
              Navigator.pop(context);
            },
            child: Text('删除'),
          ),
        ],
      ),
    );
  }

  // 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${dateTime.year}/${dateTime.month}/${dateTime.day}';
    } else if (difference.inDays > 30) {
      return '${dateTime.month}月${dateTime.day}日';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}