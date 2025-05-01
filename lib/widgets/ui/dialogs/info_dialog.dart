// lib/widgets/ui/dialogs/info_dialog.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'base_input_dialog.dart'; // 导入基类

/// 自定义信息对话框 Widget
/// *** 现在继承自 BaseInputDialog ***
class CustomInfoDialog extends BaseInputDialog<bool> {
  final VoidCallback? onClose;

  // *** 构造函数调用 super，并传递交互参数 ***
  // 注意：这个私有构造函数现在主要由内部或测试使用。
  // 公共 API 是静态 show 方法。默认值应在 show 方法中设置。
  CustomInfoDialog._({
    required String title,
    required String message,
    String closeButtonText = '好的',
    this.onClose,
    IconData iconData = Icons.info_outline,
    Color iconColor = Colors.blue,
    Color? closeButtonColor,
    bool dismissibleWhenNotProcessing = true,
    // --- 交互参数从 show 方法传入 ---
    required bool isDraggable, // 改为 required，因为默认值在 show 设置
    required bool isScalable, // 改为 required
    double minScale = 0.7,
    double maxScale = 2.0,
    // ---------------
    Key? key,
  }) : super(
    key: key,
    title: title,
    contentBuilder: (context) {
      final theme = Theme.of(context);
      final bodyMedium = theme.textTheme.bodyMedium ?? const TextStyle();
      return Text(
        message,
        textAlign: TextAlign.center,
        style: bodyMedium.copyWith(
          height: 1.5,
          color: Colors.black54,
        ),
      );
    },
    onConfirm: () async {
      onClose?.call();
      return true;
    },
    confirmButtonText: closeButtonText,
    confirmButtonColor: closeButtonColor,
    showCancelButton: false,
    iconData: iconData,
    iconColor: iconColor,
    dismissibleWhenNotProcessing: dismissibleWhenNotProcessing,
    onCancel: () {
      onClose?.call();
    },
    // --- 传递交互参数给 super ---
    isDraggable: isDraggable,
    isScalable: isScalable,
    minScale: minScale,
    maxScale: maxScale,
    // -----------------------
  );

  /// 显示自定义信息对话框的静态方法
  /// *** 现在调用 BaseInputDialog.show<bool> ***
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    // --- 设置交互参数的默认值 ---
    bool isDraggable = true, // <<--- 默认允许拖拽
    bool isScalable = false, // <<--- 默认不允许缩放
    double minScale = 0.7,   // 默认值
    double maxScale = 2.0,   // 默认值
    // ---------------------------
    String closeButtonText = '好的',
    VoidCallback? onClose,
    IconData iconData = Icons.info_outline,
    Color iconColor = Colors.blue,
    Color? closeButtonColor,
    bool barrierDismissible = true,
    // 动画参数不再需要传递，由 BaseInputDialog.show 内部处理
    double maxWidth = 300,
  }) async {
    // 调用基类的 show 方法，并传递所有参数
    await BaseInputDialog.show<bool>(
      context: context,
      title: title,
      contentBuilder: (context) {
        final theme = Theme.of(context);
        final bodyMedium = theme.textTheme.bodyMedium ?? const TextStyle();
        return Text(
          message,
          textAlign: TextAlign.center,
          style: bodyMedium.copyWith(
            height: 1.5,
            color: Colors.black54,
          ),
        );
      },
      onConfirm: () async {
        onClose?.call();
        return true; // 返回 true 让 BaseInputDialog 关闭
      },
      confirmButtonText: closeButtonText,
      confirmButtonColor: closeButtonColor,
      iconData: iconData,
      iconColor: iconColor,
      showCancelButton: false,
      barrierDismissible: barrierDismissible,
      allowDismissWhenNotProcessing: barrierDismissible, // 保持一致
      maxWidth: maxWidth,
      onCancel: () {
        onClose?.call();
        // BaseInputDialog 的 show 方法会处理 completer，这里不需要再 complete
      },
      // --- 传递交互参数给 BaseInputDialog.show ---
      isDraggable: isDraggable, // 传递从 show 方法接收或默认的值
      isScalable: isScalable, // 传递从 show 方法接收或默认的值
      minScale: minScale,
      maxScale: maxScale,
      // -------------------------------------
    );
    // 不需要返回 BaseInputDialog.show 的结果 (true/null)，所以是 Future<void>
  }
}