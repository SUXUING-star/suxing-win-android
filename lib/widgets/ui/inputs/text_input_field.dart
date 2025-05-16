// lib/widgets/ui/inputs/text_input_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart'; // 使用 AppText
import '../menus/context_menu_bubble.dart'; // 使用 ContextMenuBubble

class TextInputField extends StatefulWidget {
  final String? slotName; // 槽名称，用于状态管理
  final TextEditingController? controller;
  final String? hintText;
  final int? maxLines;
  final bool enabled;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
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
  }) : assert(controller == null || slotName == null,
            'Cannot provide both a controller and a slotName.');

  @override
  State<TextInputField> createState() => _TextInputFieldState();
}

class _TextInputFieldState extends State<TextInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  InputStateService? _inputStateService;
  bool _usesStateService = false;
  bool _isInternalController = false;
  bool _isInternalFocusNode = false;

  OverlayEntry? _overlayEntry;
  Offset? _menuAnchorPosition;
  final GlobalKey _textFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeController();
    _initializeFocusNode();
    _controller.addListener(_handleControllerChanged);
    _focusNode.addListener(_handleFocusChange);

    // 如果这个 TextInputField 被 FormTextInputField 使用 (widget.onChanged 就是 field.didChange),
    // 并且 controller 初始化后有文本 (可能来自 InputStateService 或外部 controller)，
    // 需要在下一帧通知 FormFieldState 更新其内部 value。
    if (widget.onChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 再次检查 widget 是否仍然 mounted 且 onChanged 仍然有效
        if (mounted && widget.onChanged != null) {
          // FormFieldState.didChange() 内部会检查值是否真的改变了
          widget.onChanged!(_controller.text);
        }
      });
    }
  }

  void _initializeController() {
    // 优先使用 slotName
    if (widget.slotName != null && widget.slotName!.isNotEmpty) {
      try {
        // 尝试获取 Service
        _inputStateService =
            Provider.of<InputStateService>(context, listen: false);
        _controller = _inputStateService!.getController(widget.slotName!);
        _usesStateService = true;
        _isInternalController = false;
      } catch (e) {
        // 如果 Service 没找到，降级为内部 Controller，并打印警告
        _controller = TextEditingController();
        _usesStateService = false;
        _isInternalController = true;
      }
    }
    // 其次使用外部 controller
    else if (widget.controller != null) {
      _controller = widget.controller!;
      _usesStateService = false;
      _isInternalController = false;
    }
    // 最后创建内部 controller
    else {
      _controller = TextEditingController();
      _usesStateService = false;
      _isInternalController = true;
    }
  }

  void _initializeFocusNode() {
    _isInternalFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void didUpdateWidget(covariant TextInputField oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldSlotName = oldWidget.slotName;
    final newSlotName = widget.slotName;
    final oldExternalController = oldWidget.controller;
    final newExternalController = widget.controller;

    bool needsControllerUpdate = false;

    // 判断 Controller 来源是否改变
    bool oldWasStateService = oldSlotName != null && oldSlotName.isNotEmpty;
    bool newIsStateService = newSlotName != null && newSlotName.isNotEmpty;
    bool oldWasExternal = oldExternalController != null;
    bool newIsExternal = newExternalController != null;
    // 之前是否是因 Service 找不到而 fallback 的内部 Controller
    bool oldWasFallbackInternal =
        _isInternalController && oldWasStateService && !_usesStateService;
    // 当前是否是因 Service 找不到而 fallback 的内部 Controller
    // (需要重新检查 service 是否存在，因为可能在父级动态添加了 Provider)
    bool newIsFallbackInternal = false;
    if (newIsStateService) {
      try {
        Provider.of<InputStateService>(context, listen: false);
      } catch (e) {
        newIsFallbackInternal = true; // Service 应该存在但找不到，说明是 fallback
      }
    }

    if (oldWasStateService != newIsStateService || // Service 状态切换
            (oldWasStateService &&
                newIsStateService &&
                oldSlotName != newSlotName) || // SlotName 改变
            (!oldWasStateService &&
                !newIsStateService &&
                oldWasExternal != newIsExternal) || // 内部/外部切换
            (!oldWasStateService &&
                !newIsStateService &&
                oldWasExternal &&
                newIsExternal &&
                oldExternalController !=
                    newExternalController) || // 外部 Controller 实例改变
            (oldWasFallbackInternal != newIsFallbackInternal) // Fallback 状态切换
        ) {
      needsControllerUpdate = true;
    }

    if (needsControllerUpdate) {
      // 移除旧监听器
      _controller.removeListener(_handleControllerChanged);
      // 仅释放真正由本组件创建的内部控制器
      if (_isInternalController &&
          oldWidget.controller == null &&
          (oldWidget.slotName == null || oldWasFallbackInternal)) {
        _controller.dispose();
      }
      // 重新初始化
      _initializeController();
      // 添加新监听器
      _controller.addListener(_handleControllerChanged);
    }

    // FocusNode 更新
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_handleFocusChange);
      if (_isInternalFocusNode) {
        _focusNode.dispose();
      }
      _initializeFocusNode();
      _focusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _focusNode.removeListener(_handleFocusChange);
    _hideContextMenu();
    // 仅释放真正由本组件创建的内部控制器（非外部传入，非Service管理，非Service fallback）
    if (_isInternalController &&
        widget.controller == null &&
        widget.slotName == null) {
      _controller.dispose();
    } else if (_isInternalController &&
        widget.slotName != null &&
        !_usesStateService) {
      // 如果是 Service fallback 产生的内部 Controller，也需要释放
      _controller.dispose();
    }
    if (_isInternalFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleControllerChanged() {
    // 只调用外部回调
    widget.onChanged?.call(_controller.text);
    // --- 不再调用 setState({}) ---
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _hideContextMenu();
    }
    // 焦点变化可能影响外观，需要重绘
    if (mounted) setState(() {});
  }

  Future<void> _showContextMenu(
      BuildContext context, Offset globalPosition) async {
    _hideContextMenu();
    _menuAnchorPosition = globalPosition;
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;

    final bool canPaste = clipboardData?.text?.isNotEmpty ?? false;
    final TextSelection selection = _controller.selection;
    final bool canCopy = selection.isValid && !selection.isCollapsed;
    final bool canCut =
        selection.isValid && !selection.isCollapsed && widget.enabled;
    final bool canSelectAll = _controller.text.isNotEmpty &&
        (selection.start != 0 || selection.end != _controller.text.length);

    final Map<String, VoidCallback?> actions = {};
    if (canCut) {
      actions['剪切'] = () {
        final selectedText = selection.textInside(_controller.text);
        Clipboard.setData(ClipboardData(text: selectedText));
        final currentText = _controller.text;
        final currentSelection = _controller.selection;
        _controller.value = _controller.value.copyWith(
          text: currentSelection.textBefore(currentText) +
              currentSelection.textAfter(currentText),
          selection: TextSelection.collapsed(offset: currentSelection.start),
        );
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
          final currentText = _controller.text;
          final currentSelection = _controller.selection;
          _controller.value = _controller.value.copyWith(
            text: currentSelection.textBefore(currentText) +
                text +
                currentSelection.textAfter(currentText),
            selection: TextSelection.collapsed(
                offset: currentSelection.start + text.length),
          );
        }
        _hideContextMenu();
      };
    }
    if (canSelectAll) {
      actions['全选'] = () {
        _controller.selection =
            TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
        _hideContextMenu();
      };
    }

    if (actions.isEmpty) return;
    final OverlayState overlayState = Overlay.of(this.context);
    final RenderBox? textFieldRenderBox =
        _textFieldKey.currentContext?.findRenderObject() as RenderBox?;

    final Size screenSize = MediaQuery.of(this.context).size;
    Offset textFieldOrigin = Offset.zero;
    Size textFieldSize = Size.zero;
    if (textFieldRenderBox != null && textFieldRenderBox.hasSize) {
      textFieldOrigin = textFieldRenderBox.localToGlobal(Offset.zero);
      textFieldSize = textFieldRenderBox.size;
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
            CustomSingleChildLayout(
              delegate: _ContextMenuLayoutDelegate(
                anchor: _menuAnchorPosition!,
                screenSize: screenSize,
                textFieldOrigin: textFieldOrigin,
                textFieldSize: textFieldSize,
              ),
              child:
                  ContextMenuBubble(actions: actions), // 使用 ContextMenuBubble
            ),
          ],
        );
      },
    );
    overlayState.insert(_overlayEntry!);
  }

  void _hideContextMenu() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _menuAnchorPosition = null;
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (widget.handleEnterKey &&
          (widget.maxLines ?? 1) == 1 &&
          (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
        if (!widget.isSubmitting && widget.onSubmitted != null) {
          _handleSubmit();
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  void _handleSubmit() {
    if (!widget.enabled || widget.isSubmitting) return;

    final text = _controller.text.trim();
    if (text.isEmpty && widget.onSubmitted == null) return; // 如果没回调且为空，不处理

    widget.onSubmitted?.call(text); // 可能提交空字符串，由外部处理

    if (widget.clearOnSubmit) {
      // 如果使用 Service 且 Service 存在
      if (_usesStateService &&
          _inputStateService != null &&
          widget.slotName != null &&
          widget.slotName!.isNotEmpty) {
        _inputStateService!.clearText(widget.slotName!);
      }
      // 否则，直接清空当前 Controller (外部或内部)
      else {
        _controller.clear();
      }
    }
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
      ),
      fillColor: _focusNode.hasFocus
          ? (widget.enabled ? Colors.white : Colors.grey.shade200)
          : (widget.enabled ? Colors.grey.shade50 : Colors.grey.shade200),
      filled: true,
    );
    final effectiveDecoration = widget.decoration ?? defaultDecoration;
    final bool textFieldEnabled = widget.enabled && !widget.isSubmitting;

    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: (widget.maxLines ?? 1) > 1
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.center,
        children: [
          if (widget.leadingWidget != null) ...[
            widget.leadingWidget!,
            SizedBox(width: widget.buttonSpacing),
          ],
          Expanded(
            child: GestureDetector(
              onSecondaryTapDown: (details) {
                if (textFieldEnabled) {
                  _showContextMenu(context, details.globalPosition);
                }
              },
              onLongPressStart: (details) {
                if (textFieldEnabled) {
                  _showContextMenu(context, details.globalPosition);
                }
              },
              onTap: () {
                _hideContextMenu();
                if (!_focusNode.hasFocus) {
                  FocusScope.of(context).requestFocus(_focusNode);
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Focus(
                focusNode: _focusNode,
                onKeyEvent: _handleKeyEvent,
                child: TextField(
                  key: _textFieldKey,
                  controller: _controller,
                  decoration: effectiveDecoration,
                  style: widget.textStyle ?? const TextStyle(fontSize: 14),
                  maxLines: widget.maxLines,
                  enabled: textFieldEnabled,
                  autofocus: widget.autofocus,
                  contextMenuBuilder: (context, editableTextState) =>
                      const SizedBox.shrink(), // 禁用默认菜单
                  maxLength: widget.maxLength,
                  maxLengthEnforcement: widget.maxLengthEnforcement,
                  minLines: widget.minLines,
                  textInputAction: widget.textInputAction ??
                      ((widget.maxLines ?? 1) == 1
                          ? (widget.onSubmitted != null
                              ? TextInputAction.send
                              : TextInputAction.done)
                          : TextInputAction.newline),
                  keyboardType: widget.keyboardType,
                  obscureText: widget.obscureText,
                ),
              ),
            ),
          ),
          if (widget.showSubmitButton) ...[
            SizedBox(width: widget.buttonSpacing),
            if (widget.isSubmitting)
              Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                ),
              )
            else
              TextButton(
                onPressed: textFieldEnabled ? _handleSubmit : null,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  minimumSize: Size(60, 44),
                ),
                child: AppText(widget.submitButtonText), // 使用 AppText
              ),
          ]
        ],
      ),
    );
  }
}

