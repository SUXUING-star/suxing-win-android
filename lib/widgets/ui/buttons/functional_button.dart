import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';
import '../../../../utils/font/font_config.dart'; // 确认路径正确

class FunctionalButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData? icon; // 变为可选类型 IconData?
  final double iconSize;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final bool isLoading;
  final bool isEnabled;
  final bool hasBorder;
  final double? borderWidth;
  final Color? borderColor;
  final BorderStyle? borderStyle;

  const FunctionalButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon, // 去掉 required，现在是可选的
    this.iconSize = 18.0,
    this.fontSize = 15.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    this.isLoading = false,
    this.isEnabled = true,
    this.hasBorder = false,
    this.borderStyle = BorderStyle.solid,
    this.borderColor = Colors.black,
    this.borderWidth = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final int backgroundAlpha = (255 * 0.15).round();
    final Color buttonBackgroundColor = primaryColor.withAlpha(backgroundAlpha);
    final Color buttonForegroundColor = primaryColor;

    final Color disabledBackgroundColor = Colors.grey.shade200.withAlpha(150);
    final Color disabledForegroundColor = Colors.grey.shade400;

    // --- 统一处理 onPressed 回调 ---
    final VoidCallback? effectiveOnPressed =
        isEnabled && !isLoading ? onPressed : null;

    // --- 统一处理按钮样式 ---
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      backgroundColor:
          isEnabled ? buttonBackgroundColor : disabledBackgroundColor,
      foregroundColor: isEnabled
          ? buttonForegroundColor
          : disabledForegroundColor, // foregroundColor 会影响 Text 和 Icon (如果未单独设置颜色)
      disabledForegroundColor: disabledForegroundColor,
      disabledBackgroundColor: disabledBackgroundColor,
      elevation: 0,
      padding: padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),

      side: hasBorder
          ? BorderSide(
              width: 1,
              color: Colors.black,
              style: BorderStyle.solid,
            )
          : null,
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
        // 这里显式设置颜色，确保禁用时颜色正确，不受 foregroundColor 影响
        color: isEnabled ? buttonForegroundColor : disabledForegroundColor,
        fontWeight: FontWeight.w600,
      ),
    );

    // --- 根据是否有 icon 选择不同的 Button 类型 ---
    if (icon != null) {
      // --- 有 Icon 时，使用 ElevatedButton.icon ---
      return ElevatedButton.icon(
        onPressed: effectiveOnPressed,
        icon: isLoading
            ? SizedBox(
                width: iconSize,
                height: iconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  // 加载指示器颜色也应根据状态变化
                  color: isEnabled
                      ? buttonForegroundColor
                      : disabledForegroundColor,
                ),
              )
            // icon! 是安全的，因为我们已经检查过 icon != null
            : Icon(icon!,
                size: iconSize,
                color: isEnabled
                    ? buttonForegroundColor
                    : disabledForegroundColor),
        label: labelWidget,
        style: buttonStyle,
      );
    } else {
      // --- 没有 Icon 时，使用 ElevatedButton ---
      return ElevatedButton(
        onPressed: effectiveOnPressed,
        style: buttonStyle,
        child: isLoading
            ? Row(
                // 如果需要在没有图标时，加载中也显示指示器
                mainAxisSize: MainAxisSize.min, // 让 Row 包裹内容
                children: [
                  SizedBox(
                    // 让加载指示器大小和文字差不多
                    width: fontSize,
                    height: fontSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isEnabled
                          ? buttonForegroundColor
                          : disabledForegroundColor,
                    ),
                  ),
                  const SizedBox(width: 8), // 指示器和文字之间的间距
                  labelWidget,
                ],
              )
            : labelWidget, // 不加载时只显示文字
      );
    }
  }
}
