// lib/widgets/ui/inputs/text_input_field.dart

/// 该文件定义了 TextInputField 组件，一个可定制的文本输入框。
/// 该组件支持状态管理、上下文菜单、提交逻辑和多种输入配置。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:flutter/services.dart'; // 导入系统服务，如剪贴板
import 'package:suxingchahui/providers/inputs/input_state_provider.dart'; // 导入输入状态服务
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/menus/context_menu_bubble.dart'; // 导入上下文菜单气泡组件
import 'package:suxingchahui/widgets/ui/text/app_text.dart'; // 导入应用文本组件

/// `TextInputField` 类：一个可定制的文本输入框组件。
///
/// 该组件管理文本输入状态、焦点、提交行为，并提供自定义上下文菜单。
class TextInputField extends StatefulWidget {
  final InputStateService inputStateService; // 输入状态服务实例
  final String? slotName; // 槽名称，用于输入状态服务管理
  final TextEditingController? controller; // 文本编辑控制器
  final String? hintText; // 提示文本
  final int? maxLines; // 最大行数
  final bool enabled; // 是否启用
  final FocusNode? focusNode; // 焦点节点
  final ValueChanged<String>? onSubmitted; // 提交回调
  final String submitButtonText; // 提交按钮文本
  final bool isSubmitting; // 是否提交中
  final EdgeInsetsGeometry? contentPadding; // 内容内边距
  final EdgeInsetsGeometry? padding; // 外边距
  final InputDecoration? decoration; // 输入装饰
  final TextStyle? textStyle; // 文本样式
  final TextStyle? hintStyle; // 提示文本样式
  final double buttonSpacing; // 按钮间距
  final Widget? leadingWidget; // 前置组件
  final bool autofocus; // 是否自动获取焦点
  final bool showSubmitButton; // 是否显示提交按钮
  final bool clearOnSubmit; // 提交后是否清空文本
  final bool handleEnterKey; // 是否处理回车键
  final int? maxLength; // 最大长度
  final MaxLengthEnforcement? maxLengthEnforcement; // 最大长度限制策略
  final int? minLines; // 最小行数
  final TextInputAction? textInputAction; // 文本输入动作
  final TextInputType? keyboardType; // 键盘类型
  final ValueChanged<String>? onChanged; // 文本改变回调
  final bool obscureText; // 是否隐藏文本

  /// 构造函数。
  ///
  /// [inputStateService]：输入状态服务。
  /// [slotName]：槽名称。
  /// [controller]：文本控制器。
  /// [hintText]：提示文本。
  /// [maxLines]：最大行数。
  /// [enabled]：是否启用。
  /// [focusNode]：焦点节点。
  /// [onSubmitted]：提交回调。
  /// [submitButtonText]：提交按钮文本。
  /// [isSubmitting]：是否提交中。
  /// [contentPadding]：内容内边距。
  /// [padding]：外边距。
  /// [decoration]：输入装饰。
  /// [textStyle]：文本样式。
  /// [hintStyle]：提示文本样式。
  /// [buttonSpacing]：按钮间距。
  /// [leadingWidget]：前置组件。
  /// [autofocus]：是否自动获取焦点。
  /// [showSubmitButton]：是否显示提交按钮。
  /// [clearOnSubmit]：提交后是否清空。
  /// [handleEnterKey]：是否处理回车键。
  /// [maxLength]：最大长度。
  /// [maxLengthEnforcement]：最大长度限制策略。
  /// [minLines]：最小行数。
  /// [textInputAction]：文本输入动作。
  /// [keyboardType]：键盘类型。
  /// [onChanged]：文本改变回调。
  /// [obscureText]：是否隐藏文本。
  const TextInputField({
    super.key,
    required this.inputStateService,
    this.slotName,
    this.controller,
    this.hintText = '请输入内容...',
    this.maxLines = 1,
    this.enabled = true,
    this.focusNode,
    this.onSubmitted,
    this.submitButtonText = '发送',
    this.isSubmitting = false,
    this.contentPadding =
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    this.decoration,
    this.textStyle,
    this.hintStyle,
    this.buttonSpacing = 8.0,
    this.leadingWidget,
    this.autofocus = false,
    this.showSubmitButton = true,
    this.clearOnSubmit = true,
    this.handleEnterKey = true,
    this.maxLength,
    this.maxLengthEnforcement,
    this.minLines,
    this.textInputAction,
    this.keyboardType,
    this.onChanged,
    this.obscureText = false,
  }) : assert(controller == null || slotName == null, '不能同时提供控制器和槽名称。');

