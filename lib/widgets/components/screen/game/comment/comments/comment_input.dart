// lib/widgets/components/screen/game/comment/comments/comment_input.dart
import 'package:flutter/material.dart';
import '../../../../../ui/inputs/comment_input_field.dart'; // 使用通用输入框

class CommentInput extends StatefulWidget {
  // 修改: 接收回调和状态
  final Future<void> Function(String comment) onCommentAdded;
  final bool isSubmitting;

  const CommentInput({ super.key, required this.onCommentAdded, required this.isSubmitting });

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  // 修改: 只保留本地 Controller
  final TextEditingController _controller = TextEditingController();

  // 修改: 提交逻辑
  Future<void> _submitComment() async { // 改为无参数
    final comment = _controller.text.trim();
    if (comment.isEmpty || widget.isSubmitting) return;
    await widget.onCommentAdded(comment); // 调用父级回调
    if (mounted) _controller.clear(); // 清空输入框
  }

  // 添加: 释放 Controller
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 修改: 使用通用 CommentInputField
    return CommentInputField(
      controller: _controller,
      onSubmit: (_) => _submitComment(), // 修改: 传递包装后的本地方法
      hintText: '发表评论...',
      submitButtonText: '发表',
      isSubmitting: widget.isSubmitting, // 传递 loading 状态
      maxLines: 3,
      maxLength: 50,
    );
  }
}