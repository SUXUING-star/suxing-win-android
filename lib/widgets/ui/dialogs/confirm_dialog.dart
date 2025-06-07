// lib/widgets/ui/dialogs/custom_confirm_dialog.dart

/// 该文件定义了 CustomConfirmDialog 类，用于显示自定义确认对话框。
/// CustomConfirmDialog 封装了 BaseInputDialog，提供了简洁的确认对话框接口。
library;


import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'dart:async'; // 异步操作所需
import 'base_input_dialog.dart'; // 导入基础输入对话框

/// `CustomConfirmDialog` 类：自定义确认对话框工具。
///
/// 提供静态方法显示一个可定制的确认对话框。
class CustomConfirmDialog {
  /// 显示自定义确认对话框。
  ///
  /// [context]：Build 上下文。
  /// [title]：对话框标题。
  /// [message]：对话框消息。
  /// [onConfirm]：确认操作回调。
  /// [isDraggable]：是否可拖拽。
  /// [isScalable]：是否可缩放。
  /// [minScale]：最小缩放比例。
  /// [maxScale]：最大缩放比例。
  /// [cancelButtonText]：取消按钮文本。
  /// [confirmButtonText]：确认按钮文本。
  /// [confirmButtonColor]：确认按钮颜色。
  /// [onCancel]：取消操作回调。
  /// [iconData]：对话框图标。
  /// [iconColor]：图标颜色。
  /// [barrierDismissible]：是否可点击外部关闭。
  /// [maxWidth]：对话框最大宽度。
  /// 返回一个 Future，确认操作完成或取消时完成。
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    required Future<void> Function() onConfirm,
    bool isDraggable = true,
    bool isScalable = false,
    double minScale = 0.7,
    double maxScale = 2.0,
    String cancelButtonText = '取消',
    String confirmButtonText = '确认',
    Color confirmButtonColor = Colors.blue,
    VoidCallback? onCancel,
    IconData iconData = Icons.help_outline,
    Color iconColor = Colors.orange,
    bool barrierDismissible = false,
    double maxWidth = 300,
  }) async {
    final effectiveConfirmButtonColor = confirmButtonColor; // 有效确认按钮颜色
    final effectiveIconColor = iconColor; // 有效图标颜色

    try {
      await BaseInputDialog.show<bool>(
        context: context,
        title: title,
        iconData: iconData,
        iconColor: effectiveIconColor,
        cancelButtonText: cancelButtonText,
        confirmButtonText: confirmButtonText,
        confirmButtonColor: effectiveConfirmButtonColor,
        maxWidth: maxWidth,
        barrierDismissible: barrierDismissible,
        allowDismissWhenNotProcessing: barrierDismissible,
        onCancel: onCancel,
        contentBuilder: (dialogContext) {
          return Text(
            message, // 消息文本
            textAlign: TextAlign.center, // 文本居中
            style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: Colors.black54,
                ),
          );
        },
        onConfirm: () async {
          try {
            await onConfirm(); // 执行外部传入的确认逻辑
            return true; // 成功执行，返回 true
          } catch (e) {
            rethrow; // 重新抛出异常
          }
        },
        isDraggable: isDraggable, // 传递拖拽参数
        isScalable: isScalable, // 传递缩放参数
        minScale: minScale, // 传递最小缩放比例
        maxScale: maxScale, // 传递最大缩放比例
      );
    } catch (e) {
      rethrow; // 重新抛出错误
    }
  }
}
