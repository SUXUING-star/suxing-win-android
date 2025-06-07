// lib/widgets/components/screen/game/card/game_collection_dialog.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/game/game_constants.dart';
import 'package:suxingchahui/widgets/components/screen/game/card/game_collection_stat_row.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';

class GameCollectionDialog extends StatelessWidget {
  final Game game;

  const GameCollectionDialog({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    // 从统一的工具类获取主题
    final wantTheme = GameCollectionStatusUtils.wantToPlayTheme;
    final playingTheme = GameCollectionStatusUtils.playingTheme;
    final playedTheme = GameCollectionStatusUtils.playedTheme;

    // 计算总收藏数
    final int total = game.totalCollections;

    // 计算百分比值（避免除零错误）
    final double wantToPlayPercent =
    total > 0 ? (game.wantToPlayCount / total) * 100 : 0;
    final double playingPercent =
    total > 0 ? (game.playingCount / total) * 100 : 0;
    final double playedPercent =
    total > 0 ? (game.playedCount / total) * 100 : 0;

    // 检查是否是桌面端
    final bool isDesktop = DeviceUtils.isDesktop;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: isDesktop ? 320 : double.maxFinite,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withSafeOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Row(
              children: [
                Icon(Icons.bookmark, color: Colors.deepPurple.shade300),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '《${game.title}》收藏统计',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // 总收藏数标题
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '总收藏数: ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${game.totalCollections}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade300,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // 统计行
            _buildStatRow(
              label: wantTheme.text,
              count: game.wantToPlayCount,
              percent: wantToPlayPercent,
              color: wantTheme.textColor,
              icon: wantTheme.icon,
            ),
            SizedBox(height: 12),

            _buildStatRow(
              label: playingTheme.text,
              count: game.playingCount,
              percent: playingPercent,
              color: playingTheme.textColor,
              icon: playingTheme.icon,
            ),
            SizedBox(height: 12),

            _buildStatRow(
              label: playedTheme.text,
              count: game.playedCount,
              percent: playedPercent,
              color: playedTheme.textColor,
              icon: playedTheme.icon,
            ),

            SizedBox(height: 16),

            // 关闭按钮
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.deepPurple.shade300,
                ),
                child: Text('关闭'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 创建统计行的封装方法
  Widget _buildStatRow({
    required String label,
    required int count,
    required double percent,
    required Color color,
    required IconData icon,
  }) {
    return GameCollectionStatRow(
      label: label,
      count: count,
      percent: percent,
      color: color,
      icon: icon,
    );
  }
}

// 显示游戏收藏对话框的便捷函数
void showGameCollectionDialog(BuildContext context, Game game) {
  showDialog(
    context: context,
    builder: (BuildContext context) => GameCollectionDialog(game: game),
  );
}
