// lib/widgets/components/screen/game/comment/comments/game_comment_input.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../../../ui/inputs/comment_input_field.dart'; // 使用修改后的输入框

class GameCommentInput extends StatefulWidget {
  final Future<void> Function(String comment) onCommentAdded;
  final bool isSubmitting;
  final String gameId; // 需要传入 gameId 以生成 slotName

  const GameCommentInput({
    super.key,
    required this.onCommentAdded,
    required this.isSubmitting,
    required this.gameId,
  });

  @override
  State<GameCommentInput> createState() => _GameCommentInputState();
}

class _GameCommentInputState extends State<GameCommentInput> {
  late String _slotName;

  @override
  void initState() {
    super.initState();
    // 根据 gameId 生成唯一的 slotName
    _slotName = 'game_comment_${widget.gameId}';
  }

  Future<void> _handleCommentSubmit(String comment) async {
    if (comment.isEmpty || widget.isSubmitting) return;
    try {
      await widget.onCommentAdded(comment); // 调用外部提交逻辑
      // 成功后清除状态
      if (mounted) {
        final service = Provider.of<InputStateService>(context, listen: false);
        service.clearText(_slotName);
      }
    } catch (e) {
      // 提交失败，保留输入内容
      if (mounted) {
        AppSnackBar.showError(context, '评论发表失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommentInputField(
      slotName: _slotName, // 传递 slotName
      onSubmit: _handleCommentSubmit,
      hintText: '发表评论...',
      submitButtonText: '发表',
      isSubmitting: widget.isSubmitting,
      maxLines: 3,
      maxLength: 100, // 或根据需要调整
    );
  }
}

