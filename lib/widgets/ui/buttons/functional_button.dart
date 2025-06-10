// lib/widgets/ui/buttons/functional_button.dart

/// 该文件定义了 FunctionalButton 组件，一个可定制的功能按钮。
/// 该组件支持文本、图标、加载状态、禁用状态和多种样式。
library;


import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具
import 'package:suxingchahui/widgets/ui/text/app_text.dart'; // 导入应用文本组件

/// `FunctionalButton` 类：一个可定制的功能按钮组件。
///
/// 该组件提供文本、图标、加载状态、禁用状态和多种样式选项。
class FunctionalButton extends StatelessWidget {
  final VoidCallback? onPressed; // 按钮点击回调
  final String label; // 按钮文本
  final IconData? icon; // 按钮图标
  final double iconSize; // 图标大小
  final double fontSize; // 字体大小
  final EdgeInsetsGeometry padding; // 按钮内边距
  final bool isLoading; // 按钮是否处于加载状态
  final bool isEnabled; // 按钮是否可用
  final Color? foregroundColor; // 按钮前景色
  final Color? backgroundColor; // 按钮背景色
  final bool hasBorder; // 按钮是否显示边框
  final double? borderWidth; // 边框宽度
  final Color? borderColor; // 边框颜色
  final BorderStyle? borderStyle; // 边框样式
  final double? minWidth; // 按钮最小宽度

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
  /// [hasBorder]：是否有边框。
  /// [borderWidth]：边框宽度。
  /// [borderColor]：边框颜色。
  /// [borderStyle]：边框样式。
  /// [minWidth]：最小宽度。
  const FunctionalButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.iconSize = 18.0,
    this.fontSize = 15.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    this.isLoading = false,
    this.isEnabled = true,
    this.foregroundColor,
    this.backgroundColor,
    this.hasBorder = false,
    this.borderStyle = BorderStyle.solid,
    this.borderColor = Colors.black,
    this.borderWidth = 1.0,
    this.minWidth,
  });

  /// 构建功能按钮。
  ///
  /// 该方法根据按钮状态和属性生成不同的按钮样式。
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context); // 获取当前主题

    final Color defaultForegroundColor = theme.colorScheme.primary; // 默认前景色
    final Color effectiveForegroundColor =
        foregroundColor ?? defaultForegroundColor; // 最终前景色

    final Color defaultBackgroundColor =
        theme.colorScheme.primary.withSafeOpacity(0.15); // 默认背景色
    final Color effectiveBackgroundColor =
        backgroundColor ?? defaultBackgroundColor; // 最终背景色

    final Color disabledForegroundColor = Colors.grey.shade400; // 禁用状态前景色
    final Color disabledBackgroundColor =
        Colors.grey.shade200.withSafeOpacity(0.5); // 禁用状态背景色

    final Color currentForegroundColor =
        isEnabled ? effectiveForegroundColor : disabledForegroundColor; // 当前前景色
    final Color currentBackgroundColor =
        isEnabled ? effectiveBackgroundColor : disabledBackgroundColor; // 当前背景色

    final VoidCallback? effectiveOnPressed =
        isEnabled && !isLoading ? onPressed : null; // 最终点击回调

    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: currentBackgroundColor, // 按钮背景色
      foregroundColor: currentForegroundColor, // 按钮前景色
      disabledForegroundColor: disabledForegroundColor, // 禁用前景色
      disabledBackgroundColor: disabledBackgroundColor, // 禁用背景色
      elevation: 0, // 按钮阴影
      padding: padding, // 按钮内边距
      shape: RoundedRectangleBorder(
        // 按钮形状
        borderRadius: BorderRadius.circular(12), // 按钮圆角
        side: hasBorder
            ? BorderSide(
                // 边框样式
                color: borderColor ?? Colors.grey, // 边框颜色
                width: borderWidth ?? 1.0, // 边框宽度
                style: borderStyle ?? BorderStyle.solid, // 边框样式
              )
            : BorderSide.none, // 无边框
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap, // 点击区域尺寸
      minimumSize: minWidth != null ? Size(minWidth!, 0) : null, // 最小宽度
    );

    final Widget labelWidget = AppText(
      label, // 按钮文本内容
      style: TextStyle(
        fontSize: fontSize, // 字体大小
        color: currentForegroundColor, // 字体颜色
      ),
    );

    Widget? iconWidget; // 图标组件
    if (isLoading) {
      // 处于加载状态
      iconWidget = SizedBox(
        width: iconSize, // 宽度
        height: iconSize, // 高度
        child: const LoadingWidget(),
      );
    } else if (icon != null) {
      // 存在图标
      iconWidget =
          Icon(icon!, size: iconSize, color: currentForegroundColor); // 图标颜色
    }

    if (icon != null || (isLoading && icon == null)) {
      // 根据是否有图标或加载状态决定按钮类型
      return ElevatedButton.icon(
        onPressed: effectiveOnPressed, // 点击回调
        style: buttonStyle, // 按钮样式
        icon: iconWidget!, // 图标组件
        label: labelWidget, // 文本组件
      );
    } else {
      // 无图标的普通按钮
      return ElevatedButton(
        onPressed: effectiveOnPressed, // 点击回调
        style: buttonStyle, // 按钮样式
        child: labelWidget, // 文本组件
      );
    }
  }
}
