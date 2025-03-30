// lib/widgets/components/screen/game/comment/comment_input_updated.dart
import 'package:flutter/material.dart';
import '../../../../../../services/main/game/comment/comment_service.dart';
import '../../../../dialogs/limiter/rate_limit_dialog.dart';
import '../../../../../ui/inputs/comment_input_field.dart'; // 导入新的评论输入组件

class CommentInput extends StatefulWidget {
  final String gameId;
  final VoidCallback? onCommentAdded;

  const CommentInput({
    Key? key,
    required this.gameId,
    this.onCommentAdded,
  }) : super(key: key);

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final CommentService _commentService = CommentService();
  bool _isSubmitting = false;

  Future<void> _submitComment(String comment) async {
    if (comment.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _commentService.addComment(widget.gameId, comment);

      // 调用刷新回调
      if (widget.onCommentAdded != null) {
        widget.onCommentAdded!();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('成功发表评论'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        // 检查是否为速率限制错误
        final errorMsg = e.toString();
        if (errorMsg.contains('评论速率超限')) {
          // 解析剩余时间并显示对话框
          final remainingSeconds = parseRemainingSecondsFromError(errorMsg);
          showRateLimitDialog(context, remainingSeconds);
        } else {
          // 显示常规错误消息
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('发表评论失败: ${e.toString()}'),
              duration: Duration(seconds: 2),
            ),
          );
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
      hintText: '发表评论...',
      submitButtonText: '发表',
      isSubmitting: _isSubmitting,
      onSubmit: _submitComment,
      maxLines: 3,
    );
  }
}