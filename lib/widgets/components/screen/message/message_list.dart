// 文件: lib/widgets/components/screen/message/message_list.dart
import 'package:flutter/material.dart';
import '../../../../models/message/message.dart';
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
    // --- 修改开始: 使用 Column 替代 ListView.builder ---
    return Column(
      // Column 不需要 shrinkWrap 和 physics
      children: List.generate(messages.length, (index) { // 使用 List.generate 创建列表项
        final message = messages[index];
        // 保留 Column 结构以包含 Item 和 Divider
        return Column(
          children: [
            MessageListItem(
              message: message,
              onTap: () => onMessageTap(message),
              isSelected: selectedMessage?.id == message.id,
              isCompact: isCompact,
            ),
            if (index < messages.length - 1)
              Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 72,
                  endIndent: 16,
                  color: Colors.grey[200]),
          ],
        );
      }),
      // Column 没有默认 padding，所以 padding: EdgeInsets.zero 也可以移除
    );
    // --- 修改结束 ---
  }
}