// --- ContextMenuLayoutDelegate (无修改) ---
class _ContextMenuLayoutDelegate extends SingleChildLayoutDelegate {
  final Offset anchor;
  final Size screenSize;
  final Offset textFieldOrigin;
  final Size textFieldSize;
  final double verticalMargin;
  final double horizontalMargin;

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
    return BoxConstraints(
      maxWidth: screenSize.width - (horizontalMargin * 2),
      maxHeight: screenSize.height * 0.5,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double top = anchor.dy + verticalMargin;
    if (top + childSize.height > screenSize.height - horizontalMargin) {
      top = anchor.dy - childSize.height - verticalMargin;
    }
    if (top < horizontalMargin) {
      top = textFieldOrigin.dy + textFieldSize.height + verticalMargin / 2;
      if (top + childSize.height > screenSize.height - horizontalMargin) {
        top = textFieldOrigin.dy - childSize.height - verticalMargin / 2;
        if (top < horizontalMargin) {
          top = horizontalMargin;
        }
      }
    }

    double left = anchor.dx - childSize.width / 2;
    if (left < horizontalMargin) {
      left = horizontalMargin;
    }
    if (left + childSize.width > screenSize.width - horizontalMargin) {
      left = screenSize.width - childSize.width - horizontalMargin;
    }
    return Offset(left, top);
  }

  @override
  bool shouldRelayout(_ContextMenuLayoutDelegate oldDelegate) {
    return anchor != oldDelegate.anchor ||
        screenSize != oldDelegate.screenSize ||
        textFieldOrigin != oldDelegate.textFieldOrigin ||
        textFieldSize != oldDelegate.textFieldSize;
  }
}
