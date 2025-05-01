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
    // 其他属性...
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
      // --- 如果有 slotName，这个 State 什么都不用做 ---
      // TextInputField 会自己去 Service 加载状态
      // 但 FormField 仍然需要一个初始值，否则可能是 null。
      // 这里我们不能直接访问 Service，所以暂时设为空字符串或 initialValue。
      // TextInputField 初始化后会通过 onChanged 更新 FormField 的值。
      setValue(widget.initialValue ?? ''); // 或者直接设为 ''
      // *** 更好的做法可能是在 builder 中读取 TextInputField 的初始值，但这比较复杂 ***
      // *** 依赖 TextInputField 初始化后的第一次 onChanged 更新 FormField 是更简单的模式 ***
    }
  }

  @override
  void didUpdateWidget(FormTextInputField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // --- 只处理 Controller 的变化 ---
    if (widget.slotName == null && oldWidget.slotName == null) { // **关键判断**
      if (widget.controller != oldWidget.controller) {
        // 移除旧监听
        oldWidget.controller?.removeListener(_handleControllerChanged);
        // 添加新监听
        widget.controller?.addListener(_handleControllerChanged);

        // 处理 Controller 类型切换
        if (oldWidget.controller != null && widget.controller == null) {
          // 从外部变为内部
          _controller?.dispose(); // Dispose 之前的内部 controller (如果有)
          _controller = TextEditingController.fromValue(oldWidget.controller!.value);
        } else if (oldWidget.controller == null && widget.controller != null) {
          // 从内部变为外部
          _controller?.dispose(); // Dispose 内部 controller
          _controller = null;
        }
        // 更新 FormField 的值以匹配新的 Controller
        setValue(_effectiveController?.text ?? widget.initialValue ?? '');
      }
      // 如果 controller 实例没变，但外部修改了 text，_handleControllerChanged 会处理
    } else if (widget.slotName != oldWidget.slotName) {
      // --- 如果 slotName 状态发生变化 (从无到有，或从有到无) ---
      // 需要清理或设置 Controller 监听
      if (widget.slotName != null && oldWidget.slotName == null) {
        // 从 Controller 模式切换到 slotName 模式
        widget.controller?.removeListener(_handleControllerChanged); // 移除外部监听
        _controller?.dispose(); // Dispose 内部 Controller
        _controller = null;
        // FormField 的值会在 TextInputField 初始化并触发 onChanged 后更新
        setValue(widget.initialValue ?? ''); // 重置初始值
      } else if (widget.slotName == null && oldWidget.slotName != null) {
        // 从 slotName 模式切换到 Controller 模式
        initState(); // 重新执行 Controller 初始化逻辑可能最简单
        // setValue(...) 已经在 initState 里面了
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
    super.reset(); // 重置 FormField 内部状态
    final resetValue = widget.initialValue ?? '';
    setValue(resetValue); // 更新 FormField 的值
    // --- 只处理 Controller 情况 ---
    if (widget.slotName == null) { // **关键判断**
      setState(() { // 需要 setState 触发 UI 更新
        _effectiveController?.text = resetValue;
      });
    }
    // 如果使用 slotName，不需要（也不应该）在这里操作 Service
  }

  // 监听外部 controller 的变化 (仅当 widget.slotName == null 时)
  void _handleControllerChanged() {
    if (mounted && widget.slotName == null) { // **关键判断**
      if (_effectiveController?.text != value) {
        didChange(_effectiveController!.text);
      }
    } else if (mounted && widget.controller != null) {
      // 如果 state 变成了 slotName 模式，尝试移除监听
      try { widget.controller?.removeListener(_handleControllerChanged); } catch (e) { /* ignore */ }
    }
  }

  // didChange 由 builder 中的 onChanged 调用
  @override
  void didChange(String? value) {
    // 只更新 FormField 的内部值
    super.didChange(value);
  }
}