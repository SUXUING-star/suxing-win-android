// lib/widgets/components/screen/game/comment/comment_input.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../services/main/game/comment/comment_service.dart';
import '../../../../../../providers/auth/auth_provider.dart';
import '../../../../dialogs/limiter/rate_limit_dialog.dart';

class CommentInput extends StatefulWidget {
  final String gameId;
  final VoidCallback? onCommentAdded; // 添加回调函数

  const CommentInput({
    Key? key,
    required this.gameId,
    this.onCommentAdded, // 初始化回调
  }) : super(key: key);

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final TextEditingController _controller = TextEditingController();
  final CommentService _commentService = CommentService();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final comment = _controller.text.trim();
    if (comment.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _commentService.addComment(widget.gameId, comment);

      // 清空输入并通知父组件刷新
      _controller.clear();

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
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isLoggedIn) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/login'),
          child: const Text('登录后发表评论'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: '发表评论...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              enabled: !_isSubmitting,
            ),
          ),
          const SizedBox(width: 16),
          _isSubmitting
              ? Container(
            margin: const EdgeInsets.only(left: 10),
            width: 24,
            height: 24,
            child: const CircularProgressIndicator(),
          )
              : ElevatedButton(
            onPressed: _submitComment,
            child: const Text('发表'),
          ),
        ],
      ),
    );
  }
}