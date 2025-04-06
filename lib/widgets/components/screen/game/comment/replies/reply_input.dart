// lib/widgets/components/screen/game/comment/replies/reply_input.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../../dialogs/limiter/rate_limit_dialog.dart';
import '../../../../../ui/inputs/comment_input_field.dart'; // 导入新的评论输入组件

class ReplyInput extends StatefulWidget {
  final String gameId;
  final String parentId;
  final VoidCallback? onReplyAdded;
  final VoidCallback? onCancel;

  const ReplyInput({
    Key? key,
    required this.gameId,
    required this.parentId,
    this.onReplyAdded,
    this.onCancel,
  }) : super(key: key);

  @override
  State<ReplyInput> createState() => _ReplyInputState();
}

class _ReplyInputState extends State<ReplyInput> {
  final GameService _commentService = GameService();
  bool _isSubmitting = false;

  Future<void> _submitReply(String reply) async {
    if (reply.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _commentService.addComment(
        widget.gameId,
        reply,
        parentId: widget.parentId,
      );

      // 调用回调函数刷新父组件
      if (widget.onReplyAdded != null) {
        widget.onReplyAdded!();
      }

      if (mounted) {
        AppSnackBar.showSuccess(context, '回复已提交');
      }
    } catch (e) {
      if (mounted) {
        // 检查是否为速率限制错误
        final errorMsg = e.toString();
        if (errorMsg.contains('评论速率超限')) {
          // 解析剩余时间并显示对话框
          final remainingSeconds = parseRemainingSecondsFromError(errorMsg);
          showRateLimitDialog(context, remainingSeconds);
        } else {
          AppSnackBar.showError(context, '回复评论失败: ${e.toString()}');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommentInputField(
      hintText: '回复评论...',
      submitButtonText: '回复',
      isSubmitting: _isSubmitting,
      onSubmit: _submitReply,
      isReply: true, // 标记为回复模式
      maxLines: 1, // 回复通常使用单行输入
    );
  }
}