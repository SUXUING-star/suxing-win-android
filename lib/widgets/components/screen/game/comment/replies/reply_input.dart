// lib/widgets/components/screen/game/comment/replies/reply_input.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../providers/auth/auth_provider.dart';
import '../../../../../../services/main/game/comment/comment_service.dart';
import '../../../../dialogs/limiter/rate_limit_dialog.dart';

class ReplyInput extends StatefulWidget {
  final String gameId;
  final String parentId;
  final VoidCallback? onReplyAdded;

  const ReplyInput({
    Key? key,
    required this.gameId,
    required this.parentId,
    this.onReplyAdded,
  }) : super(key: key);

  @override
  State<ReplyInput> createState() => _ReplyInputState();
}

class _ReplyInputState extends State<ReplyInput> {
  final TextEditingController _controller = TextEditingController();
  final CommentService _commentService = CommentService();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    final reply = _controller.text.trim();
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

      _controller.clear();

      // 调用回调函数刷新父组件
      if (widget.onReplyAdded != null) {
        widget.onReplyAdded!();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('回复已提交'),
            duration: Duration(seconds: 2),
          ),
        );
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
          // 显示常规错误消息
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('回复评论失败: ${e.toString()}'),
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

    if (!authProvider.isLoggedIn) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: '回复评论...',
                border: OutlineInputBorder(),
              ),
              enabled: !_isSubmitting,
            ),
          ),
          const SizedBox(width: 8),
          _isSubmitting
              ? Container(
            margin: const EdgeInsets.only(left: 10),
            width: 20,
            height: 20,
            child: const CircularProgressIndicator(strokeWidth: 2),
          )
              : TextButton(
            onPressed: _submitReply,
            child: const Text('回复'),
          ),
        ],
      ),
    );
  }
}