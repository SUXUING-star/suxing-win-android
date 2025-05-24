// lib/widgets/ui/inputs/text_input_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart'; // 使用 AppText
import '../menus/context_menu_bubble.dart'; // 使用 ContextMenuBubble

class TextInputField extends StatefulWidget {
  final InputStateService inputStateService;
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
  }) : assert(controller == null || slotName == null,
            'Cannot provide both a controller and a slotName.');

  @override
  State<TextInputField> createState() => _TextInputFieldState();
}

class _TextInputFieldState extends State<TextInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

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

    if (widget.onChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.onChanged != null) {
          widget.onChanged!(_controller.text);
        }
      });
    }
  }

  void _initializeController() {
    if (widget.slotName != null && widget.slotName!.isNotEmpty) {
      _controller = widget.inputStateService.getController(widget.slotName!);
      _usesStateService = true;
      _isInternalController = false;
    } else if (widget.controller != null) {
      _controller = widget.controller!;
      _usesStateService = false;
      _isInternalController = false;
    } else {
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
      _controller.removeListener(_handleControllerChanged);
      if (_isInternalController) {
        _controller.dispose();
      }
      _initializeController();
      _controller.addListener(_handleControllerChanged);

      if (widget.onChanged != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.onChanged != null) {
            widget.onChanged!(_controller.text);
          }
        });
      }
    }

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
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _hideContextMenu();
    }
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
    widget.onSubmitted?.call(text);

    if (widget.clearOnSubmit) {
      if (_usesStateService) {
        widget.inputStateService.clearText(widget.slotName!);
      } else {
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
                  minimumSize: const Size(60, 44),
                ),
                child: AppText(widget.submitButtonText), // 使用 AppText
              ),
          ]
        ],
      ),
    );
  }
}

class _ContextMenuLayoutDelegate extends SingleChildLayoutDelegate {
  final Offset anchor;
  final Size screenSize;
  final Offset textFieldOrigin;
  final Size textFieldSize;
  static const verticalMargin = 10.0;
  static const horizontalMargin = 10.0;

  _ContextMenuLayoutDelegate({
    required this.anchor,
    required this.screenSize,
    required this.textFieldOrigin,
    required this.textFieldSize,
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
