// lib/widgets/components/screen/message/message_list.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/message/message.dart';
import 'package:suxingchahui/widgets/ui/animation/animated_list_view.dart';
import 'message_list_item.dart';

class MessageList extends StatelessWidget {
  final List<Message> messages;
  final Function(Message) onMessageTap;
  final Message? selectedMessage;
  final bool isCompact;

  const MessageList({
    super.key,
    required this.messages,
    required this.onMessageTap,
    this.selectedMessage,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    // 使用封装好的 AnimatedListView
    return AnimatedListView<Message>(
      items: messages,
      shrinkWrap: true,
      // 关键：使其能在外部的 Column/ScrollView 内正常工作
      physics: const NeverScrollableScrollPhysics(),
      // 关键：禁用其内部滚动
      padding: EdgeInsets.zero,
      // 通常由外部容器控制 padding
      itemBuilder: (context, index, message) {
        // 为了在 item 之间显示分割线，我们可以在这里做个小处理
        return Column(
          children: [
            MessageListItem(
              message: message,
              onTap: () => onMessageTap(message),
              isSelected: selectedMessage?.id == message.id,
              isCompact: isCompact,
            ),
            if (index < messages.length - 1) // 不是最后一个 item 才显示分割线
              Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 72,
                  endIndent: 16,
                  color: Colors.grey[200]),
          ],
        );
      },
    );
  }
}
