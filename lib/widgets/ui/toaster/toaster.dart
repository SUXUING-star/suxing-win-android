// lib/widgets/common/toaster.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'dart:math' as math;

// 弃用ui
class Toaster {
  static void show(
      BuildContext context, {
        required String message,
        Duration duration = const Duration(seconds: 3),
        bool isError = false,
      }) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.clearSnackBars();

    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    // 判断是否为桌面平台
    final bool isDesktop = kIsWeb ||
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

    // 根据是否为错误消息选择颜色
    final Color baseColor = isError ? Colors.red[700]! : Colors.blue[700]!;

    // 桌面端和移动端使用不同的宽度和位置
    final double toastWidth = isDesktop
        ? math.min(320.0, screenSize.width * 0.25)
        : screenSize.width - 32;

    scaffold.showSnackBar(
      SnackBar(
        content: Container(
          width: toastWidth,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: isDesktop
              ? _buildDesktopToast(message, isError, theme)
              : _buildMobileToast(message, isError, theme),
        ),
        duration: duration,
        backgroundColor: baseColor.withOpacity(0.95),
        // 关键修改：在移动端使用固定行为，在桌面端保持浮动行为
        behavior: isDesktop ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
        elevation: 6,
        // 桌面端在右下角显示，移动端使用默认底部边距
        margin: isDesktop
            ? const EdgeInsets.only(bottom: 24, right: 24)
            : null, // 移动端不设置边距，让 SnackBar 保持在底部
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isDesktop ? 12 : 0), // 移动端不使用圆角
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

  // 桌面端的布局 - 垂直排列
  static Widget _buildDesktopToast(String message, bool isError, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 顶部图标和状态
        Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isError ? '错误' : '成功',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 消息文本
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontSize: 13,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // 移动端的布局 - 水平排列
  static Widget _buildMobileToast(String message, bool isError, ThemeData theme) {
    return Row(
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