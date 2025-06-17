// lib/widgets/components/screen/game/comment/comments/game_comment_list.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/services/main/user/user_info_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/models/game/game_comment.dart';
import 'game_comment_item.dart';

class GameCommentList extends StatelessWidget {
  final User? currentUser;
  final AuthProvider authProvider;
  final UserInfoService infoService;
  final UserFollowService followService;
  final InputStateService inputStateService;
  final List<GameComment> comments;
  final Future<void> Function(GameComment comment, String content)
      onUpdateComment;
  final Future<void> Function(GameComment comment) onDeleteComment;
  final Future<void> Function(String content, String parentId) onAddReply;
  final Set<String> deletingCommentIds;
  final Set<String> updatingCommentIds;

  const GameCommentList({
    super.key,
    required this.currentUser,
    required this.authProvider,
    required this.infoService,
    required this.followService,
    required this.inputStateService,
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

    return StreamBuilder<User?>(
      stream: authProvider.currentUserStream,
      initialData: authProvider.currentUser,
      builder: (context, authSnapshot) {
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 0),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            return GameCommentItem(
              key: ValueKey(comment.id),
              currentUser: authSnapshot.data,
              authProvider: authProvider,
              comment: comment,
              infoService: infoService,
              inputStateService: inputStateService,
              followService: followService,
              onUpdateComment: onUpdateComment,
              onDeleteComment: onDeleteComment,
              onAddReply: onAddReply,
              isDeleting: deletingCommentIds.contains(comment.id),
              isUpdating: updatingCommentIds.contains(comment.id),
            );
          },
        );
      },
    );
  }
}
