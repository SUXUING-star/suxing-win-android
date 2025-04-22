// lib/widgets/components/screen/gamelist/panel/game_right_panel.dart
import 'package:flutter/material.dart';
import '../../../../../models/game/game.dart';
import '../../../../../models/stats/category_stat.dart';
import '../../../../../models/stats/tag_stat.dart';
import '../../../../../services/main/game/stats/game_stats_service.dart';
import '../../../../../utils/device/device_utils.dart';

class GameRightPanel extends StatelessWidget {
  final List<Game> currentPageGames;
  final int totalGamesCount;
  final String? selectedTag;
  final Function(String)? onTagSelected;

  // 服务实例
  final GameStatsService _statsService = GameStatsService();

  GameRightPanel({
    super.key,
    required this.currentPageGames,
    required this.totalGamesCount,
    this.selectedTag,
    this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    // 获取统计数据
    final List<CategoryStat> categoryStats = _statsService.getCategoryStatistics(currentPageGames);
    final List<TagStat> tagStats = _statsService.getTagStatistics(currentPageGames);
    final int uniqueCategoriesCount = _statsService.getUniqueCategoriesCount(currentPageGames);
    final int uniqueTagsCount = _statsService.getUniqueTagsCount(currentPageGames);

    // 面板宽度
    final panelWidth = DeviceUtils.getSidePanelWidth(context);

    return Container(
      width: panelWidth,
      margin: EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: 0.8, // 透明度调整为0.7
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题栏
                Container(
                  padding: EdgeInsets.all(12),
                  color: Colors.blue,
                  child: Row(
                    children: [
                      Icon(
                        Icons.analytics,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '统计信息',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // 统计区
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(12),
                    children: [
                      _buildStatsCard(
                        context,
                        '页面摘要',
                        [
                          StatsItem('显示游戏数', '${currentPageGames.length}'),
                          StatsItem('分类数', '$uniqueCategoriesCount'),
                          StatsItem('标签数', '$uniqueTagsCount'),
                        ],
                      ),
                      SizedBox(height: 16),

                      _buildCategoriesStats(context, categoryStats),
                      SizedBox(height: 16),

                      _buildTagsStats(context, tagStats),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, String title, List<StatsItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.blue,
          ),
        ),
        SizedBox(height: 8),
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.label,
                  style: TextStyle(fontSize: 12),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.value,
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        Divider(height: 16),
      ],
    );
  }

  Widget _buildCategoriesStats(BuildContext context, List<CategoryStat> categoryStats) {
    if (categoryStats.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '分类统计',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: 8),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                '暂无分类数据',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Divider(height: 16),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '分类统计',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.blue,
          ),
        ),
        SizedBox(height: 8),
        ...categoryStats.map((category) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        category.name.isEmpty ? '(未分类)' : category.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      '${category.count}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: categoryStats[0].count > 0
                        ? category.count / categoryStats[0].count
                        : 0,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          );
        }),
        Divider(height: 16),
      ],
    );
  }

  Widget _buildTagsStats(BuildContext context, List<TagStat> tagStats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '标签统计',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.blue,
              ),
            ),
            if (selectedTag != null && onTagSelected != null)
              InkWell(
                onTap: () => onTagSelected!(selectedTag!),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, size: 12, color: Colors.blue),
                      SizedBox(width: 4),
                      Text(
                        '清除',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 8),
        tagStats.isEmpty
            ? Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              '暂无标签数据',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        )
            : Wrap(
          spacing: 6,
          runSpacing: 6,
          children: tagStats.map((stat) {
            final isSelected = selectedTag == stat.name;

            return Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: onTagSelected != null ? () => onTagSelected!(stat.name) : null,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        stat.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withOpacity(0.3) : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${stat.count}',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// 辅助类
class StatsItem {
  final String label;
  final String value;

  StatsItem(this.label, this.value);
}