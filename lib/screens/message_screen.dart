// lib/screens/message_screen.dart
import 'package:flutter/material.dart';
import '../services/message_service.dart';
import '../models/message/message.dart';
import '../models/message/message_type.dart';
import 'game/detail/game_detail_screen.dart';
import 'forum/post/post_detail_screen.dart';

class MessageScreen extends StatelessWidget {
  final MessageService _messageService = MessageService();

  void _handleMessageTap(BuildContext context, Message message) async {
    // 先标记为已读
    if (!message.isRead) {
      await _messageService.markAsRead(message.id);
    }

    // 根据消息类型跳转到相应页面
    if (message.type == MessageType.commentReply.toString() && message.gameId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameDetailScreen(gameId: message.gameId!),
        ),
      );
    } else if (message.type == MessageType.postReply.toString() && message.postId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailScreen(postId: message.postId!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('消息中心'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: StreamBuilder<List<Message>>(
        stream: _messageService.getUserMessages(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final messages = snapshot.data!;
          if (messages.isEmpty) {
            return Center(child: Text('暂无消息'));
          }

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return MessageItem(
                message: message,
                onTap: () => _handleMessageTap(context, message),
              );
            },
          );
        },
      ),
    );
  }
}

class MessageItem extends StatelessWidget {
  final Message message;
  final VoidCallback onTap;

  const MessageItem({
    Key? key,
    required this.message,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          message.isRead ? Icons.mark_email_read : Icons.mark_email_unread,
          color: message.isRead ? Colors.grey : Colors.blue,
        ),
        title: Text(message.content),
        subtitle: Text(
          '${message.createTime.toString().split('.')[0]}',
          style: TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline),
          onPressed: () {
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
                    onPressed: () {
                      MessageService().deleteMessage(message.id);
                      Navigator.pop(context);
                    },
                    child: Text('删除'),
                  ),
                ],
              ),
            );
          },
        ),
        onTap: onTap,
      ),
    );
  }
}