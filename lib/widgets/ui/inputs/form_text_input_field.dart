// lib/widgets/ui/inputs/form_text_input_field.dart

/// 该文件定义了 FormTextInputField 组件，一个可与 Form 集成的文本输入框。
/// 该组件支持与 InputStateService 或独立的 TextEditingController 配合使用，并进行表单验证。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:flutter/services.dart'; // 导入系统服务，如键盘事件
import 'package:suxingchahui/providers/inputs/input_state_provider.dart'; // 导入输入状态服务
import 'text_input_field.dart'; // 导入 TextInputField

/// `FormTextInputField` 类：一个用于表单输入的文本字段。
///
/// 该组件封装了 TextInputField，并将其集成到 Flutter 的 Form 系统中，支持验证、保存和状态管理。
class FormTextInputField extends FormField<String> {
  final String? slotName; // 用于 InputStateService 的槽名称
  final TextEditingController? controller; // 文本编辑控制器
  final InputStateService inputStateService; // 输入状态服务实例
  final FocusNode? focusNode; // 焦点节点
  final String? hintText; // 提示文本
  final int? maxLines; // 最大行数
  final bool isEnabled; // 是否启用
  final EdgeInsetsGeometry? contentPadding; // 内容内边距
  final EdgeInsetsGeometry? padding; // 外部填充
  final InputDecoration? decoration; // 输入装饰
  final TextStyle? textStyle; // 文本样式
  final TextStyle? hintStyle; // 提示文本样式
  final bool autofocus; // 是否自动获取焦点
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
  /// [validator]：验证器。
  /// [onSaved]：保存回调。
  /// [initialValue]：初始值。
  /// [controller]：文本控制器。
  /// [slotName]：槽名称。
  /// [decoration]：输入装饰。
  /// [focusNode]：焦点节点。
  /// [hintText]：提示文本。
  /// [maxLines]：最大行数。
  /// [isEnabled]：是否启用。
  /// [contentPadding]：内容内边距。
  /// [padding]：外部填充。
  /// [textStyle]：文本样式。
  /// [hintStyle]：提示文本样式。
  /// [autofocus]：是否自动获取焦点。
  /// [maxLength]：最大长度。
  /// [maxLengthEnforcement]：最大长度限制策略。
  /// [minLines]：最小行数。
  /// [textInputAction]：文本输入动作。
  /// [keyboardType]：键盘类型。
  /// [obscureText]：是否隐藏文本。
  /// [onChanged]：文本改变回调。
  FormTextInputField({
    super.key,
    required this.inputStateService,
    required FormFieldValidator<String> validator,
    super.onSaved,
    super.initialValue,
    this.controller,
    this.slotName,
    this.decoration = const InputDecoration(),
    this.focusNode,
    this.hintText,
    this.maxLines = 1,
    this.isEnabled = true,
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
  })  : assert(controller == null || slotName == null, '不能同时提供控制器和槽名称。'),
        super(
          validator: validator,
          enabled: isEnabled,

          /// 构建表单字段的内部组件。
          ///
          /// [field]：表单字段状态。
          builder: (FormFieldState<String> field) {
            final _FormTextInputFieldState state =
                field as _FormTextInputFieldState;

            final InputDecoration effectiveDecoration =
                (decoration ?? const InputDecoration())
                    .applyDefaults(Theme.of(field.context).inputDecorationTheme)
                    .copyWith(
                      hintText: hintText ?? decoration?.hintText,
                      errorText: field.errorText,
                    );

            final bool useSlotName =
                slotName != null && slotName.isNotEmpty; // 判断是否使用槽名称

            return TextInputField(
              inputStateService: inputStateService,
              slotName: useSlotName ? slotName : null, // 传入槽名称或空
              controller:
                  useSlotName ? null : state._effectiveController, // 传入控制器或空
              focusNode: focusNode,
              hintText: hintText,
              maxLines: maxLines,
              enabled: isEnabled,
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
              showSubmitButton: false, // 在 Form 场景下不显示提交按钮
              handleEnterKey: false, // 在 Form 场景下不处理回车键提交
              /// 监听 TextInputField 的文本变化并更新 FormField 的状态。
              ///
              /// [value]：新的文本值。
              onChanged: (String value) {
                field.didChange(value); // 更新 FormField 的值
                onChanged?.call(value); // 调用外部的 onChanged 回调
              },
            );
          },
        );

  @override
  FormFieldState<String> createState() => _FormTextInputFieldState();
}

/// `_FormTextInputFieldState` 类：`FormTextInputField` 的状态管理。
///
/// 该类管理内部的文本控制器（当外部未提供时）并处理 FormField 的状态更新。
class _FormTextInputFieldState extends FormFieldState<String> {
  TextEditingController? _controller; // 内部文本编辑控制器

  /// 获取有效的文本编辑控制器。
  ///
  /// 当 `widget.slotName` 为空时，返回 `widget.controller` 或内部的 `_controller`。
  TextEditingController? get _effectiveController =>
      widget.controller ?? _controller;

