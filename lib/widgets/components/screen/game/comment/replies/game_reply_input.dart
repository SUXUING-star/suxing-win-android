// lib/widgets/components/screen/game/comment/replies/game_reply_input.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../../../ui/inputs/comment_input_field.dart'; // 使用修改后的输入框

class GameReplyInput extends StatefulWidget {
  final Future<void> Function(String reply) onSubmitReply;
  final VoidCallback? onCancel;
  final bool isSubmitting;
  final String parentCommentId; // 需要传入父评论 ID 以生成 slotName

  const GameReplyInput({
    super.key,
    required this.onSubmitReply,
    required this.isSubmitting,
    required this.parentCommentId,
    this.onCancel,
  });

  @override
  State<GameReplyInput> createState() => _GameReplyInputState();
}

class _GameReplyInputState extends State<GameReplyInput> {
  late String _slotName;

  @override
  void initState() {
    super.initState();
    // 根据 parentCommentId 生成唯一的 slotName
    _slotName = 'game_reply_${widget.parentCommentId}';
  }

  Future<void> _handleReplySubmit(String reply) async {
    if (reply.isEmpty || widget.isSubmitting) return;
    try {
      await widget.onSubmitReply(reply); // 调用外部提交逻辑
      // 成功后清除状态
      if (mounted) {
        // 保持用途明确
        InputStateService? inputStateService =
            Provider.of<InputStateService>(context, listen: false);
        inputStateService.clearText(_slotName);
        inputStateService = null;
      }
      // 成功后也可以选择调用 onCancel 关闭输入框
      // widget.onCancel?.call();
    } catch (e) {
      // 提交失败，保留输入内容
      if (mounted) {
        AppSnackBar.showError(context, '回复失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommentInputField(
      slotName: _slotName,
      // 传递 slotName
      onSubmit: _handleReplySubmit,
      hintText: '回复评论...',
      // 可以根据需要传入更具体的 hint
      submitButtonText: '回复',
      isSubmitting: widget.isSubmitting,
      isReply: true,
      maxLength: 50,
      // 或根据需要调整
      maxLines: 1,
      // 回复通常是单行
      onCancel: widget.onCancel,
    );
  }
}
