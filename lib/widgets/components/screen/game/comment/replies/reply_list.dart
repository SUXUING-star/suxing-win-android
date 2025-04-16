import 'package:flutter/material.dart';
import '../../../../../../models/comment/comment.dart';
import 'reply_item.dart'; // Corrected import name

class ReplyList extends StatelessWidget {
  final List<Comment> replies;
  final Future<void> Function(String replyId, String content) onUpdateReply;
  final Future<void> Function(String replyId) onDeleteReply;

  const ReplyList({
    Key? key,
    required this.replies,
    required this.onUpdateReply,
    required this.onDeleteReply,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: replies.length,
      itemBuilder: (context, index) {
        final reply = replies[index];
        // --- Pass Data and Callbacks Down to ReplyItem ---
        return ReplyItem( // Use the correct ReplyItem name
          key: ValueKey(reply.id),
          reply: reply,
          // Pass specific update/delete for this reply
          onUpdate: (newContent) => onUpdateReply(reply.id, newContent),
          onDelete: () => onDeleteReply(reply.id),
          // REMOVED: gameId
          // REMOVED: onReplyChanged
        );
      },
    );
  }
}