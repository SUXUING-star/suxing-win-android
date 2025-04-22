// lib/widgets/components/screen/game/comment/replies/reply_list.dart
import 'package:flutter/material.dart';
import '../../../../../../models/comment/comment.dart';
import 'reply_item.dart'; // 导入 ReplyItem

class ReplyList extends StatelessWidget {
  final List<Comment> replies;
  // *** 接收来自 CommentItem 的需要 ID 的回调 ***
  final Future<void> Function(String replyId, String content) onUpdateReply;
  final Future<void> Function(String replyId) onDeleteReply;
  // *** 不需要接收 loading 状态 Set ***

  const ReplyList({
    super.key,
    required this.replies,
    required this.onUpdateReply, // 接收需要 ID 的 onUpdate
    required this.onDeleteReply, // 接收需要 ID 的 onDelete
  });

  @override
  Widget build(BuildContext context) {
    // *** 在 ListView.builder 中创建 ReplyItem 时，包装回调 ***
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: replies.length,
      itemBuilder: (context, index) {
        final reply = replies[index];
        return ReplyItem(
          key: ValueKey(reply.id),
          reply: reply,
          // *** 把收到的需要 ID 的回调包装成不需要 ID 的版本传给 ReplyItem ***
          onUpdate: (newContent) => onUpdateReply(reply.id, newContent), // 传入 reply.id
          onDelete: () => onDeleteReply(reply.id),                   // 传入 reply.id
          // *** ReplyItem 自己的 loading 状态由它自己或顶层管理，这里不传 ***
        );
      },
    );
  }
}