  @override
  FormTextInputField get widget => super.widget as FormTextInputField;

  @override
  void initState() {
    super.initState();
    if (widget.slotName == null) {
      // 未使用槽名称模式
      if (widget.controller == null) {
        // 未提供外部控制器
        _controller =
            TextEditingController(text: widget.initialValue); // 创建内部控制器
      } else {
        // 提供了外部控制器
        widget.controller!.addListener(_handleControllerChanged); // 监听外部控制器
      }
      setValue(_effectiveController?.text ??
          widget.initialValue ??
          ''); // 初始化 FormField 的值
    } else {
      // 使用槽名称模式
      setValue(widget.initialValue ?? ''); // 设置 FormField 的初始值
    }
  }

  @override
  void didUpdateWidget(FormTextInputField oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool wasUsingSlotName =
        oldWidget.slotName != null && oldWidget.slotName!.isNotEmpty;
    final bool isUsingSlotName =
        widget.slotName != null && widget.slotName!.isNotEmpty;

    if (!isUsingSlotName && !wasUsingSlotName) {
      // 从未启用槽名称模式
      if (widget.controller != oldWidget.controller) {
        // 控制器实例发生变化
        oldWidget.controller
            ?.removeListener(_handleControllerChanged); // 移除旧外部控制器的监听
        _controller?.removeListener(_handleControllerChanged); // 移除旧内部控制器的监听

        if (oldWidget.controller != null && widget.controller == null) {
          // 从外部控制器切换到内部控制器
          _controller?.dispose(); // 销毁可能存在的旧内部控制器
          _controller = TextEditingController.fromValue(
              oldWidget.controller!.value); // 创建新内部控制器并继承旧值
          _controller!.addListener(_handleControllerChanged); // 监听新内部控制器
        } else if (oldWidget.controller == null && widget.controller != null) {
          // 从内部控制器切换到外部控制器
          _controller?.dispose(); // 销毁内部控制器
          _controller = null;
          widget.controller!.addListener(_handleControllerChanged); // 监听新外部控制器
        } else if (widget.controller != null) {
          // 外部控制器实例发生变化
          widget.controller!.addListener(_handleControllerChanged); // 监听新外部控制器
        }
        setValue(_effectiveController?.text ??
            widget.initialValue ??
            ''); // 同步 FormField 的值
      } else if (widget.controller == null &&
          oldWidget.controller == null &&
          widget.initialValue != oldWidget.initialValue) {
        // 仅初始值变化，且使用内部控制器
        if (_controller != null && _controller!.text != (value ?? '')) {
          _controller!.text = value ?? ''; // 同步内部控制器文本
        }
      }
    } else if (isUsingSlotName != wasUsingSlotName ||
        (isUsingSlotName && widget.slotName != oldWidget.slotName)) {
      // 槽名称模式发生切换或槽名称本身改变
      if (isUsingSlotName && !wasUsingSlotName) {
        // 从非槽名称模式切换到槽名称模式
        oldWidget.controller
            ?.removeListener(_handleControllerChanged); // 移除旧控制器的监听
        _controller?.dispose(); // 销毁内部控制器
        _controller = null;
        setValue(widget.initialValue ?? ''); // 设置 FormField 的初始值
      } else if (!isUsingSlotName && wasUsingSlotName) {
        // 从槽名称模式切换到非槽名称模式
        final String previousSlotValue =
            value ?? widget.initialValue ?? ''; // 获取切换前的值
        if (widget.controller == null) {
          // 未提供外部控制器
          _controller?.dispose(); // 确保清理旧内部控制器
          _controller =
              TextEditingController(text: previousSlotValue); // 创建新内部控制器并继承值
          _controller!.addListener(_handleControllerChanged); // 监听新内部控制器
        } else {
          // 提供了外部控制器
          _controller?.dispose(); // 销毁内部控制器
          _controller = null;
          widget.controller!.addListener(_handleControllerChanged); // 监听新外部控制器
        }
        setValue(
            _effectiveController?.text ?? previousSlotValue); // 同步 FormField 的值
      } else if (isUsingSlotName &&
          wasUsingSlotName &&
          widget.slotName != oldWidget.slotName) {
        // 槽名称改变
        setValue(widget.initialValue ?? ''); // 设置 FormField 的初始值
      }
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerChanged); // 移除外部控制器的监听
    _controller?.dispose(); // 销毁内部创建的控制器
    super.dispose();
  }

  @override
  void reset() {
    super.reset(); // 重置 FormField 内部状态
    final resetValue = widget.initialValue ?? '';
    if (widget.slotName == null) {
      // 未使用槽名称模式
      _effectiveController?.text = resetValue; // 更新控制器文本
    }
  }

  /// 监听内部或外部控制器的文本变化。
  ///
  /// 仅在未使用槽名称模式时有效。
  void _handleControllerChanged() {
    if (mounted && widget.slotName == null) {
      if (_effectiveController?.text != value) {
        didChange(_effectiveController!.text); // 更新 FormField 的值
      }
    }
  }
}
