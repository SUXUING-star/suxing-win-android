import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import '../../../../../../models/comment/comment.dart';
import 'comment_item.dart';

class CommentList extends StatelessWidget { // Changed to StatelessWidget
  final List<Comment> comments;
  final Future<void> Function(String commentId, String content) onUpdateComment;
  final Future<void> Function(String commentId) onDeleteComment;
  final Future<void> Function(String content, String parentId) onAddReply;

  const CommentList({
    Key? key,
    required this.comments,
    required this.onUpdateComment,
    required this.onDeleteComment,
    required this.onAddReply,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      return EmptyStateWidget(
        message: '暂无评论',
        iconData: Icons.maps_ugc_outlined,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: comments.length,
        itemBuilder: (context, index) {
          final comment = comments[index];
          // --- Pass Data and Callbacks Down to CommentItem ---
          return CommentItem(
            key: ValueKey(comment.id), // Use comment ID as key for better state management
            comment: comment,
            onUpdate: (id,newContent) => onUpdateComment(comment.id, newContent),
            onDelete: (id) => onDeleteComment(comment.id),
            onAddReply: onAddReply,
          );
        },
      ),
    );
  }
}