// lib/widgets/ui/inputs/text_input_field.dart
import 'package:flutter/material.dart';

class TextInputField extends StatefulWidget {
  final String hintText;
  final int maxLines;
  final bool enabled;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final Function(String)? onSubmitted;
  final String submitButtonText;
  final bool isSubmitting;
  final EdgeInsetsGeometry contentPadding;
  final EdgeInsetsGeometry padding;
  final InputDecoration? decoration;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final double buttonSpacing;
  final Widget? leadingWidget;
  final bool autofocus;
  final bool showSubmitButton;
  final bool clearOnSubmit;

  const TextInputField({
    Key? key,
    this.hintText = '请输入内容...',
    this.maxLines = 1,
    this.enabled = true,
    this.controller,
    this.focusNode,
    this.onSubmitted,
    this.submitButtonText = '提交',
    this.isSubmitting = false,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.padding = const EdgeInsets.all(16.0),
    this.decoration,
    this.textStyle,
    this.hintStyle,
    this.buttonSpacing = 8.0,
    this.leadingWidget,
    this.autofocus = false,
    this.showSubmitButton = true,
    this.clearOnSubmit = true,
  }) : super(key: key);

  @override
  State<TextInputField> createState() => _TextInputFieldState();
}

class _TextInputFieldState extends State<TextInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    // 只释放内部创建的控制器和焦点
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (widget.onSubmitted != null) {
      widget.onSubmitted!(text);
    }

    if (widget.clearOnSubmit) {
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.leadingWidget != null) ...[
            widget.leadingWidget!,
            SizedBox(width: widget.buttonSpacing),
          ],
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: widget.decoration ?? InputDecoration(
                hintText: widget.hintText,
                contentPadding: widget.contentPadding,
                border: const OutlineInputBorder(),
                hintStyle: widget.hintStyle,
              ),
              style: widget.textStyle,
              maxLines: widget.maxLines,
              enabled: widget.enabled && !widget.isSubmitting,
              autofocus: widget.autofocus,
              onSubmitted: widget.maxLines == 1 ? (_) => _handleSubmit() : null,
              textInputAction: widget.maxLines == 1 ? TextInputAction.send : TextInputAction.newline,
            ),
          ),
          if (widget.showSubmitButton) ...[
            SizedBox(width: widget.buttonSpacing),
            widget.isSubmitting
                ? Container(
              margin: EdgeInsets.only(top: widget.contentPadding.vertical + 2),
              width: 24,
              height: 24,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
                : TextButton(
              onPressed: widget.enabled ? _handleSubmit : null,
              child: Text(widget.submitButtonText),
            ),
          ]
        ],
      ),
    );
  }
}