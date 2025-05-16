// 3. game_stats_widget.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import '../../../../../models/game/game.dart';
import 'stat_item_widget.dart';

class GameStatsWidget extends StatelessWidget {
  final Game game;
  final bool showCollectionStats;
  final bool isGrid;

  const GameStatsWidget({
    super.key,
    required this.game,
    required this.showCollectionStats,
    required this.isGrid,
  });

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return _buildStatsContainer(context);
    } else {
      return _buildStatsRow(context);
    }
  }

  // 构建统计信息行 - 列表布局
  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        // 点赞数
        StatItemWidget(
          icon: Icons.thumb_up,
          value: game.likeCount.toString(),
          color: Colors.pink.shade200,
          iconSize: 14,
          fontSize: 12,
          showBackground: false,
        ),

        SizedBox(width: 12),

        // 查看数
        StatItemWidget(
          icon: Icons.remove_red_eye_outlined,
          value: game.viewCount.toString(),
          color: Colors.lightBlue.shade300,
          iconSize: 14,
          fontSize: 12,
          showBackground: false,
        ),

        // 添加收藏统计（如果开启）
        if (showCollectionStats && game.totalCollections > 0) ...[
          SizedBox(width: 12),
          StatItemWidget(
            icon: Icons.bookmark,
            value: game.totalCollections.toString(),
            color: Colors.lightGreen.shade400,
            iconSize: 14,
            fontSize: 12,
            showBackground: false,
          ),
          if (showCollectionStats && game.rating >0)...[
            SizedBox(width: 12),
            StatItemWidget(
              icon: Icons.star,
              value: game.rating.toString(),
              color: Colors.lightGreen.shade400,
              iconSize: 14,
              fontSize: 12,
              showBackground: false,
            ),
          ]
        ],
      ],
    );
  }

  // 网格布局的底部统计信息容器
  Widget _buildStatsContainer(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withSafeOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 点赞数
          StatItemWidget(
            icon: Icons.thumb_up,
            value: game.likeCount.toString(),
            color: Colors.pink.shade300,
            iconSize: 10,
            fontSize: 10,
            showBackground: true,
          ),

          SizedBox(width: 8),

          // 查看数
          StatItemWidget(
            icon: Icons.remove_red_eye_outlined,
            value: game.viewCount.toString(),
            color: Colors.lightBlue.shade400,
            iconSize: 10,
            fontSize: 10,
            showBackground: true,
          ),

          // 添加收藏统计（如果开启）
          if (showCollectionStats && game.totalCollections > 0) ...[
            SizedBox(width: 6),
            StatItemWidget(
              icon: Icons.bookmark,
              value: game.totalCollections.toString(),
              color: Colors.lightGreen.shade500,
              iconSize: 10,
              fontSize: 10,
              showBackground: true,
            ),

          ],

        ],
      ),
    );
  }
}