// lib/widgets/ui/inputs/comment_input_field.dart

/// 该文件定义了 CommentInputField 组件，一个用于评论输入的文本框。
/// 该组件支持用户登录状态管理、文本输入和提交评论功能。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/models/user/user.dart'; // 导入用户模型
import 'package:suxingchahui/providers/inputs/input_state_provider.dart'; // 导入输入状态服务
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart'; // 导入功能按钮
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导入导航工具类
import 'package:suxingchahui/widgets/ui/buttons/login_prompt_button.dart'; // 导入登录提示按钮
import 'text_input_field.dart'; // 导入 TextInputField

/// `CommentInputField` 类：一个用于评论输入的文本字段。
///
/// 该组件根据用户登录状态显示不同的界面，并提供文本输入、提交和取消功能。
class CommentInputField extends StatefulWidget {
  final String? slotName; // 用于 InputStateService 的槽名称
  final User? currentUser; // 当前登录的用户
  final InputStateService inputStateService; // 输入状态服务实例
  final TextEditingController? controller; // 文本编辑控制器
  final Function(String) onSubmit; // 提交评论的回调
  final String hintText; // 提示文本
  final int maxLines; // 最大行数
  final int? maxLength; // 最大长度
  final String submitButtonText; // 提交按钮文本
  final bool isSubmitting; // 是否正在提交评论
  final bool isReply; // 是否为回复模式
  final EdgeInsetsGeometry padding; // 外部填充
  final EdgeInsetsGeometry contentPadding; // 内容内边距
  final TextStyle? textStyle; // 文本样式
  final TextStyle? hintStyle; // 提示文本样式
  final double buttonSpacing; // 按钮间距
  final VoidCallback? onLoginRequired; // 需要登录时的回调
  final Widget? loginPrompt; // 自定义登录提示组件
  final Widget? lockedContent; // 锁定状态显示组件
  final VoidCallback? onCancel; // 取消按钮回调

  /// 构造函数。
  ///
  /// [slotName]：槽名称。
  /// [controller]：控制器。
  /// [onSubmit]：提交回调。
  /// [currentUser]：当前用户。
  /// [inputStateService]：输入状态服务。
  /// [hintText]：提示文本。
  /// [submitButtonText]：提交按钮文本。
  /// [isSubmitting]：是否提交中。
  /// [isReply]：是否为回复。
  /// [maxLines]：最大行数。
  /// [maxLength]：最大长度。
  /// [padding]：外部填充。
  /// [contentPadding]：内容填充。
  /// [textStyle]：文本样式。
  /// [hintStyle]：提示文本样式。
  /// [buttonSpacing]：按钮间距。
  /// [onLoginRequired]：需要登录回调。
  /// [loginPrompt]：登录提示组件。
  /// [lockedContent]：锁定内容组件。
  /// [onCancel]：取消回调。
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
  }) : assert(controller == null || slotName == null, '不能同时提供控制器和槽名称。');

  @override
  State<CommentInputField> createState() => _CommentInputFieldState();
}

/// `_CommentInputFieldState` 类：`CommentInputField` 的状态管理。
///
/// 管理焦点、内部控制器和用户状态变化。
class _CommentInputFieldState extends State<CommentInputField> {
  late FocusNode _focusNode; // 焦点节点
  bool _isInternalFocusNode = false; // 焦点节点是否为内部创建标记
  TextEditingController? _internalController; // 内部文本编辑控制器
  User? _currentUser; // 当前用户

  @override
  void initState() {
    super.initState();
    _initializeFocusNode(); // 初始化焦点节点
    _initializeInternalControllerIfNeeded(); // 初始化内部控制器
  }

  @override
  void didChangeDependencies() {
    _currentUser = widget.currentUser; // 更新当前用户
    super.didChangeDependencies();
  }

  /// 初始化焦点节点。
  void _initializeFocusNode() {
    _focusNode = FocusNode(); // 创建焦点节点
    _isInternalFocusNode = true; // 标记为内部焦点节点
  }

  /// 按需初始化内部文本编辑控制器。
  ///
  /// 当没有提供槽名称和外部控制器时，创建内部控制器。
  void _initializeInternalControllerIfNeeded() {
    if (widget.slotName == null && widget.controller == null) {
      _internalController = TextEditingController(); // 创建内部控制器
    } else {
      _internalController = null; // 不使用内部控制器
    }
  }

  @override
  void didUpdateWidget(covariant CommentInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool needsInternalControllerUpdate =
        (widget.slotName == null && widget.controller == null) !=
            (oldWidget.slotName == null &&
                oldWidget.controller == null); // 判断是否需要更新内部控制器

    if (needsInternalControllerUpdate) {
      // 需要更新内部控制器
      if (_internalController != null) {
        _internalController!.dispose(); // 销毁旧内部控制器
        _internalController = null;
      }
      _initializeInternalControllerIfNeeded(); // 初始化新内部控制器
    }
    if (oldWidget.currentUser != widget.currentUser ||
        _currentUser != widget.currentUser) {
      // 用户状态发生变化
      setState(() {
        _currentUser = widget.currentUser; // 更新当前用户
      });
    }
  }

