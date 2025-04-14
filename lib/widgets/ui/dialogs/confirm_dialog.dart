// lib/widgets/ui/dialogs/custom_confirm_dialog.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'base_input_dialog.dart'; // *** 引入底层对话框 ***

// --- CustomConfirmDialog 本身可以简化为一个包含静态 show 方法的类 ---
// 因为实际的 UI 和状态由 BaseInputDialog 处理
class CustomConfirmDialog {

  /// 显示自定义【确认】对话框的静态方法 (调用 BaseInputDialog.show)
  /// 返回 Future<void>: 确认时完成，取消或关闭时也完成（可能带错误）
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    required Future<void> Function() onConfirm, // 保持 onConfirm 的签名
    String cancelButtonText = '取消',
    String confirmButtonText = '确认',
    Color confirmButtonColor = Colors.blue, // 默认确认按钮颜色改为蓝色
    VoidCallback? onCancel,
    IconData iconData = Icons.info_outline, // 默认改为信息图标
    Color iconColor = Colors.blue,       // 默认改为蓝色
    bool barrierDismissible = false,      // 确认对话框通常不允许点击外部关闭
    double maxWidth = 300,
    // 动画参数可以省略，使用 BaseInputDialog 的默认值
  }) {
    final theme = Theme.of(context);
    // 确定图标和按钮颜色
    final effectiveIconColor = iconColor; // 直接使用传入的
    final effectiveConfirmButtonColor = confirmButtonColor;

    // 使用 Completer 包装 onConfirm 的 Future<void>
    final completer = Completer<void>();

    // 调用 BaseInputDialog.show，泛型类型设为 bool (仅用于内部判断是否确认)
    BaseInputDialog.show<bool>(
      context: context,
      title: title,
      iconData: iconData,
      iconColor: effectiveIconColor,
      cancelButtonText: cancelButtonText,
      confirmButtonText: confirmButtonText,
      confirmButtonColor: effectiveConfirmButtonColor,
      maxWidth: maxWidth,
      barrierDismissible: barrierDismissible, // 传递 barrierDismissible
      onCancel: onCancel, // 传递 onCancel

      // --- 构建消息文本作为内容 ---
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

      // --- 确认回调: 执行原始 onConfirm 并完成 Completer ---
      onConfirm: () async {
        try {
          // 调用外部传入的 onConfirm (Future<void>)
          await onConfirm();
          // 如果 onConfirm 成功完成且 completer 未完成
          if (!completer.isCompleted) {
            completer.complete(); // 正常完成
          }
          return true; // 返回 true 表示确认成功，BaseInputDialog 会关闭
        } catch (e) {
          // 如果 onConfirm 抛出异常
          if (!completer.isCompleted) {
            completer.completeError(e); // 以错误完成
          }
          // 把异常继续抛给 BaseInputDialog 处理 (它会关闭对话框并 rethrow)
          rethrow;
        }
      },
    ).then((confirmed) {
      // 当 BaseInputDialog 关闭时 (无论是确认返回 true，还是取消/外部点击返回 null)
      // 检查 completer 是否已经完成
      if (!completer.isCompleted) {
        // 如果是因取消或外部点击关闭 (confirmed 为 null)
        // 并且 onConfirm 没有被调用或没有出错（completer 未完成）
        // 这里不需要做什么，因为 show 方法返回 Future<void>，不关心返回值
        // 调用者可以通过 try-catch 捕获 onConfirm 的错误
      }
    });

    // 返回 completer.future，调用者可以 await 它，并通过 try-catch 处理错误
    return completer.future;
  }
}
