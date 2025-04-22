import 'package:flutter/material.dart';
// ControlButton 保持不变，它会接收上面计算好的颜色
class ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color iconColor;
  final Color hoverColor;
  final double iconSize;
  final String tooltip;

  const ControlButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.iconColor,
    required this.hoverColor,
    required this.iconSize,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: onPressed,
        hoverColor: hoverColor,
        child: Container(
          // 调整按钮大小和内边距以适应 titleBarHeight
          width: 45, // 稍微宽一点
          height: double.infinity, // 填充父级高度
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: iconColor,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}