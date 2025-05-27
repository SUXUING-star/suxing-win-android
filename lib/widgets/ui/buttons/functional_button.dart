// lib/widgets/ui/buttons/functional_button.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';

class FunctionalButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final double iconSize;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final bool isLoading;
  final bool isEnabled;
  final Color? foregroundColor; // <-- 新增: 前景色 (文字和图标)
  final Color? backgroundColor; // <-- 新增: 背景色
  final bool hasBorder;
  final double? borderWidth;
  final Color? borderColor;
  final BorderStyle? borderStyle;
  final double? minWidth; // <-- 新增: 最小宽度

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
    this.foregroundColor, // <-- 新增
    this.backgroundColor, // <-- 新增
    this.hasBorder = false,
    this.borderStyle = BorderStyle.solid,
    this.borderColor = Colors.black, // 保持默认黑色或改为主题色？看需求
    this.borderWidth = 1.0,
    this.minWidth, // <-- 新增
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // --- 确定颜色 ---
    // 前景色: 优先使用传入的，否则用主题 primary
    final Color defaultForegroundColor = theme.colorScheme.primary;
    final Color effectiveForegroundColor =
        foregroundColor ?? defaultForegroundColor;

    // 背景色: 优先使用传入的，否则用主题 primary 加透明度
    final Color defaultBackgroundColor =
        theme.colorScheme.primary.withSafeOpacity(0.15); // 原来的逻辑
    final Color effectiveBackgroundColor =
        backgroundColor ?? defaultBackgroundColor;

    // 禁用状态颜色
    final Color disabledForegroundColor = Colors.grey.shade400;
    final Color disabledBackgroundColor =
        Colors.grey.shade200.withSafeOpacity(0.5); // 比原来更透明一点

    // 当前状态颜色
    final Color currentForegroundColor =
        isEnabled ? effectiveForegroundColor : disabledForegroundColor;
    final Color currentBackgroundColor =
        isEnabled ? effectiveBackgroundColor : disabledBackgroundColor;

    // --- 统一处理 onPressed 回调 ---
    final VoidCallback? effectiveOnPressed =
        isEnabled && !isLoading ? onPressed : null;

    // --- 统一处理按钮样式 ---
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: currentBackgroundColor, // 直接使用计算好的当前背景色
      foregroundColor: currentForegroundColor, // 直接使用计算好的当前前景色 (影响文字和图标默认颜色)
      disabledForegroundColor: disabledForegroundColor, // 明确指定禁用前景色
      disabledBackgroundColor: disabledBackgroundColor, // 明确指定禁用背景色
      elevation: 0, // 保持无阴影
      padding: padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasBorder
            ? BorderSide(
                color:
                    borderColor ?? Colors.grey, // 如果 borderColor 为 null 给个默认值
                width: borderWidth ?? 1.0,
                style: borderStyle ?? BorderStyle.solid,
              )
            : BorderSide.none, // 使用 BorderSide.none 替代 null
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: minWidth != null ? Size(minWidth!, 0) : null, // 应用最小宽度
    );

    // --- 创建 Label Widget ---
    final Widget labelWidget = AppText(
      label,
      style: TextStyle(
        fontSize: fontSize,
        color: currentForegroundColor, // 显式使用当前前景色
      ),
    );

    // --- 创建 Icon Widget (如果需要) ---
    Widget? iconWidget;
    if (isLoading) {
      iconWidget = SizedBox(
        width: iconSize,
        height: iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: currentForegroundColor, // 加载指示器颜色
        ),
      );
    } else if (icon != null) {
      iconWidget =
          Icon(icon!, size: iconSize, color: currentForegroundColor); // 图标颜色
    }

    // --- 构建最终按钮 ---
    if (icon != null || (isLoading && icon == null)) {
      // 使用 ElevatedButton.icon
      return ElevatedButton.icon(
        onPressed: effectiveOnPressed,
        style: buttonStyle,
        icon: iconWidget!, // iconWidget 在此场景下必定非 null
        label: labelWidget,
      );
    } else {
      // 使用 ElevatedButton
      return ElevatedButton(
        onPressed: effectiveOnPressed,
        style: buttonStyle,
        child: labelWidget,
      );
    }
  }
}
