import 'package:flutter/material.dart';
import '../../../../utils/font/font_config.dart'; // 确认路径正确

class FunctionalButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final double iconSize;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final bool isLoading;
  final bool isEnabled;

  const FunctionalButton({
    Key? key,
    required this.onPressed,
    required this.label,
    required this.icon,
    this.iconSize = 18.0,
    this.fontSize = 15.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    this.isLoading = false,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    // --- 使用 withAlpha() 设置背景透明度 ---
    // 0.15 opacity ≈ 38 alpha (0-255)
    final int backgroundAlpha = (255 * 0.15).round();
    final Color buttonBackgroundColor = primaryColor.withAlpha(backgroundAlpha);
    final Color buttonForegroundColor = primaryColor; // 文字和图标保持原色

    // 禁用状态的颜色（可以保持之前的灰色或也用带alpha的灰色）
    final Color disabledBackgroundColor = Colors.grey.shade200.withAlpha(150); // 例如：半透明灰色
    final Color disabledForegroundColor = Colors.grey.shade400;

    return ElevatedButton.icon(
      onPressed: isEnabled && !isLoading ? onPressed : null,
      icon: isLoading
          ? SizedBox(
        width: iconSize,
        height: iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: buttonForegroundColor,
        ),
      )
          : Icon(icon, size: iconSize, color: isEnabled ? buttonForegroundColor : disabledForegroundColor),
      label: Text(
        label,
        style: TextStyle(
          fontFamily: FontConfig.defaultFontFamily,
          fontFamilyFallback: FontConfig.fontFallback,
          fontSize: fontSize,
          color: isEnabled ? buttonForegroundColor : disabledForegroundColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled ? buttonBackgroundColor : disabledBackgroundColor,
        foregroundColor: buttonForegroundColor, // 这个会被 disabledForegroundColor 覆盖
        disabledForegroundColor: disabledForegroundColor,
        disabledBackgroundColor: disabledBackgroundColor,
        elevation: 0,
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        // (可选) 点击效果
        // overlayColor: MaterialStateProperty.resolveWith<Color?>(
        //   (Set<MaterialState> states) {
        //     if (states.contains(MaterialState.pressed)) {
        //        // 按下时可以用更深的 alpha 或不同颜色
        //       return primaryColor.withAlpha((255 * 0.25).round());
        //     }
        //     return null;
        //   },
        // ),
      ),
    );
  }
}