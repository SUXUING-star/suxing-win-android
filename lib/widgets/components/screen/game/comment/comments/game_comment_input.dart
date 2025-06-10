// lib/widgets/components/screen/game/comment/comments/game_comment_input.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackBar.dart';
import 'package:suxingchahui/widgets/ui/inputs/comment_input_field.dart';

class GameCommentInput extends StatelessWidget {
  final Future<void> Function(String comment) onCommentAdded;
  final bool isSubmitting;
  final User? currentUser;
  final InputStateService inputStateService;
  final String slotName;

  const GameCommentInput({
    super.key,
    required this.onCommentAdded,
    required this.isSubmitting,
    required String gameId, // 构造函数仍然接收 gameId
    required this.currentUser,
    required this.inputStateService,
  }) : slotName = 'game_comment_$gameId'; // 在初始化列表中生成 slotName

  Future<void> _handleCommentSubmit(
      BuildContext context, String comment) async {
    if (comment.isEmpty || isSubmitting) return;
    try {
      await onCommentAdded(comment);
      if (context.mounted) {
        inputStateService.clearText(slotName); // 使用 this.slotName
      }
    } catch (e) {
      AppSnackBar.showError("操作失败,${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommentInputField(
      currentUser: currentUser,
      inputStateService: inputStateService,
      slotName: slotName, // 直接使用成员变量 slotName
      onSubmit: (String comment) {
        _handleCommentSubmit(context, comment);
      },
      hintText: '发表评论...',
      submitButtonText: '发表',
      isSubmitting: isSubmitting,
      maxLines: 3,
      maxLength: 100,
    );
  }
}
