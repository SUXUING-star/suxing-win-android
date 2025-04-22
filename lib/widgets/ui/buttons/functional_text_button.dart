import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';
import '../../../../utils/font/font_config.dart'; // 确认路径正确

class FunctionalTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon; // 变为可选类型 IconData?
  final double iconSize;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final bool isLoading;
  final bool isEnabled;
  final Color? customColor; // 可选的自定义颜色

  const FunctionalTextButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon, // 去掉 required，现在是可选的
    this.iconSize = 18.0,
    this.fontSize = 15.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // TextButton 通常 padding 小一些
    this.isLoading = false,
    this.isEnabled = true,
    this.customColor, // 允许传入自定义颜色
  });

  @override
  Widget build(BuildContext context) {
    // --- 确定颜色 ---
    // 优先使用 customColor，否则使用 Theme 的 primary color
    final Color effectiveColor = customColor ?? Theme.of(context).colorScheme.primary;
    // 禁用状态的颜色
    final Color disabledForegroundColor = Colors.grey.shade400;

    // --- 根据状态确定最终的前景色 ---
    final Color currentForegroundColor = isEnabled ? effectiveColor : disabledForegroundColor;

    // --- 统一处理 onPressed 回调 ---
    final VoidCallback? effectiveOnPressed = isEnabled && !isLoading ? onPressed : null;

    // --- 统一处理按钮样式 (TextButton 样式) ---
    final ButtonStyle buttonStyle = TextButton.styleFrom(
      // 主要颜色由 foregroundColor 控制
      foregroundColor: effectiveColor, // 启用时的基础文字/图标颜色
      disabledForegroundColor: disabledForegroundColor, // 禁用时的颜色
      padding: padding,
      // TextButton 通常不需要背景色，保持透明
      backgroundColor: Colors.transparent,
      disabledBackgroundColor: Colors.transparent,
      elevation: 0, // TextButton 通常没有阴影
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // 可以用小一点的圆角
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    // --- 创建 Label Widget ---
    // 确保 Text 颜色根据 isEnabled 状态变化
    final Widget labelWidget = AppText(
      label,
      style: TextStyle(
        fontFamily: FontConfig.defaultFontFamily,
        fontFamilyFallback: FontConfig.fontFallback,
        fontSize: fontSize,
        // 显式设置颜色，确保禁用时正确，且不受 styleFrom.foregroundColor 影响（虽然这里应该一致）
        color: currentForegroundColor,
        fontWeight: FontWeight.w600, // TextButton 文字可以稍粗一点以示区别
      ),
    );

    // --- 根据是否有 icon 选择不同的 Button 类型 ---
    if (icon != null) {
      // --- 有 Icon 时，使用 TextButton.icon ---
      return TextButton.icon(
        onPressed: effectiveOnPressed,
        style: buttonStyle,
        icon: isLoading
            ? SizedBox(
          width: iconSize,
          height: iconSize,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            // 加载指示器颜色也应根据状态变化
            color: currentForegroundColor,
          ),
        )
        // icon! 是安全的
            : Icon(icon!, size: iconSize, color: currentForegroundColor), // Icon 颜色也根据状态
        label: labelWidget,
      );
    } else {
      // --- 没有 Icon 时，使用 TextButton ---
      return TextButton(
        onPressed: effectiveOnPressed,
        style: buttonStyle,
        child: isLoading
            ? Row( // 加载中在文字前加个小菊花
          mainAxisSize: MainAxisSize.min,
          // 这里用 fontSize 比较合适，让菊花和文字差不多高
          children: [
            SizedBox(
              width: fontSize,
              height: fontSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: currentForegroundColor, // 菊花颜色根据状态
              ),
            ),
            const SizedBox(width: 8), // 菊花和文字间距
            labelWidget,
          ],
        )
            : labelWidget, // 不加载时只显示文字
      );
    }
  }
}