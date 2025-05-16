import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';
import '../../../../utils/font/font_config.dart'; // 确认路径正确

class FunctionalTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final double iconSize;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final bool isLoading;
  final bool isEnabled;
  final Color? foregroundColor; // <-- 重命名 customColor 为 foregroundColor
  final Color? backgroundColor; // <-- 新增: 背景色 (TextButton 通常透明)
  final double? minWidth;       // <-- 新增: 最小宽度，方便布局

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
    this.foregroundColor, // <-- 使用新名称
    this.backgroundColor, // <-- 新增
    this.minWidth,       // <-- 新增
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // --- 确定前景色 ---
    // 优先使用传入的 foregroundColor，否则使用 Theme 的 primary color
    final Color effectiveForegroundColor = foregroundColor ?? theme.colorScheme.primary;
    // 禁用状态的前景色
    final Color disabledForegroundColor = Colors.grey.shade400;

    // --- 确定背景色 ---
    // 优先使用传入的 backgroundColor，否则默认为透明
    final Color effectiveBackgroundColor = backgroundColor ?? Colors.transparent;
    // 禁用状态的背景色 (通常 TextButton 禁用时也保持透明或非常淡)
    final Color disabledBackgroundColor = Colors.grey.shade200.withSafeOpacity(0.1); // 可以保持透明或给个非常淡的灰色

    // --- 根据状态确定最终颜色 ---
    final Color currentForegroundColor = isEnabled ? effectiveForegroundColor : disabledForegroundColor;
    // final Color currentBackgroundColor = isEnabled ? effectiveBackgroundColor : disabledBackgroundColor;

    // --- 统一处理 onPressed 回调 ---
    final VoidCallback? effectiveOnPressed = isEnabled && !isLoading ? onPressed : null;

    // --- 统一处理按钮样式 (TextButton 样式) ---
    final ButtonStyle buttonStyle = TextButton.styleFrom(
      foregroundColor: effectiveForegroundColor, // 启用时的基础文字/图标颜色
      backgroundColor: effectiveBackgroundColor, // 启用时的背景色
      disabledForegroundColor: disabledForegroundColor, // 禁用时的颜色
      disabledBackgroundColor: disabledBackgroundColor, // 禁用时的背景色
      padding: padding,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: minWidth != null ? Size(minWidth!, 0) : null, // 应用最小宽度
    );

    // --- 创建 Label Widget ---
    final Widget labelWidget = AppText(
      label,
      style: TextStyle(
        fontFamily: FontConfig.defaultFontFamily,
        fontFamilyFallback: FontConfig.fontFallback,
        fontSize: fontSize,
        color: currentForegroundColor, // 显式使用计算出的当前前景色
        fontWeight: FontWeight.w600,
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
          color: currentForegroundColor, // 加载指示器颜色也根据状态
        ),
      );
    } else if (icon != null) {
      iconWidget = Icon(icon!, size: iconSize, color: currentForegroundColor); // Icon 颜色也根据状态
    }

    // --- 构建最终按钮 ---
    if (icon != null || (isLoading && icon == null)) { // 有图标，或没图标但在加载
      // 使用 TextButton.icon 或模拟 icon 效果
      return TextButton.icon(
        onPressed: effectiveOnPressed,
        style: buttonStyle,
        // 如果正在加载且原本没有图标，加载指示器也放在 icon 位置
        icon: iconWidget!, // iconWidget 在此场景下必定非 null
        label: labelWidget,
      );
    } else {
      // 没图标也不在加载，使用普通 TextButton
      return TextButton(
        onPressed: effectiveOnPressed,
        style: buttonStyle,
        child: labelWidget,
      );
    }
  }
}