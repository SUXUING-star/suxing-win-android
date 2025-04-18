// lib/widgets/ui/inputs/comment_input_field.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// 导入 *新的* AppButton
import '../buttons/app_button.dart';
// 假设其他必要的 import 存在
import '../../../providers/auth/auth_provider.dart';
import '../../../utils/navigation/navigation_utils.dart';
import '../buttons/login_prompt.dart';


class CommentInputField extends StatefulWidget {
  // --- 保留必要的参数 ---
  final Function(String) onSubmit;
  final TextEditingController? controller;
  final String hintText;
  final int maxLines;
  final String submitButtonText; // 按钮文字需要从外部传入
  final bool isSubmitting; // 加载状态需要从外部传入
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
    Key? key,
    this.controller,
    required this.onSubmit,
    this.hintText = '发表评论...',
    this.submitButtonText = '发表', // 保留这个
    this.isSubmitting = false,     // 保留这个
    this.isReply = false,
    this.maxLines = 3,
    this.padding = const EdgeInsets.all(16.0),
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.textStyle,
    this.hintStyle,
    this.buttonSpacing = 8.0,
    this.onLoginRequired,
    this.loginPrompt,
    this.lockedContent,
    this.onCancel,
  }) : super(key: key);

  @override
  State<CommentInputField> createState() => _CommentInputFieldState();
}

class _CommentInputFieldState extends State<CommentInputField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isInternalController = false;

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
  }


  @override
  void dispose() {
    _focusNode.dispose();
    // Only dispose the controller if it was created internally
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isSubmitting) return;
    _focusNode.unfocus();
    widget.onSubmit(text);
  }

  void _handleCancel() {
    if (widget.isSubmitting) return;
    _controller.clear(); // Clear the text on cancel
    _focusNode.unfocus();
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
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
          onLoginPressed: widget.onLoginRequired ?? () => NavigationUtils.pushNamed(context, '/login'),
        ),
      );
    }


    final bool showCancelButton = widget.onCancel != null;

    return Padding(
      padding: widget.padding,
      child: Row(
        crossAxisAlignment: widget.maxLines > 1 ? CrossAxisAlignment.end : CrossAxisAlignment.center,
        children: [
          // --- 输入框 (调整圆角匹配按钮) ---
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: widget.hintStyle ?? TextStyle(color: Colors.grey.shade500),
                border: OutlineInputBorder( // 统一边框和圆角
                    borderRadius: BorderRadius.circular(10.0), // 使用与按钮一致的圆角
                    borderSide: BorderSide(color: Colors.grey.shade300)
                ),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: theme.primaryColor)
                ),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: Colors.grey.shade300)
                ),
                contentPadding: widget.contentPadding,
                isDense: true,
              ),
              style: widget.textStyle ?? theme.textTheme.bodyLarge,
              maxLines: widget.maxLines,
              minLines: 1,
              enabled: !widget.isSubmitting,
              textInputAction: widget.maxLines > 1 ? TextInputAction.newline : TextInputAction.send,
              onSubmitted: widget.maxLines == 1 ? (_) => _handleSubmit() : null,
            ),
          ),
          SizedBox(width: widget.buttonSpacing),

          // --- 取消按钮 (保持 TextButton，样式微调) ---
          if (showCancelButton) ...[
            TextButton(
              onPressed: widget.isSubmitting ? null : _handleCancel,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                minimumSize: const Size(0, 44), // 高度与 AppButton 对齐
                foregroundColor: Colors.grey.shade700,
              ),
              child: const Text('取消'),
            ),
            SizedBox(width: widget.buttonSpacing / 2),
          ],

          // --- 提交按钮 (使用 AppButton，只传必要参数) ---
          AppButton(
            text: widget.submitButtonText,   // ✅ 按钮文字
            onPressed: _handleSubmit,       // ✅ 点击事件
            isLoading: widget.isSubmitting, // ✅ 加载状态
          ),
        ],
      ),
    );
  }
}