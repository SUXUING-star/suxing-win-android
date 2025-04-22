// lib/widgets/ui/inputs/text_input_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../text/app_text.dart';     // 导入 AppText
import '../text/app_text_type.dart'; // 导入 AppTextType
import '../menus/context_menu_bubble.dart'; // <--- 导入新的气泡菜单组件

class TextInputField extends StatefulWidget {
  final String? hintText;
  final int? maxLines;
  final bool enabled;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final Function(String)? onSubmitted;
  final String submitButtonText;
  final bool isSubmitting;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? padding;
  final InputDecoration? decoration;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final double buttonSpacing;
  final Widget? leadingWidget;
  final bool autofocus;
  final bool showSubmitButton;
  final bool clearOnSubmit;
  final bool handleEnterKey;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final int? minLines;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool obscureText;

  const TextInputField({
    super.key,
    this.hintText = '请输入内容...',
    this.maxLines = 1,
    this.enabled = true,
    this.controller,
    this.focusNode,
    this.onSubmitted,
    this.submitButtonText = '发送',
    this.isSubmitting = false,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
    this.obscureText = false, // 默认不隐藏
  });

  @override
  State<TextInputField> createState() => _TextInputFieldState();
}

class _TextInputFieldState extends State<TextInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isInternalController = false;
  bool _isInternalFocusNode = false;

  OverlayEntry? _overlayEntry;
  Offset? _menuAnchorPosition;
  // +++ 用于获取 TextField 尺寸和位置 +++
  final GlobalKey _textFieldKey = GlobalKey();


  @override
  void initState() {
    super.initState();
    _isInternalController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();

    _isInternalFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();

    _controller.addListener(_handleControllerChanged);
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _focusNode.removeListener(_handleFocusChange);
    _hideContextMenu(); // Ensure menu is removed on dispose
    if (_isInternalController) {
      _controller.dispose();
    }
    if (_isInternalFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleControllerChanged() {
    widget.onChanged?.call(_controller.text);
    // You might want to hide the context menu if the text changes drastically
    // _hideContextMenu();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _hideContextMenu();
    }
  }

  // --- 显示自定义 Overlay 菜单 ---
  Future<void> _showContextMenu(BuildContext context, Offset globalPosition) async {
    _hideContextMenu();

    // 记录原始锚点
    _menuAnchorPosition = globalPosition;

    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final bool canPaste = clipboardData?.text?.isNotEmpty ?? false;
    final TextSelection selection = _controller.selection;
    final bool canCopy = selection.isValid && !selection.isCollapsed;
    final bool canCut = selection.isValid && !selection.isCollapsed && widget.enabled;
    final bool canSelectAll = _controller.text.isNotEmpty && (selection.start != 0 || selection.end != _controller.text.length);

    final Map<String, VoidCallback?> actions = {};
    if (canCut) {
      actions['剪切'] = () {
        final selectedText = selection.textInside(_controller.text);
        Clipboard.setData(ClipboardData(text: selectedText));
        _controller.text = selection.textBefore(_controller.text) + selection.textAfter(_controller.text);
        _controller.selection = TextSelection.collapsed(offset: selection.start);
        _hideContextMenu();
      };
    }
    if (canCopy) {
      actions['复制'] = () {
        final selectedText = selection.textInside(_controller.text);
        Clipboard.setData(ClipboardData(text: selectedText));
        _hideContextMenu();
      };
    }
    if (canPaste && widget.enabled) {
      actions['粘贴'] = () async {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        if (data?.text != null) {
          final text = data!.text!;
          _controller.text = selection.textBefore(_controller.text) + text + selection.textAfter(_controller.text);
          _controller.selection = TextSelection.collapsed(offset: selection.start + text.length);
        }
        _hideContextMenu();
      };
    }
    if (canSelectAll) {
      actions['全选'] = () {
        _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
        _hideContextMenu(); // 关闭菜单，但保持全选状态
      };
    }

    if (actions.isEmpty) return;

    final OverlayState overlayState = Overlay.of(context);
    final RenderBox? textFieldRenderBox = _textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    final Size screenSize = MediaQuery.of(context).size;

    // 获取 TextField 在屏幕上的位置和大小（如果可用）
    Offset textFieldOrigin = Offset.zero;
    Size textFieldSize = Size.zero;
    if (textFieldRenderBox != null && textFieldRenderBox.hasSize) {
      textFieldOrigin = textFieldRenderBox.localToGlobal(Offset.zero);
      textFieldSize = textFieldRenderBox.size;
    } else {
      // Fallback if renderbox not ready or available
      print("Warning: TextField RenderBox not available for precise positioning.");
    }


    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _hideContextMenu,
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.transparent),
              ),
            ),
            // 使用 Positioned + CustomSingleChildLayout 来精确定位和约束
            CustomSingleChildLayout(
              // delegate 负责计算位置和大小
              delegate: _ContextMenuLayoutDelegate(
                anchor: _menuAnchorPosition!, // 传入点击位置
                screenSize: screenSize,
                textFieldOrigin: textFieldOrigin, // 传入输入框位置
                textFieldSize: textFieldSize,     // 传入输入框大小
              ),
              // 要布局的子 Widget 就是我们的气泡菜单
              child: ContextMenuBubble(actions: actions), // <--- 使用封装的组件
            ),
          ],
        );
      },
    );

    overlayState.insert(_overlayEntry!);
    print("--- Custom Overlay Context Menu Shown ---");
  }

  // --- 隐藏自定义 Overlay 菜单 ---
  void _hideContextMenu() {
    if (_overlayEntry != null) {
      print("--- Hiding Custom Overlay Context Menu ---");
      _overlayEntry!.remove();
      _overlayEntry = null;
      _menuAnchorPosition = null;
    }
  }

  // --- 键盘和提交逻辑 (无省略号) ---
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (widget.handleEnterKey &&
          (widget.maxLines ?? 1) == 1 && // 确保是单行
          (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
        if (!widget.isSubmitting) {
          if ((widget.textInputAction == TextInputAction.send ||
              widget.textInputAction == null) &&
              widget.onSubmitted != null) {
            _handleSubmit();
            return KeyEventResult.handled;
          }
        }
      }
    }
    return KeyEventResult.ignored;
  }

  void _handleSubmit() {
    if (!widget.enabled || widget.isSubmitting) {
      return;
    }
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmitted?.call(text);
    if (widget.clearOnSubmit) {
      _controller.clear();
    }
  }


  @override
  Widget build(BuildContext context) {
    final defaultDecoration = InputDecoration(
      hintText: widget.hintText,
      hintStyle: widget.hintStyle ?? TextStyle(color: Colors.grey.shade500),
      contentPadding: widget.contentPadding,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
      ),
      filled: true,
      fillColor: widget.enabled ? Colors.white : Colors.grey.shade100,
    );
    final effectiveDecoration = widget.decoration ?? defaultDecoration;

    return Padding(
      padding: widget.padding ?? EdgeInsets.zero, // 处理可能的 null
      child: Row(
        crossAxisAlignment: (widget.maxLines ?? 1) > 1 ? CrossAxisAlignment.end : CrossAxisAlignment.center,
        children: [
          if (widget.leadingWidget != null) ...[
            widget.leadingWidget!,
            SizedBox(width: widget.buttonSpacing),
          ],
          Expanded(
            child: GestureDetector(
              onSecondaryTapDown: (details) {
                // 如果 TextField 可用，则显示菜单
                if(widget.enabled) {
                  _showContextMenu(context, details.globalPosition);
                }
              },
              onLongPressStart: (details) {
                if(widget.enabled) {
                  _showContextMenu(context, details.globalPosition);
                }
              },
              onTap: () {
                // 点击输入框时隐藏菜单，并确保请求焦点
                _hideContextMenu();
                if (!_focusNode.hasFocus) {
                  FocusScope.of(context).requestFocus(_focusNode);
                }
              },
              behavior: HitTestBehavior.opaque, // 确保 GestureDetector 响应事件
              // 使用 Focus 包裹 TextField
              child: Focus(
                focusNode: _focusNode,
                onKeyEvent: _handleKeyEvent,
                child: TextField(
                  key: _textFieldKey, // <--- 给 TextField 添加 GlobalKey
                  controller: _controller,
                  decoration: effectiveDecoration,
                  style: widget.textStyle ?? const TextStyle(fontSize: 14),
                  maxLines: widget.maxLines,
                  enabled: widget.enabled && !widget.isSubmitting,
                  autofocus: widget.autofocus,
                  contextMenuBuilder: (context, editableTextState) => const SizedBox.shrink(), // 禁用默认菜单
                  maxLength: widget.maxLength,
                  maxLengthEnforcement: widget.maxLengthEnforcement,
                  minLines: widget.minLines,
                  textInputAction: widget.textInputAction ?? ((widget.maxLines ?? 1) == 1 ? (widget.onSubmitted != null ? TextInputAction.send : TextInputAction.done) : TextInputAction.newline),
                  keyboardType: widget.keyboardType, // <--- 传递 keyboardType
                  obscureText: widget.obscureText,  // <--- 传递 obscureText
                ),
              ),
            ),
          ),
          if (widget.showSubmitButton) ...[
            SizedBox(width: widget.buttonSpacing),
            if (widget.isSubmitting)
              Container(
                width: 36, height: 36,
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                ),
              )
            else
              TextButton(
                onPressed: widget.enabled ? _handleSubmit : null,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                child: Text(widget.submitButtonText),
              ),
          ]
        ],
      ),
    );
  }
}

