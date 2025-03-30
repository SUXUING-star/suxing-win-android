// post_statistics_row.dart
import 'package:flutter/material.dart';

class PostStatisticsRow extends StatelessWidget {
  final int replyCount;
  final int likeCount;
  final int favoriteCount;
  final bool isSmallScreen;
  final Color? replyColor;
  final Color? likeColor;
  final Color? favoriteColor;
  final bool showLabels;

  const PostStatisticsRow({
    Key? key,
    required this.replyCount,
    required this.likeCount,
    required this.favoriteCount,
    this.isSmallScreen = false,
    this.replyColor,
    this.likeColor,
    this.favoriteColor,
    this.showLabels = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Reply count
        StatisticItem(
          icon: Icons.chat_bubble_outline,
          count: replyCount.toString(),
          color: replyColor ?? Colors.green[400]!,
          isSmallScreen: isSmallScreen,
          label: showLabels ? '回复' : null,
        ),

        SizedBox(width: isSmallScreen ? 4 : 8),

        // Like count
        StatisticItem(
          icon: Icons.thumb_up_outlined,
          count: likeCount.toString(),
          color: likeColor ?? Colors.pink[300]!,
          isSmallScreen: isSmallScreen,
          label: showLabels ? '点赞' : null,
        ),

        SizedBox(width: isSmallScreen ? 4 : 8),

        // Favorite count
        StatisticItem(
          icon: Icons.star_border,
          count: favoriteCount.toString(),
          color: favoriteColor ?? Colors.amber[400]!,
          isSmallScreen: isSmallScreen,
          label: showLabels ? '收藏' : null,
        ),
      ],
    );
  }
}

class StatisticItem extends StatelessWidget {
  final IconData icon;
  final String count;
  final Color color;
  final bool isSmallScreen;
  final String? label;

  const StatisticItem({
    Key? key,
    required this.icon,
    required this.count,
    required this.color,
    required this.isSmallScreen,
    this.label,
  }) : super(key: key);

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