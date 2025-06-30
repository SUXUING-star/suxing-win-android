// lib/widgets/components/screen/game/card/game_stats_widget.dart

/// 该文件定义了 GameStatsWidget 组件，一个用于显示游戏统计数据的 StatelessWidget。
/// GameStatsWidget 根据布局模式（网格或列表）展示游戏的点赞、查看和收藏统计信息。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具
import 'package:suxingchahui/models/game/game/game.dart'; // 导入游戏模型
import 'game_stat_item_widget.dart'; // 导入统计项组件

/// `GameStatsWidget` 类：显示游戏统计数据的组件。
///
/// 该组件根据是否为网格布局，展示不同样式的点赞数、查看数和收藏数（可选）。
class GameStatsWidget extends StatelessWidget {
  final Game game; // 游戏数据
  final bool showCollectionStats; // 是否显示收藏统计
  final bool isGrid; // 是否为网格布局

  /// 构造函数。
  ///
  /// [game]：游戏数据。
  /// [showCollectionStats]：是否显示收藏统计。
  /// [isGrid]：是否网格布局。
  const GameStatsWidget({
    super.key,
    required this.game,
    required this.showCollectionStats,
    required this.isGrid,
  });

  /// 构建游戏统计数据组件。
  ///
  /// 根据 [isGrid] 参数选择构建网格布局或列表布局样式。
  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      // 网格布局
      return _buildStatsContainer(context); // 构建统计信息容器
    } else {
      // 列表布局
      return _buildStatsRow(context); // 构建统计信息行
    }
  }

  /// 构建统计信息行（列表布局）。
  ///
  /// [context]：Build 上下文。
  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        StatItemWidget(
          icon: Icons.thumb_up, // 点赞图标
          value: game.likeCount.toString(), // 点赞数
          color: Colors.pink.shade200, // 颜色
          iconSize: 14, // 图标大小
          fontSize: 12, // 字体大小
          showBackground: false, // 不显示背景
        ),

        const SizedBox(width: 12), // 间距

        if (game.coinsCount > 0) ...[
          StatItemWidget(
            icon: Icons.monetization_on, // 投币图标
            value: game.coinsCount.toString(), // 投币数
            color: Colors.orange.shade400, // 颜色
            iconSize: 14,
            fontSize: 12,
            showBackground: false,
          ),
          const SizedBox(width: 12),
        ],

        StatItemWidget(
          icon: Icons.remove_red_eye_outlined, // 查看图标
          value: game.viewCount.toString(), // 查看数
          color: Colors.lightBlue.shade300, // 颜色
          iconSize: 14, // 图标大小
          fontSize: 12, // 字体大小
          showBackground: false, // 不显示背景
        ),

        if (showCollectionStats && game.totalCollections > 0) ...[
          // 显示收藏统计
          const SizedBox(width: 12), // 间距
          StatItemWidget(
            icon: Icons.bookmark, // 收藏图标
            value: game.totalCollections.toString(), // 收藏数
            color: Colors.lightGreen.shade400, // 颜色
            iconSize: 14, // 图标大小
            fontSize: 12, // 字体大小
            showBackground: false, // 不显示背景
          ),
          if (showCollectionStats && game.rating > 0) ...[
            // 显示评分
            const SizedBox(width: 12), // 间距
            StatItemWidget(
              icon: Icons.star, // 星星图标
              value: game.rating.toString(), // 评分
              color: Colors.lightGreen.shade400, // 颜色
              iconSize: 14, // 图标大小
              fontSize: 12, // 字体大小
              showBackground: false, // 不显示背景
            ),
          ]
        ],
      ],
    );
  }

  /// 构建统计信息容器（网格布局）。
  ///
  /// [context]：Build 上下文。
  Widget _buildStatsContainer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 内边距
      decoration: BoxDecoration(
        color: Colors.white.withSafeOpacity(0.85), // 背景色
        borderRadius: BorderRadius.circular(12), // 圆角
        border: Border.all(color: Colors.grey.shade300, width: 0.5), // 边框
        boxShadow: [
          // 阴影
          const BoxShadow(
            color: Colors.black12,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // 行主轴尺寸最小化
        children: [
          StatItemWidget(
            icon: Icons.thumb_up, // 点赞图标
            value: game.likeCount.toString(), // 点赞数
            color: Colors.pink.shade300, // 颜色
            iconSize: 10, // 图标大小
            fontSize: 10, // 字体大小
            showBackground: true, // 显示背景
          ),

          const SizedBox(width: 8), // 间距

          // --- 投币统计 ---
          if (game.coinsCount > 0) ...[
            StatItemWidget(
              icon: Icons.monetization_on, // 投币图标
              value: game.coinsCount.toString(), // 投币数
              color: Colors.orange.shade500, // 颜色
              iconSize: 10,
              fontSize: 10,
              showBackground: true,
            ),
            const SizedBox(width: 8),
          ],

          StatItemWidget(
            icon: Icons.remove_red_eye_outlined, // 查看图标
            value: game.viewCount.toString(), // 查看数
            color: Colors.lightBlue.shade400, // 颜色
            iconSize: 10, // 图标大小
            fontSize: 10, // 字体大小
            showBackground: true, // 显示背景
          ),

          if (showCollectionStats && game.totalCollections > 0) ...[
            // 显示收藏统计
            const SizedBox(width: 6), // 间距
            StatItemWidget(
              icon: Icons.bookmark, // 收藏图标
              value: game.totalCollections.toString(), // 收藏数
              color: Colors.lightGreen.shade500, // 颜色
              iconSize: 10, // 图标大小
              fontSize: 10, // 字体大小
              showBackground: true, // 显示背景
            ),
          ],
        ],
      ),
    );
  }
}
