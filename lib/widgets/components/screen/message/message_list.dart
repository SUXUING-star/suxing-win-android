import 'package:flutter/material.dart';
import '../../../../models/message/message.dart';
import 'message_list_item.dart'; // 引入列表项 Widget

/// 消息列表 Widget，用于显示特定分组下的消息
class MessageList extends StatelessWidget {
  final List<Message> messages;     // 要显示的消息列表
  final Function(Message) onMessageTap; // 列表项点击回调
  final Message? selectedMessage; // 当前选中的消息 (用于高亮)
  final bool isCompact;           // 是否为紧凑模式

  const MessageList({
    Key? key,
    required this.messages,
    required this.onMessageTap,
    this.selectedMessage,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 如果列表为空，可以在这里显示提示，但通常由父组件处理
    // if (messages.isEmpty) {
    //   return Padding(
    //     padding: const EdgeInsets.all(16.0),
    //     child: Text('暂无此类消息', style: TextStyle(color: Colors.grey)),
    //   );
    // }

    // 使用 ListView.builder 构建列表，提高性能
    return ListView.builder(
      shrinkWrap: true, // 重要：让 ListView 高度自适应内容 (因为它通常在 ExpansionTile 或 Column 中)
      physics: NeverScrollableScrollPhysics(), // 重要：禁用内部滚动，由外部滚动控制
      itemCount: messages.length, // 列表项数量
      itemBuilder: (context, index) {
        final message = messages[index];
        // 构建每一项，并添加底部分割线（除了最后一项）
        return Column(
          children: [
            MessageListItem(
              message: message,
              onTap: () => onMessageTap(message), // 传递点击事件
              isSelected: selectedMessage?.id == message.id, // 判断是否选中
              isCompact: isCompact, // 传递紧凑模式设置
            ),
            // 在非最后一项的后面添加分割线
            if (index < messages.length - 1)
              Divider(
                  height: 1,           // 分割线高度
                  thickness: 0.5,      // 分割线厚度
                  indent: 72,        // 左侧缩进 (大致对齐 leading 图标后的区域)
                  endIndent: 16,     // 右侧缩进
                  color: Colors.grey[200] // 分割线颜色
              ),
          ],
        );
      },
      padding: EdgeInsets.zero, // 移除 ListView 默认的上下内边距
    );
  }
}