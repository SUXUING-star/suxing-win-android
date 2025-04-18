// lib/widgets/components/screen/game/comment/replies/reply_input.dart
import 'package:flutter/material.dart';
import '../../../../../ui/inputs/comment_input_field.dart'; // 使用通用输入框

class ReplyInput extends StatefulWidget {
  // 修改: 接收回调和状态
  final Future<void> Function(String reply) onSubmitReply;
  final VoidCallback? onCancel;
  final bool isSubmitting; // 由 CommentItem 传入

  const ReplyInput({ Key? key, required this.onSubmitReply, required this.isSubmitting, this.onCancel }) : super(key: key);

  @override
  State<ReplyInput> createState() => _ReplyInputState();
}

class _ReplyInputState extends State<ReplyInput> {
  // 修改: 只保留本地 Controller
  final TextEditingController _controller = TextEditingController();

  // 修改: 提交逻辑
  Future<void> _submitReply() async { // 改为无参数
    final reply = _controller.text.trim();
    if (reply.isEmpty || widget.isSubmitting) return;
    await widget.onSubmitReply(reply); // 调用父级 (CommentItem) 回调
    if (mounted) _controller.clear(); // 清空
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
      onSubmit: (_) => _submitReply(), // 修改: 传递包装后的本地方法
      hintText: '回复评论...',
      submitButtonText: '回复',
      isSubmitting: widget.isSubmitting, // 传递 loading 状态
      isReply: true,
      maxLines: 1,
      onCancel: widget.onCancel,
    );
  }
}