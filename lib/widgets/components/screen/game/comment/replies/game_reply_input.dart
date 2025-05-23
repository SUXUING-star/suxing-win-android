// lib/widgets/components/screen/game/comment/replies/game_reply_input.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/widgets/ui/inputs/comment_input_field.dart'; // 使用修改后的输入框

class GameReplyInput extends StatelessWidget {
  final User? currentUser;
  final Future<void> Function(String reply) onSubmitReply;
  final VoidCallback? onCancel;
  final bool isSubmitting;
  final InputStateService inputStateService;
  final String slotName; // 直接使用 slotName

  GameReplyInput({
    super.key,
    required this.currentUser,
    required this.onSubmitReply,
    required this.isSubmitting,
    required String parentCommentId, // 构造函数仍然接收 parentCommentId
    required this.inputStateService,
    this.onCancel,
  }) : slotName = 'game_reply_$parentCommentId'; // 在初始化列表中生成 slotName

  Future<void> _handleReplySubmit(BuildContext context, String reply) async {
    if (reply.isEmpty || isSubmitting) return;
    try {
      await onSubmitReply(reply); // 调用外部提交逻辑
      // 成功后清除状态
      if (context.mounted) {
        inputStateService.clearText(slotName); // 使用 this.slotName
      }
      // 成功后也可以选择调用 onCancel 关闭输入框
      // onCancel?.call(); // 如果需要，可以取消注释这行
    } catch (e) {
      // 提交失败，保留输入内容
      if (context.mounted) {
        AppSnackBar.showError(context, '回复失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommentInputField(
      inputStateService: inputStateService,
      slotName: slotName, // 直接使用成员变量 slotName
      currentUser: currentUser, // 直接使用传入的 currentUser
      onSubmit: (String reply) {
        _handleReplySubmit(context, reply);
      },
      hintText: '回复评论...',
      submitButtonText: '回复',
      isSubmitting: isSubmitting,
      isReply: true,
      maxLength: 50,
      maxLines: 1,
      onCancel: onCancel,
    );
  }
}
