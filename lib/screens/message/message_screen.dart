// lib/screens/message_screen.dart
import 'package:flutter/material.dart';
import '../services/main/message/message_service.dart';
import '../models/message/message.dart';
import '../models/message/message_type.dart';
import 'game/detail/game_detail_screen.dart';
import 'forum/post/post_detail_screen.dart';

class MessageScreen extends StatefulWidget {
  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final MessageService _messageService = MessageService();
  List<Message> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 进入页面时自动标记所有消息为已读
    _markAllAsRead();
  }

  // 标记所有消息为已读
  Future<void> _markAllAsRead() async {
    try {
      await _messageService.markAllAsRead();
    } catch (e) {
      print('标记所有消息为已读失败: $e');
    }
  }

  void _handleMessageTap(BuildContext context, Message message) async {
    // 先标记为已读
    if (!message.isRead) {
      await _messageService.markAsRead(message.id);
      // 更新本地消息状态
      setState(() {
        int index = _messages.indexWhere((m) => m.id == message.id);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(isRead: true);
        }
      });
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
        actions: [
          IconButton(
            icon: Icon(Icons.done_all),
            tooltip: '全部标为已读',
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: StreamBuilder<List<Message>>(
        stream: _messageService.getUserMessages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _messages.isEmpty) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            _messages = snapshot.data!;
          }

          if (_messages.isEmpty) {
            return Center(child: Text('暂无消息'));
          }

          return ListView.builder(
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return MessageItem(
                message: message,
                onTap: () => _handleMessageTap(context, message),
                onDelete: () async {
                  await _messageService.deleteMessage(message.id);
                  setState(() {
                    _messages.removeAt(index);
                  });
                },
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
  final VoidCallback onDelete;

  const MessageItem({
    Key? key,
    required this.message,
    required this.onTap,
    required this.onDelete,
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
                      onDelete();
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