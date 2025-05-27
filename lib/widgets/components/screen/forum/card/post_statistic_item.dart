// lib/widgets/components/screen/forum/card/post_statistic_item.dart
import 'package:flutter/material.dart';
class StatisticItem extends StatelessWidget {
  final IconData icon;
  final String count;
  final Color color;
  final bool isSmallScreen;
  final String? label;

  const StatisticItem({
    super.key,
    required this.icon,
    required this.count,
    required this.color,
    required this.isSmallScreen,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final double iconSize = isSmallScreen ? 14 : 16;
    final double fontSize = isSmallScreen ? 12 : 13;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: color,
        ),
        SizedBox(width: 2),
        Text(
          count,
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.grey[700],
          ),
        ),
        if (label != null) ...[
          SizedBox(width: 2),
          Text(
            label!,
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.grey[700],
            ),
          ),
        ],
      ],
    );
  }
}