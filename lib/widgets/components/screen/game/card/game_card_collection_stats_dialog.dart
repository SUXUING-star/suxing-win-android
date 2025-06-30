// lib/widgets/components/screen/game/card/game_card_collection_stats_dialog.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/extension/theme/base/icon_data_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_color_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_label_extension.dart';
import 'package:suxingchahui/models/game/collection/enrich_collection_status.dart';
import 'package:suxingchahui/widgets/components/screen/game/card/game_collection_stat_row.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/models/game/game/game.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';

class GameCardCollectionStatsDialog extends StatelessWidget {
  final Game game;

  const GameCardCollectionStatsDialog({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
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
    final bool isDesktop = DeviceUtils.isDesktopScreen(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: isDesktop ? 320 : double.maxFinite,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withSafeOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                const SizedBox(width: 8),
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
            const SizedBox(height: 16),

            // 总收藏数标题
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
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
            const SizedBox(height: 16),

            // 统计行
            _buildStatRow(
              count: game.wantToPlayCount,
              percent: wantToPlayPercent,
              enrichStatus: EnrichCollectionStatus.wantToPlayCollection,
            ),
            const SizedBox(height: 12),

            _buildStatRow(
              count: game.playingCount,
              percent: playingPercent,
              enrichStatus: EnrichCollectionStatus.playingCollection,
            ),
            const SizedBox(height: 12),

            _buildStatRow(
              enrichStatus: EnrichCollectionStatus.playedCollection,
              count: game.playedCount,
              percent: playedPercent,
            ),

            const SizedBox(height: 16),

            // 关闭按钮
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.deepPurple.shade300,
                ),
                child: const Text('关闭'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 创建统计行的封装方法
  Widget _buildStatRow({
    required int count,
    required EnrichCollectionStatus enrichStatus,
    required double percent,
  }) {
    return GameCollectionStatRow(
      label: enrichStatus.textLabel,
      count: count,
      percent: percent,
      color: enrichStatus.textColor,
      icon: enrichStatus.iconData,
    );
  }
}
