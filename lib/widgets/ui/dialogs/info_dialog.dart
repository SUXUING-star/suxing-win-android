// lib/widgets/ui/dialogs/info_dialog.dart

/// 该文件定义了 CustomInfoDialog 类，用于显示自定义信息对话框。
/// CustomInfoDialog 封装了 BaseInputDialog，提供了简洁的信息提示接口。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'dart:async'; // 异步操作所需
import 'base_input_dialog.dart'; // 导入基础输入对话框

/// `CustomInfoDialog` 类：自定义信息对话框组件。
///
/// 该类继承自 BaseInputDialog，用于显示信息提示，并支持关闭操作。
class CustomInfoDialog extends BaseInputDialog<bool> {
  final VoidCallback? onClose; // 关闭对话框时的回调

  /// 私有构造函数。
  ///
  /// [title]：标题。
  /// [message]：消息。
  /// [closeButtonText]：关闭按钮文本。
  /// [onClose]：关闭回调。
  /// [iconData]：图标。
  /// [iconColor]：图标颜色。
  /// [closeButtonColor]：关闭按钮颜色。
  /// [dismissibleWhenNotProcessing]：非处理中时是否可关闭。
  /// [isDraggable]：是否可拖拽。
  /// [isScalable]：是否可缩放。
  /// [minScale]：最小缩放比例。
  /// [maxScale]：最大缩放比例。
  CustomInfoDialog._({
    required String title,
    required String message,
    String closeButtonText = '好的',
    this.onClose,
    IconData iconData = Icons.info_outline,
    Color iconColor = Colors.blue,
    Color? closeButtonColor,
    bool dismissibleWhenNotProcessing = true,
    required bool isDraggable,
    required bool isScalable,
    double minScale = 0.7,
    double maxScale = 2.0,
    Key? key,
  }) : super(
          key: key,
          title: title,
          contentBuilder: (context) {
            final theme = Theme.of(context);
            final bodyMedium = theme.textTheme.bodyMedium ?? const TextStyle();
            return Text(
              message, // 消息文本
              textAlign: TextAlign.center, // 文本居中
              style: bodyMedium.copyWith(
                height: 1.5,
                color: Colors.black54,
              ),
            );
          },
          onConfirm: () async {
            onClose?.call(); // 调用关闭回调
            return true; // 返回 true 关闭对话框
          },
          confirmButtonText: closeButtonText, // 确认按钮文本
          confirmButtonColor: closeButtonColor, // 确认按钮颜色
          showCancelButton: false, // 不显示取消按钮
          iconData: iconData, // 图标
          iconColor: iconColor, // 图标颜色
          dismissibleWhenNotProcessing: dismissibleWhenNotProcessing, // 可点击外部关闭
          onCancel: () {
            onClose?.call(); // 调用关闭回调
          },
          isDraggable: isDraggable, // 传递拖拽参数
          isScalable: isScalable, // 传递缩放参数
          minScale: minScale, // 传递最小缩放比例
          maxScale: maxScale, // 传递最大缩放比例
        );

  /// 显示自定义信息对话框。
  ///
  /// [context]：Build 上下文。
  /// [title]：对话框标题。
  /// [message]：对话框消息。
  /// [isDraggable]：是否可拖拽。
  /// [isScalable]：是否可缩放。
  /// [minScale]：最小缩放比例。
  /// [maxScale]：最大缩放比例。
  /// [closeButtonText]：关闭按钮文本。
  /// [onClose]：关闭操作回调。
  /// [iconData]：对话框图标。
  /// [iconColor]：图标颜色。
  /// [closeButtonColor]：关闭按钮颜色。
  /// [barrierDismissible]：是否可点击外部关闭。
  /// [maxWidth]：对话框最大宽度。
  /// 返回一个 Future，表示对话框关闭。
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    bool isDraggable = true,
    bool isScalable = false,
    double minScale = 0.7,
    double maxScale = 2.0,
    String closeButtonText = '好的',
    VoidCallback? onClose,
    IconData iconData = Icons.info_outline,
    Color iconColor = Colors.blue,
    Color? closeButtonColor,
    bool barrierDismissible = true,
    double maxWidth = 300,
  }) async {
    await BaseInputDialog.show<bool>(
      context: context,
      title: title,
      contentBuilder: (context) {
        final theme = Theme.of(context);
        final bodyMedium = theme.textTheme.bodyMedium ?? const TextStyle();
        return Text(
          message, // 消息文本
          textAlign: TextAlign.center, // 文本居中
          style: bodyMedium.copyWith(
            height: 1.5,
            color: Colors.black54,
          ),
        );
      },
      onConfirm: () async {
        onClose?.call(); // 调用关闭回调
        return true; // 返回 true 关闭对话框
      },
      confirmButtonText: closeButtonText, // 确认按钮文本
      confirmButtonColor: closeButtonColor, // 确认按钮颜色
      iconData: iconData, // 图标
      iconColor: iconColor, // 图标颜色
      showCancelButton: false, // 不显示取消按钮
      barrierDismissible: barrierDismissible, // 可点击外部关闭
      allowDismissWhenNotProcessing: barrierDismissible, // 保持一致
      maxWidth: maxWidth, // 最大宽度
      onCancel: () {
        onClose?.call(); // 调用关闭回调
      },
      isDraggable: isDraggable, // 传递拖拽参数
      isScalable: isScalable, // 传递缩放参数
      minScale: minScale, // 传递最小缩放比例
      maxScale: maxScale, // 传递最大缩放比例
    );
  }
}
