// lib/widgets/ui/buttons/warning_button.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';

class WarningButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final double iconSize;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final bool isLoading;
  final bool isEnabled;

  const WarningButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
    this.iconSize = 18.0,
    this.fontSize = 15.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    this.isLoading = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color warningColor = Colors.red.shade600;
    // --- 使用 withAlpha() 设置背景透明度 ---
    // 同样使用 0.15 opacity ≈ 38 alpha
    final int backgroundAlpha = (255 * 0.15).round();
    final Color buttonBackgroundColor = warningColor.withAlpha(backgroundAlpha);
    final Color buttonForegroundColor = warningColor; // 文字和图标保持警告色

    // 禁用状态的颜色
    final Color disabledBackgroundColor = Colors.grey.shade200.withAlpha(150);
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
          : Icon(
              icon,
              size: iconSize,
              color:
                  isEnabled ? buttonForegroundColor : disabledForegroundColor,
            ),
      label: AppText(
        label,
        style: TextStyle(
          fontSize: fontSize,
          color: isEnabled ? buttonForegroundColor : disabledForegroundColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isEnabled ? buttonBackgroundColor : disabledBackgroundColor,
        foregroundColor:
            buttonForegroundColor, // 这个会被 disabledForegroundColor 覆盖
        disabledForegroundColor: disabledForegroundColor,
        disabledBackgroundColor: disabledBackgroundColor,
        elevation: 0,
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
