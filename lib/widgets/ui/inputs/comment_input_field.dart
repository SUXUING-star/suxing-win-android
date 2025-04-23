// lib/widgets/ui/inputs/comment_input_field.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import '../buttons/app_button.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../utils/navigation/navigation_utils.dart';
import '../buttons/login_prompt.dart';
import 'text_input_field.dart'; // <--- 导入咱们牛逼的组件

class CommentInputField extends StatefulWidget {
  final Function(String) onSubmit;
  final TextEditingController? controller;
  final String hintText;
  final int maxLines;
  final int maxLength;
  final String submitButtonText;
  final bool isSubmitting;
  final bool isReply;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry contentPadding;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final double buttonSpacing;
  final VoidCallback? onLoginRequired;
  final Widget? loginPrompt;
  final Widget? lockedContent;
  final VoidCallback? onCancel;

  const CommentInputField({
    super.key,
    this.controller,
    required this.onSubmit,
    this.hintText = '发表评论...',
    this.submitButtonText = '发表',
    this.isSubmitting = false,
    this.isReply = false,
    this.maxLines = 3,
    this.maxLength = 100,
    this.padding = const EdgeInsets.all(16.0),
    this.contentPadding =
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.textStyle,
    this.hintStyle,
    this.buttonSpacing = 8.0,
    this.onLoginRequired,
    this.loginPrompt,
    this.lockedContent,
    this.onCancel,
  });

  @override
  State<CommentInputField> createState() => _CommentInputFieldState();
}

class _CommentInputFieldState extends State<CommentInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode; // FocusNode 需要被管理
  bool _isInternalController = false;
  bool _isInternalFocusNode = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller = TextEditingController();
      _isInternalController = true;
    } else {
      _controller = widget.controller!;
      _isInternalController = false;
    }
    // FocusNode 也需要同样的逻辑，如果外部没传，就内部创建
    _focusNode = FocusNode(); // TextInputField 内部也会处理，但为了 unfocus，这里也保留
    _isInternalFocusNode = true; // 假设总是内部创建，因为原代码就是这样
  }

  @override
  void dispose() {
    // 仅释放内部创建的 FocusNode
    if (_isInternalFocusNode) {
      _focusNode.dispose();
    }
    // 仅释放内部创建的 Controller
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isSubmitting) return;
    _focusNode.unfocus(); // 保留 unfocus 逻辑
    widget.onSubmit(text);
    // 清空逻辑可以保留在这里，或者依赖 TextInputField 的 clearOnSubmit (如果使用它的提交)
    // _controller.clear(); // 如果需要提交后清空
  }

  void _handleCancel() {
    if (widget.isSubmitting) return;
    _controller.clear();
    _focusNode.unfocus();
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    // --- 登录和锁定逻辑保持不变 ---
    if (widget.lockedContent != null) {
      return Padding(padding: widget.padding, child: widget.lockedContent!);
    }
    if (!authProvider.isLoggedIn) {
      if (widget.loginPrompt != null) {
        return Padding(padding: widget.padding, child: widget.loginPrompt!);
      }
      if (widget.isReply) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: widget.padding,
        child: LoginPrompt(
          message: widget.isReply ? '登录后回复' : '登录后发表评论',
          buttonText: '登录',
          onLoginPressed: widget.onLoginRequired ??
              () => NavigationUtils.pushNamed(context, '/login'),
        ),
      );
    }

    final bool showCancelButton = widget.onCancel != null;

    // --- 使用 Row + TextInputField + Buttons 的布局 ---
    return Padding(
      padding: widget.padding,
      child: Row(
        // CrossAxisAlignment 对齐方式很重要
        crossAxisAlignment: CrossAxisAlignment.end, // 通常希望按钮和输入框底部对齐
        children: [
          // --- 使用 TextInputField ---
          Expanded(
            child: TextInputField(
              controller: _controller,
              focusNode: _focusNode, // 传递 FocusNode
              hintText: widget.hintText,
              maxLines: widget.maxLines,
              maxLength: widget.maxLength,
              enabled: !widget.isSubmitting, // 传递 enabled 状态
              contentPadding: widget.contentPadding,
              textStyle: widget.textStyle,
              hintStyle: widget.hintStyle,
              // !!! 关键：不显示 TextInputField 自带的按钮，并且不需要它处理 padding !!!
              showSubmitButton: false,
              padding: EdgeInsets.zero, // TextInputField 外层不需要 padding
              handleEnterKey: false, // 多行文本框通常不希望 Enter 提交
              // 可以传递 decoration 来进一步定制样式，如果需要的话
              // decoration: InputDecoration(...)
            ),
          ),
          SizedBox(width: widget.buttonSpacing),

          // --- 取消按钮 (逻辑不变) ---
          if (showCancelButton) ...[
            // 为了和 AppButton 高度尽量一致，可以包一层 SizedBox 或调整样式
            SizedBox(
              height: 44, // 尝试和 AppButton 高度一致
              child: TextButton(
                onPressed: widget.isSubmitting ? null : _handleCancel,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12), // 调整内边距
                  foregroundColor: Colors.grey.shade700,
                ),
                child: const Text('取消'),
              ),
            ),
            SizedBox(width: widget.buttonSpacing / 2),
          ],

          // --- 提交按钮 (逻辑不变) ---
          FunctionalButton(
            label: widget.submitButtonText,
            onPressed: _handleSubmit, // 按下时调用这里的 _handleSubmit
            isLoading: widget.isSubmitting,
          ),
        ],
      ),
    );
  }
}
