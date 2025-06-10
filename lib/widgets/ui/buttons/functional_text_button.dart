// lib/widgets/ui/buttons/functional_text_button.dart

/// 该文件定义了 FunctionalTextButton 组件，一个功能强大的文本按钮。
/// 该组件支持文本、图标、加载状态、禁用状态和颜色定制。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具
import 'package:suxingchahui/widgets/ui/text/app_text.dart'; // 导入应用文本组件

/// `FunctionalTextButton` 类：一个功能强大的文本按钮组件。
///
/// 该组件提供文本、图标、加载状态、禁用状态和细粒度的颜色控制。
class FunctionalTextButton extends StatelessWidget {
  final VoidCallback? onPressed; // 按钮按下时触发的回调。加载中或为空时按钮禁用。
  final String label; // 按钮文本。
  final IconData? icon; // 按钮图标。
  final double iconSize; // 图标大小。
  final double fontSize; // 字体大小。
  final EdgeInsetsGeometry padding; // 按钮内边距。
  final bool isLoading; // 按钮是否处于加载状态。
  final bool isEnabled; // 按钮是否可用。
  final Color? foregroundColor; // 按钮前景色。
  final Color? backgroundColor; // 按钮背景色。
  final double? minWidth; // 按钮最小宽度。

  /// 构造函数。
  ///
  /// [onPressed]：点击回调。
  /// [label]：按钮文本。
  /// [icon]：图标。
  /// [iconSize]：图标大小。
  /// [fontSize]：字体大小。
  /// [padding]：内边距。
  /// [isLoading]：是否加载中。
  /// [isEnabled]：是否可用。
  /// [foregroundColor]：前景色。
  /// [backgroundColor]：背景色。
  /// [minWidth]：最小宽度。
  const FunctionalTextButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.iconSize = 18.0,
    this.fontSize = 15.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.isLoading = false,
    this.isEnabled = true,
    this.foregroundColor,
    this.backgroundColor,
    this.minWidth,
  });

  /// 构建功能文本按钮。
  ///
  /// 该方法根据按钮状态和属性生成不同的按钮内容和样式。
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context); // 获取当前主题

    final Color effectiveForegroundColor =
        foregroundColor ?? theme.colorScheme.primary; // 最终前景色
    final Color disabledForegroundColor = Colors.grey.shade400; // 禁用状态前景色

    final Color effectiveBackgroundColor =
        backgroundColor ?? Colors.transparent; // 最终背景色
    final Color disabledBackgroundColor =
        Colors.grey.shade200.withSafeOpacity(0.1); // 禁用状态背景色

    final Color currentForegroundColor =
        isEnabled ? effectiveForegroundColor : disabledForegroundColor; // 当前前景色

    final VoidCallback? effectiveOnPressed =
        isEnabled && !isLoading ? onPressed : null; // 最终点击回调

    final ButtonStyle buttonStyle = TextButton.styleFrom(
      foregroundColor: effectiveForegroundColor, // 启用时前景色
      backgroundColor: effectiveBackgroundColor, // 启用时背景色
      disabledForegroundColor: disabledForegroundColor, // 禁用时前景色
      disabledBackgroundColor: disabledBackgroundColor, // 禁用时背景色
      padding: padding, // 内边距
      elevation: 0, // 阴影高度
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // 圆角
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap, // 点击区域尺寸
      minimumSize: minWidth != null ? Size(minWidth!, 0) : null, // 最小宽度
    );

    final Widget labelWidget = AppText(
      label, // 按钮文本内容
      style: TextStyle(
        fontSize: fontSize, // 字体大小
        color: currentForegroundColor, // 字体颜色
        fontWeight: FontWeight.w600, // 字体粗细
      ),
    );

    Widget? iconWidget; // 图标组件
    if (isLoading) {
      // 处于加载状态时显示进度指示器
      iconWidget = SizedBox(
        width: iconSize, // 宽度
        height: iconSize, // 高度
        child: LoadingWidget(
          color: currentForegroundColor, // 颜色
        ),
      );
    } else if (icon != null) {
      // 存在图标时显示图标
      iconWidget =
          Icon(icon!, size: iconSize, color: currentForegroundColor); // 图标颜色
    }

    if (icon != null || isLoading) {
      // 根据是否有图标或是否加载中决定按钮类型
      return TextButton.icon(
        onPressed: effectiveOnPressed, // 点击回调
        style: buttonStyle, // 样式
        icon: iconWidget!, // 图标组件
        label: labelWidget, // 文本组件
      );
    } else {
      // 无图标且不加载时使用普通文本按钮
      return TextButton(
        onPressed: effectiveOnPressed, // 点击回调
        style: buttonStyle, // 样式
        child: labelWidget, // 文本组件
      );
    }
  }
}
