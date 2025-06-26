// lib/widgets/ui/common/empty_state_widget.dart

/// 该文件定义了 EmptyStateWidget 组件，用于显示空状态提示。
/// 该组件支持消息文本、图标和操作按钮。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具

/// `EmptyStateWidget` 类：显示空状态提示的组件。
///
/// 该组件提供消息文本、图标和操作按钮。
class EmptyStateWidget extends StatelessWidget {
  final String message; // 要显示的提示信息
  final IconData? iconData; // 消息上方显示的图标
  final Widget? action; // 消息下方显示的操作组件
  final Color? iconColor; // 图标颜色
  final TextStyle? textStyle; // 文本样式
  final double? iconSize; // 图标大小

  /// 构造函数。
  ///
  /// [message]：提示信息。
  /// [iconData]：图标。
  /// [action]：操作组件。
  /// [iconColor]：图标颜色。
  /// [textStyle]：文本样式。
  /// [iconSize]：图标大小。
  const EmptyStateWidget({
    super.key,
    required this.message,
    this.iconData,
    this.action,
    this.iconColor,
    this.textStyle,
    this.iconSize,
  });

  /// 构建 EmptyStateWidget。
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color defaultIconColor =
        theme.hintColor.withSafeOpacity(0.7); // 默认图标颜色
    final TextStyle defaultTextStyle = theme.textTheme.titleMedium?.copyWith(
          color: Colors.grey[600],
          height: 1.5,
        ) ??
        const TextStyle(
            fontSize: 16, color: Colors.grey, height: 1.5); // 默认文本样式

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            if (iconData != null) // 显示图标
              Icon(
                iconData,
                size: iconSize ?? 60.0, // 使用指定或默认图标大小
                color: iconColor ?? defaultIconColor, // 使用指定或默认图标颜色
              ),

            if (iconData != null) // 图标与文本间距
              const SizedBox(height: 16.0),

            Text(
              message, // 消息文本
              textAlign: TextAlign.center, // 文本居中
              style: textStyle ?? defaultTextStyle, // 使用指定或默认文本样式
            ),

            if (action != null) // 文本与操作间距
              const SizedBox(height: 24.0),

            if (action != null) action!, // 显示操作组件
          ],
        ),
      ),
    );
  }
}
