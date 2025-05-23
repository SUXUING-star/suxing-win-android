// lib/widgets/ui/dialogs/edit_dialog.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/widgets/ui/inputs/form_text_input_field.dart'; // 假设路径正确
import 'dart:async';
import 'base_input_dialog.dart';

class EditDialog {
  /// 显示【单行/多行】编辑对话框的静态方法 (调用 BaseInputDialog.show)
  /// 返回 Future: 仅用于表示对话框关闭或 onSave 抛出错误
  static Future<void> show({
    required InputStateService inputStateService,
    required BuildContext context,
    required String title,
    required String initialText,
    required Future<void> Function(String text) onSave,
    // --- 设置交互参数的默认值 ---
    bool isDraggable = true, //
    bool isScalable = true, //
    double minScale = 0.7, // 默认值
    double maxScale = 2.0, // 默认值
    // ------------------
    String hintText = '编辑内容...',
    String cancelButtonText = '取消',
    String saveButtonText = '保存',
    int maxLines = 3,
    IconData iconData = Icons.edit_note,
    Color? iconColor,
    TextInputType? keyboardType,
    double maxWidth = 350, // 编辑对话框可能需要稍宽一点
    bool barrierDismissible = true, // 编辑对话框默认允许外部关闭
  }) async {
    // 改为 async
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.primaryColor;
    final formKey = GlobalKey<FormState>();

    // Controller 在这里创建，需要在 finally 中 dispose
    final controller = TextEditingController(text: initialText);

    try {
      await BaseInputDialog.show<bool>(
        // 等待结果
        context: context,
        title: title,
        iconData: iconData,
        iconColor: effectiveIconColor,
        cancelButtonText: cancelButtonText,
        confirmButtonText: saveButtonText,
        confirmButtonColor: theme.primaryColor,
        maxWidth: maxWidth,
        barrierDismissible: barrierDismissible,
        allowDismissWhenNotProcessing: barrierDismissible, // 保持一致
        contentBuilder: (dialogContext) {
          // 在这里创建 Form 和 TextField
          return Form(
            key: formKey,
            child: FormTextInputField(
              controller: controller, // 使用上面创建的 controller
              inputStateService: inputStateService,
              decoration: InputDecoration(
                hintText: hintText,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide:
                        BorderSide(color: theme.primaryColor, width: 1.5)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: maxLines,
              textInputAction:
                  maxLines > 1 ? TextInputAction.newline : TextInputAction.done,
              keyboardType: keyboardType,
              autofocus: true, // 自动聚焦输入框
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '内容不能为空';
                }
                return null;
              },
            ),
          );
        },
        onConfirm: () async {
          // BaseInputDialog 的 onConfirm
          if (formKey.currentState?.validate() == true) {
            final text = controller.text.trim();
            try {
              await onSave(text); // 执行外部传入的保存逻辑
              return true; // 成功保存，返回 true 关闭对话框
            } catch (e) {
              // 如果 onSave 失败，重新抛出异常
              rethrow;
            }
          } else {
            // 校验失败，返回 null，BaseInputDialog 不会关闭对话框
            return null;
          }
        },
        // --- 传递交互参数 ---
        isDraggable: isDraggable, // 传递从 show 方法接收或默认的值
        isScalable: isScalable, // 传递从 show 方法接收或默认的值
        minScale: minScale,
        maxScale: maxScale,
        // ------------------
        // onCancel 不需要特殊处理，BaseInputDialog 会处理关闭
      );
    } finally {
      // *** 确保 Controller 被释放 ***
      // 当 BaseInputDialog.show 的 Future 完成时（无论成功、失败、取消）
      // 这个 finally 块会被执行
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (controller.toString().contains('disposed') == false) {
          // 检查是否已 dispose
          controller.dispose();
        }
      });
      // 使用 addPostFrameCallback 稍微延迟 dispose，避免在 build 过程中 dispose
      // 或者直接 dispose 也可以，因为此时 dialog 已经 pop 了。
      // controller.dispose(); // 直接 dispose 通常也是安全的
    }
  }
}
