// lib/widgets/components/screen/activity/comment/activity_comment_input.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/widgets/ui/buttons/login_prompt_button.dart';
import 'package:suxingchahui/widgets/ui/inputs/comment_input_field.dart';

class ActivityCommentInput extends StatelessWidget {
  final Function(String) onSubmit;
  final InputStateService inputStateService;
  final bool isAlternate; // 是否交替布局
  final String hintText;
  final bool isLocked; // 是否锁定状态
  final bool isSubmitting;
  final User? currentUser;

  const ActivityCommentInput({
    super.key,
    required this.onSubmit,
    required this.inputStateService,
    required this.currentUser,
    this.isAlternate = false,
    this.hintText = '发表评论...',
    this.isLocked = false, // 默认为未锁定
    this.isSubmitting = false,
  });

  @override
  Widget build(BuildContext context) {
    return CommentInputField(
      inputStateService: inputStateService,
      currentUser: currentUser,
      hintText: hintText,
      submitButtonText: '发送',
      isSubmitting: isSubmitting,
      onSubmit: (String comment) {
        // 在调用外部回调前，检查提交状态
        if (isSubmitting) return;
        // CommentInputField 应该已经处理了空检查，这里直接调用
        onSubmit(comment);
      },
      maxLines: 3,
      maxLength: 50,
      loginPrompt: const LoginPromptButton(
        message: '登录后发表评论', // 自定义提示信息
        buttonText: '立即登录', // 自定义按钮文字
      ),
      lockedContent: isLocked
          ? Card(
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
            )
          : null,
    );
  }
}
