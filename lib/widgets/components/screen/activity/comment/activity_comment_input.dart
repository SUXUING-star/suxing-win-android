// lib/widgets/components/screen/activity/comment/activity_comment_input_updated.dart

import 'package:flutter/material.dart';
import '../../../../../widgets/ui/inputs/comment_input_field.dart'; // 导入可复用的评论输入组件
import '../../../../../widgets/ui/buttons/login_prompt.dart';
class ActivityCommentInput extends StatefulWidget {
  final Function(String) onSubmit;
  final bool isAlternate; // 是否交替布局
  final String hintText;
  final bool isLocked; // 是否锁定状态
  final bool isSubmitting;

  const ActivityCommentInput({
    Key? key,
    required this.onSubmit,
    this.isAlternate = false,
    this.hintText = '发表评论...',
    this.isLocked = false, // 默认为未锁定
    this.isSubmitting = false,
  }) : super(key: key);

  @override
  _ActivityCommentInputState createState() => _ActivityCommentInputState();
}

class _ActivityCommentInputState extends State<ActivityCommentInput> {

  @override
  void dispose() {
    // --- 不再需要释放 Controller ---
    // _controller.dispose();
    super.dispose();
  }

  void _handleSubmit(String comment) {
    // 检查外部传入的提交状态
    if (widget.isSubmitting) return;

    // CommentInputField 内部应该已经处理了 trim 和空检查
    // 但为保险起见可以再检查一次
    if (comment.isEmpty) return;

    // --- 直接调用外部 onSubmit ---
    widget.onSubmit(comment);

  }


  @override
  Widget build(BuildContext context) {
    // 使用可复用的CommentInputField组件
    return CommentInputField(
      hintText: widget.hintText,
      submitButtonText: '发送',
      isSubmitting: widget.isSubmitting,
      onSubmit: _handleSubmit,
      maxLines: 3,
      // --- 2. Replace the custom Card with LoginPrompt ---
      loginPrompt: const LoginPrompt(
        message: '登录后发表评论', // 自定义提示信息
        buttonText: '立即登录',    // 自定义按钮文字
      ),
      lockedContent: widget.isLocked ? Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '评论已锁定',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text('该内容已被锁定，无法评论'),
            ],
          ),
        ),
      ) : null,
    );
  }
}