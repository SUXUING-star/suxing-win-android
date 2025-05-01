// lib/widgets/components/screen/game/comment/comments/game_comment_list.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import '../../../../../../models/comment/comment.dart';
import 'game_comment_item.dart'; // 导入 CommentItem

class GameCommentList extends StatelessWidget {
  final List<Comment> comments;
  final Future<void> Function(String commentId, String content) onUpdateComment;
  final Future<void> Function(String commentId) onDeleteComment;
  final Future<void> Function(String content, String parentId) onAddReply;
  final Set<String> deletingCommentIds;
  final Set<String> updatingCommentIds;

  // *** 修改：构造函数接收正确签名的回调和 loading 状态 ***
  const GameCommentList({
    super.key,
    required this.comments,
    required this.onUpdateComment, // 接收需要 ID 的 onUpdate
    required this.onDeleteComment, // 接收需要 ID 的 onDelete
    required this.onAddReply,      // 接收 onAddReply
    required this.deletingCommentIds, // 接收 loading
    required this.updatingCommentIds, // 接收 loading
  });

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) { // 空状态不变
      return const EmptyStateWidget( message: '暂无评论', iconData: Icons.maps_ugc_outlined );
    }

    // *** 修改：ListView.builder 内部创建 CommentItem 时，传递正确的参数 ***
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 0), // 你原来的代码
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        return GameCommentItem( // 创建 CommentItem
          key: ValueKey(comment.id), // 使用 Key
          comment: comment,
          onUpdateComment: onUpdateComment,
          onDeleteComment: onDeleteComment,
          onAddReply: onAddReply,
          isDeleting: deletingCommentIds.contains(comment.id),
          isUpdating: updatingCommentIds.contains(comment.id),
        );
      },
    );
  }
}