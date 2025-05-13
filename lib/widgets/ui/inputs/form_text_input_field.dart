// lib/widgets/ui/inputs/form_text_input_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'text_input_field.dart'; // 导入 TextInputField

class FormTextInputField extends FormField<String> {
  // 接收 slotName
  final String? slotName;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final int? maxLines;
  final bool enabled;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? padding;
  final InputDecoration? decoration;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final bool autofocus;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final int? minLines;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool obscureText;

  FormTextInputField({
    super.key,
    required FormFieldValidator<String> validator,
    super.onSaved,
    super.initialValue, // 只有在没有 controller 和 slotName 时才可能用到
    this.controller,
    this.slotName, // 接收 slotName
    this.decoration = const InputDecoration(),
    this.focusNode,
    this.hintText,
    this.maxLines = 1,
    this.enabled = true,
    this.contentPadding,
    this.padding = EdgeInsets.zero,
    this.textStyle,
    this.hintStyle,
    this.autofocus = false,
    this.maxLength,
    this.maxLengthEnforcement,
    this.minLines,
    this.textInputAction,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,

  }) : assert(controller == null || slotName == null,
  'Cannot provide both a controller and a slotName.'),
        super(
        validator: validator,
        enabled: enabled,
        // --- builder ---
        builder: (FormFieldState<String> field) {
          final _FormTextInputFieldState state = field as _FormTextInputFieldState;

          final InputDecoration effectiveDecoration = (decoration ?? const InputDecoration())
              .applyDefaults(Theme.of(field.context).inputDecorationTheme)
              .copyWith(
            hintText: hintText ?? decoration?.hintText,
            errorText: field.errorText,
          );

          // --- 核心逻辑简化 ---
          // 如果提供了 slotName，直接把它传给 TextInputField，controller 传 null
          // 如果没提供 slotName，才使用 FormFieldState 管理的 controller (_effectiveController)
          final bool useSlotName = slotName != null && slotName.isNotEmpty;

          return TextInputField(
            slotName: useSlotName ? slotName : null,
            controller: useSlotName ? null : state._effectiveController, // **关键**
            // 传递其他属性...
            focusNode: focusNode,
            hintText: hintText,
            maxLines: maxLines,
            enabled: enabled,
            contentPadding: contentPadding,
            padding: padding,
            decoration: effectiveDecoration,
            textStyle: textStyle,
            hintStyle: hintStyle,
            autofocus: autofocus,
            maxLength: maxLength,
            maxLengthEnforcement: maxLengthEnforcement,
            minLines: minLines,
            textInputAction: textInputAction,
            keyboardType: keyboardType,
            obscureText: obscureText,
            showSubmitButton: false,
            handleEnterKey: false,
            // --- TextInputField 的 onChanged 直接驱动 FormField ---
            onChanged: (String value) {
              field.didChange(value); // 更新 FormField 的值
              onChanged?.call(value); // 调用外部的 onChanged
            },
            // clearOnSubmit: false, // FormField 场景下不需要这个
          );
        },
      );

  @override
  FormFieldState<String> createState() => _FormTextInputFieldState();
}

// --- _FormTextInputFieldState 简化 ---
// 这个 State 只在 *没有* slotName 的时候才管理 Controller
class _FormTextInputFieldState extends FormFieldState<String> {

  // 内部 Controller，仅当 widget.controller 为 null 且 widget.slotName 为 null 时创建
  TextEditingController? _controller;

  // 获取有效的 Controller (仅当 widget.slotName 为 null 时才有意义)
  TextEditingController? get _effectiveController => widget.controller ?? _controller;

  @override
  FormTextInputField get widget => super.widget as FormTextInputField;

  @override
  void initState() {
    super.initState();
    // --- 只处理 Controller 情况 ---
    if (widget.slotName == null) { // **关键判断**
      if (widget.controller == null) {
        // 外部没提供 controller，内部创建
        _controller = TextEditingController(text: widget.initialValue);
      } else {
        // 外部提供了 controller，添加监听
        widget.controller!.addListener(_handleControllerChanged);
      }
      // 用 controller 或 initialValue 初始化 FormField 的值
      setValue(_effectiveController?.text ?? widget.initialValue ?? '');
    } else {
      setValue(widget.initialValue ?? ''); // 或者直接设为 ''
      // *** 更好的做法可能是在 builder 中读取 TextInputField 的初始值，但这比较复杂 ***
      // *** 依赖 TextInputField 初始化后的第一次 onChanged 更新 FormField 是更简单的模式 ***
    }
  }

