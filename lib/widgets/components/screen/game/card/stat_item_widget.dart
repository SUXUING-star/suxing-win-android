// 4. stat_item_widget.dart
import 'package:flutter/material.dart';

class StatItemWidget extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  final double iconSize;
  final double fontSize;
  final bool showBackground;

  const StatItemWidget({
    Key? key,
    required this.icon,
    required this.value,
    required this.color,
    required this.iconSize,
    required this.fontSize,
    required this.showBackground,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 网格布局中的显示样式
    if (showBackground) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: color,
            ),
          ),
          SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }
    // 列表布局中的显示样式
    else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: color,
            ),
          ),
          SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
  }
}