  @override
  State<TextInputField> createState() => _TextInputFieldState();
}

/// `_TextInputFieldState` 类：`TextInputField` 的状态管理。
///
/// 管理文本编辑控制器、焦点节点和自定义上下文菜单的显示。
class _TextInputFieldState extends State<TextInputField> {
  late TextEditingController _controller; // 文本编辑控制器
  late FocusNode _focusNode; // 焦点节点

  bool _usesStateService = false; // 是否使用输入状态服务标记
  bool _isInternalController = false; // 控制器是否为内部创建标记
  bool _isInternalFocusNode = false; // 焦点节点是否为内部创建标记

  OverlayEntry? _overlayEntry; // 上下文菜单的 OverlayEntry
  Offset? _menuAnchorPosition; // 菜单锚点位置
  final GlobalKey _textFieldKey = GlobalKey(); // 文本输入框的全局键

  @override
  void initState() {
    super.initState();
    _initializeController(); // 初始化控制器
    _initializeFocusNode(); // 初始化焦点节点
    _controller.addListener(_handleControllerChanged); // 添加控制器监听器
    _focusNode.addListener(_handleFocusChange); // 添加焦点监听器

    if (widget.onChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.onChanged != null) {
          widget.onChanged!(_controller.text); // 初始化时触发 onChanged 回调
        }
      });
    }
  }

  /// 初始化文本编辑控制器。
  ///
  /// 根据是否提供槽名称或外部控制器来决定创建内部控制器或使用外部控制器。
  void _initializeController() {
    if (widget.slotName != null && widget.slotName!.isNotEmpty) {
      _controller = widget.inputStateService
          .getController(widget.slotName!); // 从状态服务获取控制器
      _usesStateService = true;
      _isInternalController = false;
    } else if (widget.controller != null) {
      _controller = widget.controller!; // 使用外部控制器
      _usesStateService = false;
      _isInternalController = false;
    } else {
      _controller = TextEditingController(); // 创建内部控制器
      _usesStateService = false;
      _isInternalController = true;
    }
  }

  /// 初始化焦点节点。
  ///
  /// 根据是否提供外部焦点节点来决定创建内部焦点节点或使用外部焦点节点。
  void _initializeFocusNode() {
    _isInternalFocusNode = widget.focusNode == null; // 判断是否为内部焦点节点
    _focusNode = widget.focusNode ?? FocusNode(); // 初始化焦点节点
  }

  @override
  void didUpdateWidget(covariant TextInputField oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldSlotName = oldWidget.slotName;
    final newSlotName = widget.slotName;
    final oldExternalController = oldWidget.controller;
    final newExternalController = widget.controller;

    bool needsControllerUpdate = false; // 控制器是否需要更新标记

    bool oldHadSlot = oldSlotName != null && oldSlotName.isNotEmpty;
    bool newHasSlot = newSlotName != null && newSlotName.isNotEmpty;
    bool oldHadExternalController = oldExternalController != null;
    bool newHasExternalController = newExternalController != null;

    if (oldHadSlot != newHasSlot) {
      needsControllerUpdate = true;
    } else if (oldHadSlot && newHasSlot && oldSlotName != newSlotName) {
      needsControllerUpdate = true;
    } else if (!oldHadSlot && !newHasSlot) {
      if (oldHadExternalController != newHasExternalController) {
        needsControllerUpdate = true;
      } else if (oldHadExternalController &&
          newHasExternalController &&
          oldExternalController != newExternalController) {
        needsControllerUpdate = true;
      }
    }

    if (needsControllerUpdate) {
      // 如果控制器需要更新
      _controller.removeListener(_handleControllerChanged); // 移除旧监听器
      if (_isInternalController) {
        _controller.dispose(); // 销毁内部控制器
      }
      _initializeController(); // 重新初始化控制器
      _controller.addListener(_handleControllerChanged); // 添加新监听器

      if (widget.onChanged != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.onChanged != null) {
            widget.onChanged!(_controller.text); // 触发 onChanged 回调
          }
        });
      }
    }

    if (widget.focusNode != oldWidget.focusNode) {
      // 焦点节点发生变化
      _focusNode.removeListener(_handleFocusChange); // 移除旧监听器
      if (_isInternalFocusNode) {
        _focusNode.dispose(); // 销毁内部焦点节点
      }
      _initializeFocusNode(); // 重新初始化焦点节点
      _focusNode.addListener(_handleFocusChange); // 添加新监听器
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged); // 移除控制器监听器
    _focusNode.removeListener(_handleFocusChange); // 移除焦点监听器
    _hideContextMenu(); // 隐藏上下文菜单

    if (_isInternalController) {
      _controller.dispose(); // 销毁内部控制器
    }
    if (_isInternalFocusNode) {
      _focusNode.dispose(); // 销毁内部焦点节点
    }
    super.dispose();
  }

  /// 处理控制器文本改变事件。
  ///
  /// 调用组件的 `onChanged` 回调。
  void _handleControllerChanged() {
    widget.onChanged?.call(_controller.text);
  }

  /// 处理焦点变化事件。
  ///
  /// 焦点失去时隐藏上下文菜单。
  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _hideContextMenu(); // 焦点失去时隐藏上下文菜单
    }
    if (mounted) setState(() {}); // 更新 UI
  }

  /// 显示自定义上下文菜单。
  ///
  /// [context]：Build 上下文。
  /// [globalPosition]：菜单的全局位置。
  /// 根据当前文本选择和剪贴板内容生成菜单选项。
  Future<void> _showContextMenu(
      BuildContext context, Offset globalPosition) async {
    _hideContextMenu(); // 隐藏现有菜单
    _menuAnchorPosition = globalPosition; // 设置菜单锚点位置
    final clipboardData =
        await Clipboard.getData(Clipboard.kTextPlain); // 获取剪贴板数据
    if (!mounted) return; // 组件未挂载时返回

    final bool canPaste = clipboardData?.text?.isNotEmpty ?? false; // 判断是否可粘贴
    final TextSelection selection = _controller.selection; // 获取当前文本选择
    final bool canCopy = selection.isValid && !selection.isCollapsed; // 判断是否可复制
    final bool canCut = selection.isValid &&
        !selection.isCollapsed &&
        widget.enabled; // 判断是否可剪切
    final bool canSelectAll = _controller.text.isNotEmpty &&
        (selection.start != 0 ||
            selection.end != _controller.text.length); // 判断是否可全选

    final Map<String, VoidCallback?> actions = {}; // 菜单操作集合
    if (canCut) {
      actions['剪切'] = () {
        final selectedText = selection.textInside(_controller.text); // 获取选中文本
        Clipboard.setData(ClipboardData(text: selectedText)); // 复制到剪贴板
        final currentText = _controller.text; // 当前文本
        final currentSelection = _controller.selection; // 当前选择
        _controller.value = _controller.value.copyWith(
          text: currentSelection.textBefore(currentText) +
              currentSelection.textAfter(currentText), // 删除选中部分
          selection:
              TextSelection.collapsed(offset: currentSelection.start), // 恢复光标位置
        );
        _hideContextMenu(); // 隐藏菜单
      };
    }
    if (canCopy) {
      actions['复制'] = () {
        final selectedText = selection.textInside(_controller.text); // 获取选中文本
        Clipboard.setData(ClipboardData(text: selectedText)); // 复制到剪贴板
        _hideContextMenu(); // 隐藏菜单
      };
    }
    if (canPaste && widget.enabled) {
      actions['粘贴'] = () async {
        final data = await Clipboard.getData(Clipboard.kTextPlain); // 获取剪贴板数据
        if (data?.text != null) {
          final text = data!.text!; // 粘贴文本
          final currentText = _controller.text; // 当前文本
          final currentSelection = _controller.selection; // 当前选择
          _controller.value = _controller.value.copyWith(
            text: currentSelection.textBefore(currentText) +
                text +
                currentSelection.textAfter(currentText), // 插入文本
            selection: TextSelection.collapsed(
                offset: currentSelection.start + text.length), // 更新光标位置
          );
        }
        _hideContextMenu(); // 隐藏菜单
      };
    }
    if (canSelectAll) {
      actions['全选'] = () {
        _controller.selection = TextSelection(
            baseOffset: 0, extentOffset: _controller.text.length); // 全选文本
        _hideContextMenu(); // 隐藏菜单
      };
    }

    if (actions.isEmpty) return; // 无可用操作时返回
    final OverlayState overlayState =
        Overlay.of(this.context); // 获取 OverlayState
    final RenderBox? textFieldRenderBox = _textFieldKey.currentContext
        ?.findRenderObject() as RenderBox?; // 获取文本框渲染盒

    final Size screenSize = MediaQuery.of(this.context).size; // 获取屏幕尺寸
    Offset textFieldOrigin = Offset.zero; // 文本框起始位置
    Size textFieldSize = Size.zero; // 文本框尺寸
    if (textFieldRenderBox != null && textFieldRenderBox.hasSize) {
      textFieldOrigin =
          textFieldRenderBox.localToGlobal(Offset.zero); // 文本框全局位置
      textFieldSize = textFieldRenderBox.size; // 文本框尺寸
    }

    _overlayEntry = OverlayEntry(
      // 创建 OverlayEntry
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _hideContextMenu, // 点击外部隐藏菜单
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.transparent),
              ),
            ),
            CustomSingleChildLayout(
              delegate: _ContextMenuLayoutDelegate(
                // 菜单布局委托
                anchor: _menuAnchorPosition!,
                screenSize: screenSize,
                textFieldOrigin: textFieldOrigin,
                textFieldSize: textFieldSize,
              ),
              child: ContextMenuBubble(actions: actions), // 上下文菜单气泡组件
            ),
          ],
        );
      },
    );
    overlayState.insert(_overlayEntry!); // 插入到 Overlay 中显示
  }

  /// 隐藏自定义上下文菜单。
  void _hideContextMenu() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove(); // 移除 OverlayEntry
      _overlayEntry = null; // 清空引用
      _menuAnchorPosition = null; // 清空锚点位置
    }
  }

  /// 处理键盘事件。
  ///
  /// [node]：焦点节点。
  /// [event]：键盘事件。
  /// 处理单行输入框的回车键提交逻辑。
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      // 按键按下事件
      if (widget.handleEnterKey &&
          (widget.maxLines ?? 1) == 1 &&
          (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
        // 检查是否为回车键且为单行输入框
        if (!widget.isSubmitting && widget.onSubmitted != null) {
          // 非提交中且有提交回调
          _handleSubmit(); // 执行提交
          return KeyEventResult.handled; // 处理事件
        }
      }
    }
    return KeyEventResult.ignored; // 忽略事件
  }

  /// 处理提交操作。
  ///
  /// 调用组件的 `onSubmitted` 回调，并根据配置清空文本。
  void _handleSubmit() {
    if (!widget.enabled || widget.isSubmitting) return; // 按钮禁用或正在提交时返回

    final text = _controller.text.trim(); // 获取并修剪文本
    widget.onSubmitted?.call(text); // 调用提交回调

    if (widget.clearOnSubmit) {
      // 如果配置提交后清空
      if (_usesStateService) {
        widget.inputStateService.clearText(widget.slotName!); // 通过状态服务清空文本
      } else {
        _controller.clear(); // 清空控制器文本
      }
    }
    _focusNode.unfocus(); // 失去焦点
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // 获取当前主题
    final defaultDecoration = InputDecoration(
      hintText: widget.hintText, // 提示文本
      hintStyle:
          widget.hintStyle ?? TextStyle(color: Colors.grey.shade500), // 提示文本样式
      contentPadding: widget.contentPadding, // 内容内边距
      border: OutlineInputBorder(
        // 默认边框
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      enabledBorder: OutlineInputBorder(
        // 启用状态边框
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        // 焦点状态边框
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
      ),
      fillColor: _focusNode.hasFocus // 填充颜色
          ? (widget.enabled ? Colors.white : Colors.grey.shade200)
          : (widget.enabled ? Colors.grey.shade50 : Colors.grey.shade200),
      filled: true, // 是否填充
    );
    final effectiveDecoration =
        widget.decoration ?? defaultDecoration; // 最终输入装饰
    final bool textFieldEnabled =
        widget.enabled && !widget.isSubmitting; // 文本框是否启用

    return Padding(
      padding: widget.padding ?? EdgeInsets.zero, // 外边距
      child: Row(
        crossAxisAlignment: (widget.maxLines ?? 1) > 1
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.center, // 交叉轴对齐方式
        children: [
          if (widget.leadingWidget != null) ...[
            // 前置组件
            widget.leadingWidget!,
            SizedBox(width: widget.buttonSpacing),
          ],
          Expanded(
            // 展开文本输入框
            child: GestureDetector(
              onSecondaryTapDown: (details) {
                // 右键点击显示菜单
                if (textFieldEnabled) {
                  _showContextMenu(context, details.globalPosition);
                }
              },
              onLongPressStart: (details) {
                // 长按显示菜单
                if (textFieldEnabled) {
                  _showContextMenu(context, details.globalPosition);
                }
              },
              onTap: () {
                // 点击获取焦点
                _hideContextMenu(); // 隐藏菜单
                if (!_focusNode.hasFocus) {
                  FocusScope.of(context).requestFocus(_focusNode);
                }
              },
              behavior: HitTestBehavior.opaque, // 点击行为
              child: Focus(
                // 焦点管理
                focusNode: _focusNode, // 焦点节点
                onKeyEvent: _handleKeyEvent, // 键盘事件回调
                child: TextField(
                  key: _textFieldKey, // 全局键
                  controller: _controller, // 文本控制器
                  decoration: effectiveDecoration, // 输入装饰
                  style:
                      widget.textStyle ?? const TextStyle(fontSize: 14), // 文本样式
                  maxLines: widget.maxLines, // 最大行数
                  enabled: textFieldEnabled, // 是否启用
                  autofocus: widget.autofocus, // 是否自动获取焦点
                  contextMenuBuilder: (context, editableTextState) =>
                      const SizedBox.shrink(), // 禁用默认菜单
                  maxLength: widget.maxLength, // 最大长度
                  maxLengthEnforcement: widget.maxLengthEnforcement, // 最大长度限制策略
                  minLines: widget.minLines, // 最小行数
                  textInputAction: widget.textInputAction ?? // 文本输入动作
                      ((widget.maxLines ?? 1) == 1
                          ? (widget.onSubmitted != null
                              ? TextInputAction.send
                              : TextInputAction.done)
                          : TextInputAction.newline),
                  keyboardType: widget.keyboardType, // 键盘类型
                  obscureText: widget.obscureText, // 是否隐藏文本
                ),
              ),
            ),
          ),
          if (widget.showSubmitButton) ...[
            // 显示提交按钮
            SizedBox(width: widget.buttonSpacing), // 间距
            if (widget.isSubmitting) // 提交中显示进度指示器
              Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(8.0),
                child: const LoadingWidget(),
              )
            else // 否则显示提交按钮
              TextButton(
                onPressed: textFieldEnabled ? _handleSubmit : null, // 点击回调
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  minimumSize: const Size(60, 44),
                ),
                child: AppText(widget.submitButtonText), // 按钮文本
              ),
          ]
        ],
      ),
    );
  }
}

