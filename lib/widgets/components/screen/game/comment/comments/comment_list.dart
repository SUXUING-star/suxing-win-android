// lib/widgets/components/screen/game/comment/comments/comment_list.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import '../../../../../../models/comment/comment.dart';
import 'comment_item.dart'; // 导入 CommentItem

class CommentList extends StatelessWidget {
  final List<Comment> comments;
  // *** 修改：接收来自 CommentsSection 的需要 ID 的回调 ***
  final Future<void> Function(String commentId, String content) onUpdateComment;
  final Future<void> Function(String commentId) onDeleteComment;
  // *** 修改：接收 onAddReply (这个签名本来就对) ***
  final Future<void> Function(String content, String parentId) onAddReply;
  // *** 修改：接收 loading 状态 Set ***
  final Set<String> deletingCommentIds;
  final Set<String> updatingCommentIds;

  // *** 修改：构造函数接收正确签名的回调和 loading 状态 ***
  const CommentList({
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
      return EmptyStateWidget( message: '暂无评论', iconData: Icons.maps_ugc_outlined );
    }

    // *** 修改：ListView.builder 内部创建 CommentItem 时，传递正确的参数 ***
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 0), // 你原来的代码
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        return CommentItem( // 创建 CommentItem
          key: ValueKey(comment.id), // 使用 Key
          comment: comment,
          // *** 把接收到的需要 ID 的回调直接传给 CommentItem ***
          // CommentItem 内部会用 comment.id 来调用它们
          onUpdateComment: onUpdateComment,
          onDeleteComment: onDeleteComment,
          // *** 把 onAddReply 直接传给 CommentItem ***
          // CommentItem 内部会用 comment.id 作为 parentId 调用它
          onAddReply: onAddReply,
          // *** 把 loading 状态传递给 CommentItem ***
          isDeleting: deletingCommentIds.contains(comment.id),
          isUpdating: updatingCommentIds.contains(comment.id),
        );
      },
    );
  }
}