// lib/widgets/components/screen/message/message_detail.dart
import 'package:flutter/material.dart';
import '../../../../models/message/message.dart';
import '../../../../models/message/message_type.dart';

class MessageDetail extends StatelessWidget {
  final Message message;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  final Function(Message) onViewDetail;

  const MessageDetail({
    Key? key,
    required this.message,
    required this.onClose,
    required this.onDelete,
    required this.onViewDetail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Divider(),
          SizedBox(height: 16),

          // 消息类型标签
          _buildTypeLabel(),
          SizedBox(height: 24),

          // 消息内容
          _buildContentSection(),
          SizedBox(height: 16),

          // 时间信息
          _buildTimeSection(),
          SizedBox(height: 24),

          // 如果是分组消息，显示引用内容
          if (message.isGrouped && message.references != null && message.references!.isNotEmpty)
            _buildReferencesSection(),

          Spacer(),

          // 操作按钮
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return AppBar(
      title: Text('消息详情'),
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: Icon(Icons.close),
          onPressed: onClose,
        ),
      ],
    );
  }

  Widget _buildTypeLabel() {
    final bool isCommentReply = message.type.toLowerCase().contains("comment") ||
        message.type == MessageType.commentReply.toString();

    final String typeText = isCommentReply ? '评论回复' : '帖子回复';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        typeText,
        style: TextStyle(color: Colors.blue[700]),
      ),
    );
  }

  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '内容',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Text(
          message.content,
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '时间',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Text(
          '${message.createTime.year}年${message.createTime.month}月${message.createTime.day}日 ${message.createTime.hour.toString().padLeft(2, '0')}:${message.createTime.minute.toString().padLeft(2, '0')}',
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildReferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '相关引用',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            message.lastContent ?? "无引用内容",
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                icon: Icon(Icons.delete),
                label: Text('删除'),
                onPressed: onDelete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.open_in_new),
                label: Text('查看详情'),
                onPressed: () => onViewDetail(message),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}