// post_statistics_row.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/components/screen/forum/card/post_statistic_item.dart';

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