  @override
  void dispose() {
    if (_isInternalFocusNode) {
      _focusNode.dispose(); // 销毁内部焦点节点
    }
    _internalController?.dispose(); // 销毁内部控制器
    super.dispose();
  }

  /// 处理文本提交。
  ///
  /// [text]：要提交的文本。
  /// 文本为空或正在提交时不做任何操作。
  void _handleSubmit(String text) {
    final trimmedText = text.trim(); // 修剪文本
    if (trimmedText.isEmpty || widget.isSubmitting) return; // 文本为空或正在提交时返回
    _focusNode.unfocus(); // 失去焦点
    widget.onSubmit(trimmedText); // 调用提交回调
  }

  /// 处理取消操作。
  ///
  /// 清空输入框内容并失去焦点，然后调用取消回调。
  void _handleCancel() {
    if (widget.isSubmitting) return; // 正在提交时返回

    if (widget.slotName != null && widget.slotName!.isNotEmpty) {
      widget.inputStateService.clearText(widget.slotName!); // 通过状态服务清空文本
    } else if (widget.controller != null) {
      widget.controller!.clear(); // 清空外部控制器文本
    } else {
      _internalController?.clear(); // 清空内部控制器文本
    }
    _focusNode.unfocus(); // 失去焦点
    widget.onCancel?.call(); // 调用取消回调
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lockedContent != null) {
      // 如果存在锁定内容组件
      return Padding(
          padding: widget.padding, child: widget.lockedContent!); // 显示锁定内容
    }

    if (widget.currentUser == null) {
      // 用户未登录
      if (widget.loginPrompt != null) {
        // 存在自定义登录提示组件
        return Padding(
            padding: widget.padding, child: widget.loginPrompt!); // 显示自定义登录提示
      }
      if (widget.isReply) {
        return const SizedBox.shrink(); // 回复模式下未登录时不显示
      }
      return Padding(
        padding: widget.padding,
        child: LoginPromptButton(
          message: widget.isReply ? '登录后回复' : '登录后发表评论', // 提示消息
          buttonText: '登录', // 按钮文本
          onLoginPressed: widget.onLoginRequired ??
              () => NavigationUtils.navigateToLogin(context), // 登录回调或导航到登录页面
        ),
      );
    }

    final bool showCancelButton = widget.onCancel != null; // 是否显示取消按钮
    final TextEditingController? effectiveController =
        widget.controller ?? _internalController; // 有效的文本编辑控制器

    return Padding(
      padding: widget.padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end, // 交叉轴对齐方式
        children: [
          Expanded(
            // 文本输入框
            child: TextInputField(
              inputStateService: widget.inputStateService,
              slotName: widget.slotName,
              controller: effectiveController,
              focusNode: _focusNode,
              hintText: widget.hintText,
              maxLines: widget.maxLines,
              maxLength: widget.maxLength,
              enabled: !widget.isSubmitting, // 根据提交状态禁用
              contentPadding: widget.contentPadding,
              textStyle: widget.textStyle,
              hintStyle: widget.hintStyle,
              showSubmitButton: false, // 禁用内部提交按钮
              padding: EdgeInsets.zero,
              handleEnterKey: (widget.maxLines) == 1, // 单行允许回车键提交
              onSubmitted: _handleSubmit, // 提交回调
              clearOnSubmit: false, // 清空由外部控制
              keyboardType: (widget.maxLines) == 1
                  ? TextInputType.text
                  : TextInputType.multiline, // 键盘类型
              textInputAction: (widget.maxLines) == 1
                  ? TextInputAction.send
                  : TextInputAction.newline, // 文本输入动作
            ),
          ),
          SizedBox(width: widget.buttonSpacing), // 间距

          if (showCancelButton) ...[
            // 显示取消按钮
            SizedBox(
              height: 44,
              child: TextButton(
                onPressed:
                    widget.isSubmitting ? null : _handleCancel, // 禁用或取消回调
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  foregroundColor: Colors.grey.shade700,
                ),
                child: const Text('取消'), // 按钮文本
              ),
            ),
            SizedBox(width: widget.buttonSpacing / 2), // 间距
          ],

          FunctionalButton(
            label: widget.submitButtonText, // 按钮文本
            onPressed: () {
              String currentText = '';

              if (widget.slotName != null && widget.slotName!.isNotEmpty) {
                currentText = widget.inputStateService
                    .getText(widget.slotName!); // 从状态服务获取文本
              } else if (effectiveController != null) {
                currentText = effectiveController.text; // 从控制器获取文本
              }
              _handleSubmit(currentText); // 提交文本
            },
            isLoading: widget.isSubmitting, // 设置加载状态
          ),
        ],
      ),
    );
  }
}
