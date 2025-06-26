// lib/widgets/components/screen/activity/comment/activity_comment_input.dart

/// 该文件定义了 ActivityCommentInput 组件，用于动态评论的输入。
/// ActivityCommentInput 提供评论文本输入、提交、登录提示和锁定状态显示。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:suxingchahui/models/user/user.dart'; // 用户模型所需
import 'package:suxingchahui/providers/inputs/input_state_provider.dart'; // 输入状态 Provider 所需
import 'package:suxingchahui/widgets/ui/buttons/login_prompt_button.dart'; // 登录提示按钮组件所需
import 'package:suxingchahui/widgets/ui/inputs/comment_input_field.dart'; // 评论输入字段组件所需

/// `ActivityCommentInput` 类：动态评论输入框的 StatelessWidget。
///
/// 该组件提供评论文本输入功能，支持登录提示和锁定状态显示。
class ActivityCommentInput extends StatelessWidget {
  final Function(String) onSubmit; // 提交评论回调
  final InputStateService inputStateService; // 输入状态服务
  final bool isAlternate; // 是否为交替布局
  final String hintText; // 输入框提示文本
  final bool isLocked; // 是否为锁定状态
  final bool isSubmitting; // 是否正在提交评论
  final User? currentUser; // 当前登录用户

  /// 构造函数。
  ///
  /// [onSubmit]：提交评论回调。
  /// [inputStateService]：输入状态服务。
  /// [currentUser]：当前登录用户。
  /// [isAlternate]：是否为交替布局。
  /// [hintText]：输入框提示文本。
  /// [isLocked]：是否为锁定状态。
  /// [isSubmitting]：是否正在提交评论。
  const ActivityCommentInput({
    super.key,
    required this.onSubmit,
    required this.inputStateService,
    required this.currentUser,
    this.isAlternate = false,
    this.hintText = '发表评论',
    this.isLocked = false,
    this.isSubmitting = false,
  });

  @override
  Widget build(BuildContext context) {
    return CommentInputField(
      inputStateService: inputStateService, // 输入状态服务
      currentUser: currentUser, // 当前用户
      hintText: hintText, // 提示文本
      submitButtonText: '发送', // 提交按钮文本
      isSubmitting: isSubmitting, // 提交状态
      onSubmit: (String comment) {
        if (isSubmitting) return; // 正在提交时阻止重复提交
        onSubmit(comment); // 调用提交回调
      },
      maxLines: 3, // 最大行数
      maxLength: 50, // 最大字符长度
      loginPrompt: const LoginPromptButton(
        // 登录提示按钮
        message: '登录后发表评论',
        buttonText: '立即登录',
      ),
      lockedContent: isLocked // 锁定状态下显示锁定内容
          ? Card(
              elevation: 1, // 阴影
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // 圆角边框
                side: BorderSide(color: Colors.grey.shade200), // 边框颜色
              ),
              child: Container(
                padding: const EdgeInsets.all(16), // 内边距
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '评论已锁定', // 锁定标题
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16), // 间距
                    Text('该内容已被锁定，无法评论'), // 锁定说明
                  ],
                ),
              ),
            )
          : null, // 非锁定状态不显示
    );
  }
}