// --- 用于精确定位和约束菜单大小的 Layout Delegate ---
class _ContextMenuLayoutDelegate extends SingleChildLayoutDelegate {
  final Offset anchor; // 点击/长按的全局位置
  final Size screenSize; // 屏幕尺寸
  final Offset textFieldOrigin; // TextField 左上角全局位置
  final Size textFieldSize; // TextField 尺寸
  final double verticalMargin; // 菜单与锚点/输入框的垂直间距
  final double horizontalMargin; // 屏幕边缘的最小间距

  _ContextMenuLayoutDelegate({
    required this.anchor,
    required this.screenSize,
    required this.textFieldOrigin,
    required this.textFieldSize,
    this.verticalMargin = 10.0,
    this.horizontalMargin = 10.0,
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // 约束菜单的最大宽度和高度，防止它比屏幕还大
    return BoxConstraints(
      // 最大宽度为屏幕宽度减去两边边距
      maxWidth: screenSize.width - (horizontalMargin * 2),
      // 最大高度可以设一个值，比如屏幕高度的一半
      maxHeight: screenSize.height * 0.5,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // size 是父级（这里是 Overlay，即全屏）的大小
    // childSize 是菜单（ContextMenuBubble）实际测量后的大小

    // 1. 理想的垂直位置：优先放在锚点下方
    double top = anchor.dy + verticalMargin;
    // 2. 检查下方是否越界
    if (top + childSize.height > screenSize.height - horizontalMargin) {
      // 越界，尝试放到锚点上方
      top = anchor.dy - childSize.height - verticalMargin;
    }
    // 3. 检查上方是否越界（如果移到上方后）
    if (top < horizontalMargin) {
      // 如果上方也放不下，尝试贴近输入框顶部或底部
      // 优先贴近输入框底部
      top = textFieldOrigin.dy + textFieldSize.height + verticalMargin / 2;
      // 如果贴近底部还是会超出屏幕，则尝试贴近输入框顶部
      if (top + childSize.height > screenSize.height - horizontalMargin) {
        top = textFieldOrigin.dy - childSize.height - verticalMargin / 2;
        // 如果贴近顶部还是小于边距，就只能顶着边距放了
        if (top < horizontalMargin) {
          top = horizontalMargin;
        }
      }
    }

    // 4. 理想的水平位置：让菜单中心尽量对齐锚点
    double left = anchor.dx - childSize.width / 2;
    // 5. 检查左侧是否越界
    if (left < horizontalMargin) {
      left = horizontalMargin;
    }
    // 6. 检查右侧是否越界
    if (left + childSize.width > screenSize.width - horizontalMargin) {
      left = screenSize.width - childSize.width - horizontalMargin;
    }

    return Offset(left, top);
  }

  @override
  bool shouldRelayout(_ContextMenuLayoutDelegate oldDelegate) {
    // 当锚点或屏幕尺寸变化时需要重新布局
    return anchor != oldDelegate.anchor || screenSize != oldDelegate.screenSize;
  }
}