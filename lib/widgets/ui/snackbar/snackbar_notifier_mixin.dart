// lib/widgets/ui/snackbar/snackbar_notifier_mixin.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';

// 定义 SnackBar 信息类和类型 (如果还没定义的话)
enum SnackbarType { success, error, warning, info }

class SnackbarInfo {
  final String message;
  final SnackbarType type;
  final String? actionLabel; // 可选的 Action
  final VoidCallback? onActionPressed; // 可选的 Action 回调

  SnackbarInfo(
      this.message,
      this.type, {
        this.actionLabel,
        this.onActionPressed,
      });
}

// ---- SnackBar 管理的 Mixin ----
mixin SnackBarNotifierMixin<T extends StatefulWidget> on State<T> {
  SnackbarInfo? _snackbarInfoForMixin;

  /// 触发一个 SnackBar 显示请求。
  /// 这会在下一次 build 循环的 post-frame 回调中显示 SnackBar。
  void showSnackbar({
    required String message,
    required SnackbarType type,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    if (mounted) {
      setState(() {
        _snackbarInfoForMixin = SnackbarInfo(
          message,
          type,
          actionLabel: actionLabel,
          onActionPressed: onActionPressed,
        );
      });
    }
    // 如果 widget unmounted，请求会自然丢失
  }

  /// 在你的 State 的 build 方法的开头或者结尾调用此方法。
  /// 它会检查是否有待显示的 SnackBar，并在 post-frame 回调中显示它。
  ///
  /// 示例用法:
  /// @override
  /// Widget build(BuildContext context) {
  ///   // 在 build 方法的开始或结束调用
  ///   buildSnackBar(context);
  ///
  ///   return Scaffold(...);
  /// }
  void buildSnackBar(BuildContext context) {
    if (_snackbarInfoForMixin != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _snackbarInfoForMixin != null) {
          final info = _snackbarInfoForMixin!;
          switch (info.type) {
            case SnackbarType.success:
              AppSnackBar.showSuccess(
                context, // 使用当前 build 的 context
                info.message,
                actionLabel: info.actionLabel,
                onActionPressed: info.onActionPressed,
              );
              break;
            case SnackbarType.error:
              AppSnackBar.showError(
                context,
                info.message,
                actionLabel: info.actionLabel,
                onActionPressed: info.onActionPressed,
              );
              break;
            case SnackbarType.warning:
              AppSnackBar.showWarning(
                context,
                info.message,
                actionLabel: info.actionLabel,
                onActionPressed: info.onActionPressed,
              );
              break;
            case SnackbarType.info:
              AppSnackBar.showInfo(
                context,
                info.message,
                actionLabel: info.actionLabel,
                onActionPressed: info.onActionPressed,
              );
              break;
          }
          // 清除，防止重复显示
          if (mounted) {
            setState(() {
              _snackbarInfoForMixin = null;
            });
          }
        }
      });
    }
  }
}