/// `_ContextMenuLayoutDelegate` 类：自定义上下文菜单的布局委托。
///
/// 该类计算上下文菜单在屏幕上的位置，确保其可见且不超出屏幕范围。
class _ContextMenuLayoutDelegate extends SingleChildLayoutDelegate {
  final Offset anchor; // 锚点位置
  final Size screenSize; // 屏幕尺寸
  final Offset textFieldOrigin; // 文本框起始位置
  final Size textFieldSize; // 文本框尺寸
  static const verticalMargin = 10.0; // 垂直外边距
  static const horizontalMargin = 10.0; // 水平外边距

  /// 构造函数。
  ///
  /// [anchor]：锚点。
  /// [screenSize]：屏幕尺寸。
  /// [textFieldOrigin]：文本框起始位置。
  /// [textFieldSize]：文本框尺寸。
  _ContextMenuLayoutDelegate({
    required this.anchor,
    required this.screenSize,
    required this.textFieldOrigin,
    required this.textFieldSize,
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      maxWidth: screenSize.width - (horizontalMargin * 2), // 最大宽度
      maxHeight: screenSize.height * 0.5, // 最大高度
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double top = anchor.dy + verticalMargin; // 初始顶部位置
    if (top + childSize.height > screenSize.height - horizontalMargin) {
      top = anchor.dy - childSize.height - verticalMargin; // 菜单向上调整
    }
    if (top < horizontalMargin) {
      top = textFieldOrigin.dy +
          textFieldSize.height +
          verticalMargin / 2; // 调整到文本框下方
      if (top + childSize.height > screenSize.height - horizontalMargin) {
        top = textFieldOrigin.dy -
            childSize.height -
            verticalMargin / 2; // 再次调整到文本框上方
        if (top < horizontalMargin) {
          top = horizontalMargin; // 最终调整到屏幕顶部边距
        }
      }
    }

    double left = anchor.dx - childSize.width / 2; // 初始左侧位置
    if (left < horizontalMargin) {
      left = horizontalMargin; // 调整到屏幕左侧边距
    }
    if (left + childSize.width > screenSize.width - horizontalMargin) {
      left = screenSize.width - childSize.width - horizontalMargin; // 调整到屏幕右侧边距
    }
    return Offset(left, top); // 返回最终位置
  }

  @override
  bool shouldRelayout(_ContextMenuLayoutDelegate oldDelegate) {
    return anchor != oldDelegate.anchor ||
        screenSize != oldDelegate.screenSize ||
        textFieldOrigin != oldDelegate.textFieldOrigin ||
        textFieldSize != oldDelegate.textFieldSize; // 检查是否需要重新布局
  }
}
