// lib/widgets/ui/inputs/comment_input_field.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/buttons/login_prompt.dart';
import 'text_input_field.dart';

class CommentInputField extends StatefulWidget {
  final String? slotName;
  final User? currentUser;
  final InputStateService inputStateService;
  final TextEditingController? controller;
  final Function(String) onSubmit;
  final String hintText;
  final int maxLines;
  final int? maxLength;
  final String submitButtonText;
  final bool isSubmitting;
  final bool isReply;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry contentPadding;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final double buttonSpacing;
  final VoidCallback? onLoginRequired;
  final Widget? loginPrompt; // 允许自定义登录提示 Widget
  final Widget? lockedContent; // 允许传入锁定状态 Widget
  final VoidCallback? onCancel;

  const CommentInputField({
    super.key,
    this.slotName,
    this.controller,
    required this.onSubmit,
    required this.currentUser,
    required this.inputStateService,
    this.hintText = '发表评论...',
    this.submitButtonText = '发表',
    this.isSubmitting = false,
    this.isReply = false,
    this.maxLines = 3,
    this.maxLength,
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
  }) : assert(controller == null || slotName == null,
            'Cannot provide both a controller and a slotName.');

  @override
  State<CommentInputField> createState() => _CommentInputFieldState();
}

class _CommentInputFieldState extends State<CommentInputField> {
  late FocusNode _focusNode;
  bool _isInternalFocusNode = false;
  TextEditingController? _internalController; // 内部控制器（如果需要）
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeFocusNode();
    _initializeInternalControllerIfNeeded();
  }

  @override
  void didChangeDependencies() {
    _currentUser = widget.currentUser;
    super.didChangeDependencies();
  }


  void _initializeFocusNode() {
    // 假设 CommentInputField 创建并向下传递 FocusNode
    _focusNode = FocusNode();
    _isInternalFocusNode = true;
  }

  void _initializeInternalControllerIfNeeded() {
    if (widget.slotName == null && widget.controller == null) {
      _internalController = TextEditingController();
    } else {
      _internalController = null;
    }
  }

  @override
  void didUpdateWidget(covariant CommentInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool needsInternalControllerUpdate =
        (widget.slotName == null && widget.controller == null) !=
            (oldWidget.slotName == null && oldWidget.controller == null);

    if (needsInternalControllerUpdate) {
      if (_internalController != null) {
        _internalController!.dispose();
        _internalController = null;
      }
      _initializeInternalControllerIfNeeded();
    }
    if (oldWidget.currentUser != widget.currentUser ||
        _currentUser != widget.currentUser) {
      setState(() {
        _currentUser = widget.currentUser;
      });
    }
  }

  @override
  void dispose() {
    if (_isInternalFocusNode) {
      _focusNode.dispose();
    }
    _internalController?.dispose();
    super.dispose();
  }

  void _handleSubmit(String text) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || widget.isSubmitting) return;
    _focusNode.unfocus();
    widget.onSubmit(trimmedText);
    // 清空由外部逻辑处理（成功回调后）
  }

  void _handleCancel() {
    if (widget.isSubmitting) return;

    if (widget.slotName != null && widget.slotName!.isNotEmpty) {
      widget.inputStateService.clearText(widget.slotName!);
    } else if (widget.controller != null) {
      widget.controller!.clear();
    } else {
      _internalController?.clear();
    }
    _focusNode.unfocus();
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lockedContent != null) {
      return Padding(padding: widget.padding, child: widget.lockedContent!);
    }

    if (widget.currentUser == null) {
      if (widget.loginPrompt != null) {
        return Padding(padding: widget.padding, child: widget.loginPrompt!);
      }
      if (widget.isReply) {
        return const SizedBox.shrink();
      }
      // 使用你的 LoginPrompt 组件
      return Padding(
        padding: widget.padding,
        child: LoginPrompt(
          message: widget.isReply ? '登录后回复' : '登录后发表评论',
          buttonText: '登录',
          onLoginPressed: widget.onLoginRequired ??
              () => NavigationUtils.pushNamed(
                  context, AppRoutes.login), // 直接使用 NavigationUtils
        ),
      );
    }

    final bool showCancelButton = widget.onCancel != null;
    final TextEditingController? effectiveController =
        widget.controller ?? _internalController;

    return Padding(
      padding: widget.padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextInputField(
              inputStateService: widget.inputStateService,
              slotName: widget.slotName,
              controller: effectiveController,
              focusNode: _focusNode,
              hintText: widget.hintText,
              maxLines: widget.maxLines,
              maxLength: widget.maxLength,
              enabled: !widget.isSubmitting,
              contentPadding: widget.contentPadding,
              textStyle: widget.textStyle,
              hintStyle: widget.hintStyle,
              showSubmitButton: false, // 禁用内部提交按钮
              padding: EdgeInsets.zero,
              handleEnterKey: (widget.maxLines) == 1, // 单行允许 Enter
              onSubmitted: _handleSubmit, // 内部 Enter 提交也走这个逻辑
              clearOnSubmit: false, // 清空由外部控制
              keyboardType: (widget.maxLines) == 1
                  ? TextInputType.text
                  : TextInputType.multiline,
              textInputAction: (widget.maxLines) == 1
                  ? TextInputAction.send
                  : TextInputAction.newline,
            ),
          ),
          SizedBox(width: widget.buttonSpacing),

          if (showCancelButton) ...[
            // 取消按钮通常用 TextButton
            SizedBox(
              height: 44, // 尝试匹配高度
              child: TextButton(
                onPressed: widget.isSubmitting ? null : _handleCancel,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  foregroundColor: Colors.grey.shade700,
                ),
                child: const Text('取消'),
              ),
            ),
            SizedBox(width: widget.buttonSpacing / 2),
          ],

          // 使用你的 FunctionalButton
          FunctionalButton(
            label: widget.submitButtonText,
            onPressed: () {
              String currentText = '';

              if (widget.slotName != null && widget.slotName!.isNotEmpty) {
                currentText =
                    widget.inputStateService.getText(widget.slotName!);
              } else if (effectiveController != null) {
                currentText = effectiveController.text;
              }
              _handleSubmit(currentText);
            },
            isLoading: widget.isSubmitting,
          ),
        ],
      ),
    );
  }
}
