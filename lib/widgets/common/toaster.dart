// lib/widgets/common/toaster.dart
import 'package:flutter/material.dart';


class Toaster {
  static void show(
      BuildContext context, {
        required String message,
        Duration duration = const Duration(seconds: 2),
        bool isError = false,
      }) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.clearSnackBars();

    final theme = Theme.of(context);

    // 根据是否为错误消息选择颜色
    final Color baseColor = isError ? Colors.red : Colors.blue;

    scaffold.showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // 状态图标
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              // 消息文本
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
        duration: duration,
        backgroundColor: baseColor.withOpacity(0.95),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        animation: CurvedAnimation(
          parent: const AlwaysStoppedAnimation(1),
          curve: Curves.easeOutCirc,
        ),
        dismissDirection: DismissDirection.horizontal,
        action: SnackBarAction(
          label: '关闭',
          textColor: Colors.white.withOpacity(0.8),
          onPressed: () => scaffold.hideCurrentSnackBar(),
        ),
      ),
    );
  }

  // 成功提示的便捷方法
  static void success(BuildContext context, String message) {
    show(context, message: message, isError: false);
  }

  // 错误提示的便捷方法
  static void error(BuildContext context, String message) {
    show(context, message: message, isError: true);
  }
}