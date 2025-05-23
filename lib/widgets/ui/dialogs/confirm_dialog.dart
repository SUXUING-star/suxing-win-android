// lib/widgets/ui/dialogs/custom_confirm_dialog.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'base_input_dialog.dart';

class CustomConfirmDialog {
  /// 显示自定义【确认】对话框的静态方法 (调用 BaseInputDialog.show)
  /// 返回 Future: 确认时完成，取消或关闭时也完成（可能带错误）
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    required Future<void> Function() onConfirm,
    // --- 设置交互参数的默认值 ---
    bool isDraggable = true, // <<--- 默认允许拖拽
    bool isScalable = false, // <<--- 默认不允许缩放
    double minScale = 0.7, // 默认值
    double maxScale = 2.0, // 默认值
    // ---------------------------
    String cancelButtonText = '取消',
    String confirmButtonText = '确认',
    Color confirmButtonColor =
        Colors.blue, // 考虑使用 Theme.of(context).primaryColor
    VoidCallback? onCancel,
    IconData iconData = Icons.help_outline, // 确认对话框用 help 图标可能更合适
    Color iconColor = Colors.orange, // 确认对话框用警告色或主题色
    bool barrierDismissible = false, // 确认对话框通常不允许点击外部关闭
    double maxWidth = 300,
  }) async {
    // 改为 async，因为 BaseInputDialog.show 返回 Future
    // final theme = Theme.of(context);
    // 使用主题色作为默认确认按钮颜色和图标颜色可能更好
    final effectiveConfirmButtonColor = confirmButtonColor;
    final effectiveIconColor = iconColor;

    // 不再需要手动管理 Completer，让 BaseInputDialog.show 返回的 Future 来处理
    try {
      await BaseInputDialog.show<bool>(
        // 等待 BaseInputDialog.show 完成
        context: context,
        title: title,
        iconData: iconData,
        iconColor: effectiveIconColor,
        cancelButtonText: cancelButtonText,
        confirmButtonText: confirmButtonText,
        confirmButtonColor: effectiveConfirmButtonColor,
        maxWidth: maxWidth,
        barrierDismissible: barrierDismissible,
        allowDismissWhenNotProcessing: barrierDismissible, // 保持一致
        onCancel: onCancel,
        contentBuilder: (dialogContext) {
          return Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: Colors.black54,
                ),
          );
        },
        onConfirm: () async {
          // 注意：这里的 onConfirm 是 BaseInputDialog 的，它需要返回 T? (这里是 bool?)
          // 外部传入的 onConfirm 是 Future<void>
          try {
            await onConfirm(); // 执行外部传入的确认逻辑
            return true; // 成功执行，返回 true 关闭对话框
          } catch (e) {
            // 如果外部 onConfirm 抛出异常，重新抛出
            // BaseInputDialog 的 show 会捕获并使 Future fail
            rethrow;
          }
        },
        // --- 传递交互参数 ---
        isDraggable: isDraggable, // 传递从 show 方法接收或默认的值
        isScalable: isScalable, // 传递从 show 方法接收或默认的值
        minScale: minScale,
        maxScale: maxScale,
        // ------------------
      );
      // 如果 BaseInputDialog.show 正常完成（无论是确认还是取消关闭），
      // 这个 Future<void> 就正常完成。
    } catch (e) {
      // 如果 BaseInputDialog.show 的 Future 失败了（通常是因为 onConfirm 抛异常）
      // 重新抛出错误，让调用者知道确认操作失败了。
      rethrow;
    }
  }
}
