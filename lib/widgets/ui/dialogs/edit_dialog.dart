// lib/widgets/ui/dialogs/edit_dialog.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'base_input_dialog.dart'; // *** 引入底层对话框 ***

// --- EditDialog 现在是一个包含静态 show 方法的类 ---
class EditDialog {

  /// 显示【单行】编辑对话框的静态方法 (调用 BaseInputDialog.show)
  /// **保持原有 onSave 签名: required Future<void> Function(String text) onSave**
  /// 返回 Future<void>: 仅用于表示对话框关闭或 onSave 抛出错误
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String initialText,
    // *** 保持原来的 onSave 签名 ***
    required Future<void> Function(String text) onSave,
    String hintText = '编辑内容...',
    String cancelButtonText = '取消',
    String saveButtonText = '保存',
    int maxLines = 3, // 保留 maxLines 参数
    IconData iconData = Icons.edit_note,
    Color? iconColor,
    TextInputType? keyboardType, // 保留键盘类型
    double maxWidth = 300,
  }) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.primaryColor;
    // 使用 GlobalKey 来访问 TextFormField 的状态
    final formKey = GlobalKey<FormState>();
    // 使用 TextEditingController 来获取文本
    final controller = TextEditingController(text: initialText);

    // 使用 Completer 来包装外部调用者等待的 Future<void>
    final completer = Completer<void>();

    // 调用 BaseInputDialog.show，内部泛型设为 bool (用于区分确认/取消)
    BaseInputDialog.show<bool>(
      context: context,
      title: title,
      iconData: iconData,
      iconColor: effectiveIconColor,
      cancelButtonText: cancelButtonText,
      confirmButtonText: saveButtonText,
      confirmButtonColor: theme.primaryColor, // 保存按钮用主题色
      maxWidth: maxWidth,
      barrierDismissible: true, // 编辑对话框通常允许点击外部关闭

      // --- 构建 TextFormField 作为内容 ---
      contentBuilder: (dialogContext) {
        return Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            // *** 补全 InputDecoration ***
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
                  borderSide: BorderSide(color: theme.primaryColor, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            // **************************
            maxLines: maxLines,
            textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.done,
            keyboardType: keyboardType,
            autofocus: true,
            // *** 补全 validator ***
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '内容不能为空'; // 基本校验
              }
              return null; // 校验通过
            },
            // ********************
          ),
        );
      },

      // --- 确认回调 (内部转换) ---
      onConfirm: () async {
        // 1. 校验表单
        if (formKey.currentState?.validate() == true) {
          final text = controller.text.trim();
          try {
            // 2. *** 调用外部传入的 onSave (Future<void>) ***
            await onSave(text);
            // 3. 如果 onSave 成功完成，返回 true 让 BaseInputDialog 关闭
            return true; // 返回非 null 值表示成功并关闭
          } catch (e) {
            // 4. 如果 onSave 失败，把错误抛给 BaseInputDialog 处理
            // BaseInputDialog 会关闭对话框并 rethrow
            rethrow;
          }
        } else {
          // 5. 校验失败，返回 null，BaseInputDialog 不会关闭对话框
          return null;
        }
      },
      // onCancel 使用 BaseInputDialog 的默认行为 (关闭对话框)
    ).whenComplete(() {
      // 当 BaseInputDialog 的 Future 完成时 (无论成功、失败、取消)
      // 确保外部等待的 Future<void> 也完成
      if (!completer.isCompleted) {
        completer.complete();
      }
    }).catchError((e){
      // 如果 BaseInputDialog 的 Future 因错误完成
      if (!completer.isCompleted) {
        completer.completeError(e); // 将错误传递给外部 Future
      }
    });

    return completer.future; // 返回 Future<void>
  }
}

