// lib/widgets/ui/inputs/form_text_input_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'text_input_field.dart'; // 导入我们修改后的 TextInputField

class FormTextInputField extends FormField<String> {
  final TextEditingController? controller;

  // 直接暴露 TextInputField 的常用属性
  final FocusNode? focusNode;
  final String? hintText;
  final int? maxLines;
  final bool enabled;
  // final Function(String)? onSubmitted; // FormField 应该用 onSaved
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? padding; // 这个是 TextInputField 的外边距
  final InputDecoration? decoration; // 允许完全覆盖
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
    required FormFieldValidator<String> validator, // FormField 必须的验证器
    super.onSaved, // FormField 的 onSaved 回调
    super.initialValue, // 可以设置初始值，但通常用 controller
    this.controller,
    this.decoration = const InputDecoration(),
    // --- TextInputField 的属性 ---
    this.focusNode,
    this.hintText,
    this.maxLines = 1,
    this.enabled = true,
    // this.onSubmitted, // 移除，用 onSaved
    this.contentPadding, // 可以传给 TextInputField
    this.padding = EdgeInsets.zero, // FormField 包装器通常不需要 TextInputField 的外边距
    this.textStyle,
    this.hintStyle,
    this.autofocus = false,
    this.maxLength,
    this.maxLengthEnforcement,
    this.minLines,
    this.textInputAction,
    this.keyboardType,
    this.obscureText = false, // 默认 false
    this.onChanged,

  }) : super(
    validator: validator,
    enabled: enabled,
    // --- builder 是 FormField 的核心 ---
    builder: (FormFieldState<String> field) {
      final _FormTextInputFieldState state = field as _FormTextInputFieldState;

      // --- 构建传递给 TextInputField 的 InputDecoration ---
      // 合并外部传入的 decoration 和错误状态
      final InputDecoration effectiveDecoration = (decoration ?? const InputDecoration())
          .applyDefaults(Theme.of(field.context).inputDecorationTheme) // 应用主题默认值
          .copyWith(
        hintText: hintText ?? decoration?.hintText, // 优先用直接传的 hintText
        errorText: field.errorText, // 显示验证错误
        // 可以根据 field.hasError 改变其他样式
        // enabledBorder: field.hasError ? ... : ...,
      );

      // --- 构建并返回 TextInputField ---
      return TextInputField(
        controller: state._effectiveController, // 使用内部管理的 controller
        focusNode: focusNode,
        hintText: hintText ,// 传递 hintText
        maxLines: maxLines,
        enabled: enabled, // 使用外部传入的 enabled
        contentPadding: contentPadding,
        padding: padding, // 传递 padding (通常是 zero)
        decoration: effectiveDecoration, // 传递处理过的 decoration
        textStyle: textStyle,
        hintStyle: hintStyle,
        autofocus: autofocus,
        maxLength: maxLength,
        maxLengthEnforcement: maxLengthEnforcement,
        minLines: minLines,
        textInputAction: textInputAction,
        keyboardType: keyboardType,     // <--- 传递 keyboardType
        obscureText: obscureText,       // <--- 传递 obscureText
        showSubmitButton: false, // FormField 内部不需要提交按钮
        handleEnterKey: false, // 表单字段通常不处理 Enter 提交
        // 当 TextInputField 内部值变化时，通知 FormField
        onChanged: (String value) {
          // 调用 FormField 的 didChange 来更新状态并可能触发验证
          field.didChange(value);
          // 同时调用外部传入的 onChanged 回调 (如果提供了)
          onChanged?.call(value);
        },
      );
    },
  );

  // 重写 createState 以返回自定义的 State
  @override
  FormFieldState<String> createState() => _FormTextInputFieldState();
}

// 自定义 FormFieldState 来处理 Controller
class _FormTextInputFieldState extends FormFieldState<String> {
  // 内部持有的 Controller
  TextEditingController? _controller;

  // 获取有效的 Controller (优先用外部传入的，否则用内部创建的)
  TextEditingController get _effectiveController => widget.controller ?? _controller!;

  // 获取外部传入的 FormTextInputField widget 配置
  @override
  FormTextInputField get widget => super.widget as FormTextInputField;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      // 如果外部没传 controller，内部创建一个
      _controller = TextEditingController(text: widget.initialValue);
    } else {
      // 如果外部传了 controller，添加监听器，当外部 controller 改变时同步 FormField 的值
      widget.controller!.addListener(_handleControllerChanged);
    }
    // 设置 FormField 的初始值 (从 controller 或 initialValue)
    setValue(_effectiveController.text);
  }

  @override
  void didUpdateWidget(FormTextInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当 widget 更新时，检查 controller 是否发生变化
    if (widget.controller != oldWidget.controller) {
      // 移除旧 controller 的监听器 (如果存在且是外部的)
      oldWidget.controller?.removeListener(_handleControllerChanged);
      // 为新 controller 添加监听器 (如果是外部的)
      widget.controller?.addListener(_handleControllerChanged);

      // 如果之前是内部 controller，现在是外部 controller
      if (oldWidget.controller == null && widget.controller != null) {
        // 不再需要内部 controller，但不要 dispose 它，因为外部可能还在用
        _controller = null; // 只需置空引用
      }
      // 如果之前是外部 controller，现在是内部 controller
      if (oldWidget.controller != null && widget.controller == null) {
        // 需要创建内部 controller
        _controller = TextEditingController.fromValue(oldWidget.controller!.value);
      }
      // 如果 controller 从一个外部实例换成另一个外部实例
      if (oldWidget.controller != null && widget.controller != null) {
        setValue(widget.controller!.text); // 更新 FormField 的值
      }
      // 如果 controller 从内部变为 null (理论上不该发生，除非外部设为 null)
      // (此情况已包含在上面)
    }
    // 如果 controller 类型没变，但外部 controller 的文本变了，_handleControllerChanged 会处理
  }


  @override
  void dispose() {
    // 移除监听器 (如果是外部 controller)
    widget.controller?.removeListener(_handleControllerChanged);
    // 如果是内部创建的 controller，需要 dispose
    // 注意：在 didUpdateWidget 中，如果从内部变为外部，_controller 会被设为 null
    // 所以这里的 dispose 只会作用于真正由这个 State 创建并持有的 Controller
    _controller?.dispose();
    super.dispose();
  }

  @override
  void reset() {
    super.reset();
    // 重置时，将 controller 的文本设为 FormField 的初始值
    setState(() {
      _effectiveController.text = widget.initialValue ?? '';
    });
  }

  // 监听外部 controller 的变化，并更新 FormField 的值
  void _handleControllerChanged() {
    if (_effectiveController.text != value) {
      // 当外部 controller 的文本变化时，调用 didChange 更新 FormField 的内部值
      // 这也会触发可能的重新验证 (如果 autovalidateMode 开启)
      didChange(_effectiveController.text);
    }
  }

  // didChange 由 builder 中的 onChanged 或者 _handleControllerChanged 调用
  @override
  void didChange(String? value) {
    super.didChange(value);
    // 如果 FormField 的值改变了 (可能是用户输入或外部 controller)，
    // 并且 *不是* 外部 controller 引起的 (避免循环)，
    // 就更新 controller 的文本。
    // (这个检查在 _handleControllerChanged 中做了，这里理论上不需要，
    // 因为 didChange 最终会更新 FormField 的 `value` 属性)
    // if (widget.controller != null && widget.controller!.text != value) {
    //   widget.controller!.text = value ?? '';
    // }
  }
}