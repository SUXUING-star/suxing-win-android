// lib/widgets/components/screen/game/comment/comments/game_comment_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/user/user_data_status.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import '../../../../../../models/comment/comment.dart';
import 'game_comment_item.dart'; // 导入 CommentItem

class GameCommentList extends StatelessWidget {
  final User? currentUser;
  final List<Comment> comments;
  final Future<void> Function(Comment comment, String content) onUpdateComment;
  final Future<void> Function(Comment comment) onDeleteComment;
  final Future<void> Function(String content, String parentId) onAddReply;
  final Set<String> deletingCommentIds;
  final Set<String> updatingCommentIds;

  const GameCommentList({
    super.key,
    required this.currentUser,
    required this.comments,
    required this.onUpdateComment, // 接收需要 ID 的 onUpdate
    required this.onDeleteComment, // 接收需要 ID 的 onDelete
    required this.onAddReply, // 接收 onAddReply
    required this.deletingCommentIds, // 接收 loading
    required this.updatingCommentIds, // 接收 loading
  });

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      // 空状态不变
      return const EmptyStateWidget(
          message: '暂无评论', iconData: Icons.maps_ugc_outlined);
    }
    final userInfoProvider = context.watch<UserInfoProvider>();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        final userId = comment.userId;
        userInfoProvider.ensureUserInfoLoaded(userId);
        final UserDataStatus userDataStatus =
            userInfoProvider.getUserStatus(userId);

        return GameCommentItem(
          key: ValueKey(comment.id), // 使用 Key
          currentUser: currentUser,
          comment: comment,
          userDataStatus: userDataStatus,
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
