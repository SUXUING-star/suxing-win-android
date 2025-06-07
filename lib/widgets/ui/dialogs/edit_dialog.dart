// lib/widgets/ui/dialogs/edit_dialog.dart

/// 该文件定义了 EditDialog 类，用于显示可编辑文本的对话框。
/// EditDialog 封装了 BaseInputDialog 和 FormTextInputField，提供编辑和保存功能。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/providers/inputs/input_state_provider.dart'; // 导入输入状态服务
import 'package:suxingchahui/widgets/ui/inputs/form_text_input_field.dart'; // 导入表单文本输入框
import 'dart:async'; // 异步操作所需
import 'base_input_dialog.dart'; // 导入基础输入对话框

/// `EditDialog` 类：自定义编辑对话框工具。
///
/// 提供静态方法显示一个可编辑文本内容的对话框，并支持保存功能。
class EditDialog {
  /// 显示编辑对话框。
  ///
  /// [inputStateService]：输入状态服务。
  /// [context]：Build 上下文。
  /// [title]：对话框标题。
  /// [initialText]：初始文本内容。
  /// [onSave]：保存操作回调。
  /// [isDraggable]：是否可拖拽。
  /// [isScalable]：是否可缩放。
  /// [minScale]：最小缩放比例。
  /// [maxScale]：最大缩放比例。
  /// [hintText]：提示文本。
  /// [cancelButtonText]：取消按钮文本。
  /// [saveButtonText]：保存按钮文本。
  /// [maxLines]：最大行数。
  /// [iconData]：对话框图标。
  /// [iconColor]：图标颜色。
  /// [keyboardType]：键盘类型。
  /// [maxWidth]：对话框最大宽度。
  /// [barrierDismissible]：是否可点击外部关闭。
  /// 返回一个 Future，表示对话框关闭或保存操作完成。
  static Future<void> show({
    required InputStateService inputStateService,
    required BuildContext context,
    required String title,
    required String initialText,
    required Future<void> Function(String text) onSave,
    bool isDraggable = true,
    bool isScalable = true,
    double minScale = 0.7,
    double maxScale = 2.0,
    String hintText = '编辑内容...',
    String cancelButtonText = '取消',
    String saveButtonText = '保存',
    int maxLines = 3,
    IconData iconData = Icons.edit_note,
    Color? iconColor,
    TextInputType? keyboardType,
    double maxWidth = 350,
    bool barrierDismissible = true,
  }) async {
    final theme = Theme.of(context); // 获取当前主题
    final effectiveIconColor = iconColor ?? theme.primaryColor; // 有效图标颜色
    final formKey = GlobalKey<FormState>(); // 表单键

    final controller = TextEditingController(text: initialText); // 创建文本编辑控制器

    try {
      await BaseInputDialog.show<bool>(
        context: context,
        title: title,
        iconData: iconData,
        iconColor: effectiveIconColor,
        cancelButtonText: cancelButtonText,
        confirmButtonText: saveButtonText,
        confirmButtonColor: theme.primaryColor,
        maxWidth: maxWidth,
        barrierDismissible: barrierDismissible,
        allowDismissWhenNotProcessing: barrierDismissible,
        contentBuilder: (dialogContext) {
          return Form(
            key: formKey, // 绑定表单键
            child: FormTextInputField(
              controller: controller, // 使用控制器
              inputStateService: inputStateService,
              decoration: InputDecoration(
                hintText: hintText, // 提示文本
                filled: true, // 填充
                fillColor: Colors.grey.shade100, // 填充颜色
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0), // 圆角
                  borderSide: BorderSide.none, // 无边框
                ),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(
                        color: theme.primaryColor, width: 1.5)), // 焦点边框
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12), // 内容内边距
              ),
              maxLines: maxLines, // 最大行数
              textInputAction: // 文本输入动作
                  maxLines > 1 ? TextInputAction.newline : TextInputAction.done,
              keyboardType: keyboardType, // 键盘类型
              autofocus: true, // 自动获取焦点
              validator: (value) {
                // 验证器
                if (value == null || value.trim().isEmpty) {
                  return '内容不能为空';
                }
                return null;
              },
            ),
          );
        },
        onConfirm: () async {
          if (formKey.currentState?.validate() == true) {
            // 验证表单
            final text = controller.text.trim(); // 获取并修剪文本
            try {
              await onSave(text); // 执行外部传入的保存逻辑
              return true; // 成功保存，返回 true
            } catch (e) {
              rethrow; // 重新抛出异常
            }
          } else {
            return null; // 验证失败，返回 null
          }
        },
        isDraggable: isDraggable, // 传递拖拽参数
        isScalable: isScalable, // 传递缩放参数
        minScale: minScale, // 传递最小缩放比例
        maxScale: maxScale, // 传递最大缩放比例
      );
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (controller.toString().contains('disposed') == false) {
          // 检查控制器是否未销毁
          controller.dispose(); // 销毁控制器
        }
      });
    }
  }
}