  @override
  void didUpdateWidget(FormTextInputField oldWidget) {
    super.didUpdateWidget(oldWidget); // FormFieldState.didUpdateWidget 会处理 initialValue 的变化

    final bool wasUsingSlotName = oldWidget.slotName != null && oldWidget.slotName!.isNotEmpty;
    final bool isUsingSlotName = widget.slotName != null && widget.slotName!.isNotEmpty;

    // --- 情况1: 一直是 Controller 模式 ---
    if (!isUsingSlotName && !wasUsingSlotName) {
      if (widget.controller != oldWidget.controller) {
        // 清理旧的 controller 监听
        oldWidget.controller?.removeListener(_handleControllerChanged);
        _controller?.removeListener(_handleControllerChanged); // 如果是内部 controller

        // 处理 Controller 切换 (外部 <-> 内部)
        if (oldWidget.controller != null && widget.controller == null) { // 从外部 controller 切换到内部 controller
          _controller?.dispose(); // 清理可能存在的旧内部 controller
          // 新的内部 controller 应该继承旧外部 controller 的值
          _controller = TextEditingController.fromValue(oldWidget.controller!.value);
          _controller!.addListener(_handleControllerChanged);
        } else if (oldWidget.controller == null && widget.controller != null) { // 从内部 controller 切换到外部 controller
          _controller?.dispose(); // 清理内部 controller
          _controller = null;
          widget.controller!.addListener(_handleControllerChanged); // 监听新的外部 controller
        } else if (widget.controller != null) { // 外部 controller 实例发生变化
          widget.controller!.addListener(_handleControllerChanged);
        }
        // 外部 controller 为 null, 且之前也是 null (意味着一直使用内部 controller)
        // _controller 实例不变，不需要做什么特殊处理，除非 initialValue 驱动更新

        // 同步 FormFieldState 的值
        setValue(_effectiveController?.text ?? widget.initialValue ?? '');
      }
      // 如果只是 initialValue 变了，并且我们用的是内部 controller, super.didUpdateWidget 会更新 FormFieldState.value
      // 我们可能需要同步 _controller.text
      else if (widget.controller == null && oldWidget.controller == null && widget.initialValue != oldWidget.initialValue) {
        if (_controller != null && _controller!.text != (this.value ?? '')) { // this.value 是 FormFieldState.value
          _controller!.text = this.value ?? '';
        }
      }
    }
    // --- 情况2: slotName 模式发生切换或 slotName 本身改变 ---
    else if (isUsingSlotName != wasUsingSlotName || (isUsingSlotName && widget.slotName != oldWidget.slotName)) {
      if (isUsingSlotName && !wasUsingSlotName) { // 从 Controller 模式切换到 slotName 模式
        oldWidget.controller?.removeListener(_handleControllerChanged);
        _controller?.dispose();
        _controller = null;
        // FormField 的值会在 TextInputField 初始化并触发 onChanged (didChange) 后更新
        // 将 FormFieldState.value 设为 initialValue 作为临时值，很快会被 TextInputField 更新
        setValue(widget.initialValue ?? '');
      } else if (!isUsingSlotName && wasUsingSlotName) { // 从 slotName 模式切换到 Controller 模式
        // 保留从 slotName 模式带来的当前值
        final String previousSlotValue = this.value ?? widget.initialValue ?? '';
        if (widget.controller == null) { // 外部没提供 controller，内部创建
          _controller?.dispose(); // 确保清理
          _controller = TextEditingController(text: previousSlotValue);
          _controller!.addListener(_handleControllerChanged);
        } else { // 外部提供了 controller
          _controller?.dispose();
          _controller = null;
          widget.controller!.addListener(_handleControllerChanged);
        }
        // 同步 FormFieldState 的值
        setValue(_effectiveController?.text ?? previousSlotValue);
      } else if (isUsingSlotName && wasUsingSlotName && widget.slotName != oldWidget.slotName) {
        // slotName 改变了，但仍然是 slotName 模式
        // TextInputField 会在其 didUpdateWidget 中处理新 slotName 并更新
        // FormField 的值同样会通过 TextInputField 的 onChanged (didChange) 更新
        setValue(widget.initialValue ?? ''); // 设为临时值
      }
    }
  }
  @override
  void dispose() {
    // --- 只处理 Controller 情况 ---
    widget.controller?.removeListener(_handleControllerChanged);
    _controller?.dispose(); // 只 dispose 内部创建的
    super.dispose();
  }

  @override
  void reset() {
    super.reset(); // 重置 FormField 内部状态 (value 会变成 initialValue)
    final resetValue = widget.initialValue ?? '';
    // setValue(resetValue); // super.reset() 已经做了类似的事情
    if (widget.slotName == null) { // Controller 模式
      // 更新 controller 的文本并触发UI更新
      // setState(() { // FormFieldState.reset() 内部会调用 setState
      _effectiveController?.text = resetValue;
      // });
    }
    // 如果使用 slotName，TextInputField 会从 InputStateService 获取值（如果service也被重置的话）
    // 或者依赖其自身的逻辑。这里不需要直接操作 InputStateService。
  }


  // 监听外部 controller 的变化 (仅当 widget.slotName == null 时)
  void _handleControllerChanged() {
    if (mounted && widget.slotName == null) { // 仅在 Controller 模式下且未提供 slotName 时
      if (_effectiveController?.text != value) { // value 是 FormFieldState.value
        didChange(_effectiveController!.text);
      }
    }
  }

  // didChange 由 builder 中的 onChanged 调用
  @override
  void didChange(String? value) {
    // 只更新 FormField 的内部值
    super.didChange(value);
  }
}