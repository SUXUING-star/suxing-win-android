// lib/widgets/components/screen/message/message_tabs.dart
import 'package:flutter/material.dart';
import '../../../../models/message/message.dart';
import '../../../../models/message/message_type.dart';
import '../../../../services/main/message/message_service.dart';
import 'message_list.dart';

class MessageTabs extends StatefulWidget {
  final Map<String, List<Message>> groupedMessages;
  final TabController tabController;
  final List<String> tabLabels;
  final MessageService messageService;
  final Function(Message) onMessageTap;
  final Message? selectedMessage;
  final bool isCompact;
  final Function() onRefresh;

  const MessageTabs({
    Key? key,
    required this.groupedMessages,
    required this.tabController,
    required this.tabLabels,
    required this.messageService,
    required this.onMessageTap,
    required this.onRefresh,
    this.selectedMessage,
    this.isCompact = false,
  }) : super(key: key);

  @override
  _MessageTabsState createState() => _MessageTabsState();
}

class _MessageTabsState extends State<MessageTabs> {
  @override
  Widget build(BuildContext context) {
// In the build method in _MessageTabsState class
    return RefreshIndicator(
      onRefresh: () async {
        await widget.onRefresh();
      },
      child: TabBarView(
        controller: widget.tabController,
        children: [
          // 全部消息
          MessageList(
            messages: _getAllMessages(),
            messageService: widget.messageService,
            onMessageTap: widget.onMessageTap,
            selectedMessage: widget.selectedMessage,
            isCompact: widget.isCompact,
          ),

          // 帖子回复
          MessageList(
            messages: _getPostReplies(),
            messageService: widget.messageService,
            onMessageTap: widget.onMessageTap,
            selectedMessage: widget.selectedMessage,
            isCompact: widget.isCompact,
          ),

          // 评论回复
          MessageList(
            messages: _getCommentReplies(),
            messageService: widget.messageService,
            onMessageTap: widget.onMessageTap,
            selectedMessage: widget.selectedMessage,
            isCompact: widget.isCompact,
          ),

          // 关注通知 - 新增
          MessageList(
            messages: _getFollowNotifications(),
            messageService: widget.messageService,
            onMessageTap: widget.onMessageTap,
            selectedMessage: widget.selectedMessage,
            isCompact: widget.isCompact,
          ),
        ],
      ),
    );
  }
  // 获取关注通知
  List<Message> _getFollowNotifications() {
    return widget.groupedMessages["follow_notification"] ?? [];
  }

  // 获取所有消息的平铺列表
  List<Message> _getAllMessages() {
    List<Message> allMessages = [];
    widget.groupedMessages.forEach((type, messages) {
      allMessages.addAll(messages);
    });

    // 按时间排序，最新的在前面
    allMessages.sort((a, b) => b.displayTime.compareTo(a.displayTime));

    return allMessages;
  }

  // 获取帖子回复消息
  List<Message> _getPostReplies() {
    return widget.groupedMessages[MessageType.postReply.toString()] ?? [];
  }

  // 获取评论回复消息
  List<Message> _getCommentReplies() {
    return widget.groupedMessages[MessageType.commentReply.toString()] ?? [];
  }
}