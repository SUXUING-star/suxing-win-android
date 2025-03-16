// lib/widgets/components/screen/gamelist/panel/game_right_panel.dart
import 'package:flutter/material.dart';
import '../../../../../models/game/game.dart';
import '../../../../../models/stats/category_stat.dart';
import '../../../../../models/stats/tag_stat.dart';
import '../../../../../services/main/game/stats/game_stats_service.dart';
import '../../../../../utils/device/device_utils.dart';
import '../tag/tag_cloud.dart';

class GameRightPanel extends StatelessWidget {
  final List<Game> currentPageGames;
  final int totalGamesCount;
  final String? selectedTag;
  final Function(String)? onTagSelected;

  // 服务实例 - 统计逻辑放在服务层
  final GameStatsService _statsService = GameStatsService();

  GameRightPanel({
    Key? key,
    required this.currentPageGames,
    required this.totalGamesCount,
    this.selectedTag,
    this.onTagSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 从服务层获取统计数据
    final List<CategoryStat> categoryStats = _statsService.getCategoryStatistics(currentPageGames);
    final List<TagStat> tagStats = _statsService.getTagStatistics(currentPageGames);
    final int uniqueCategoriesCount = _statsService.getUniqueCategoriesCount(currentPageGames);
    final int uniqueTagsCount = _statsService.getUniqueTagsCount(currentPageGames);

    // 使用自适应宽度
    final panelWidth = DeviceUtils.getSidePanelWidth(context);
    final isCompact = panelWidth < 220; // 当面板宽度较小时使用紧凑模式

    return Container(
      width: panelWidth,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1.0,
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 6.0 : 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPageSummary(context, uniqueCategoriesCount, uniqueTagsCount, isCompact),
              SizedBox(height: isCompact ? 8 : 12),
              _buildCategoriesPanel(context, categoryStats, isCompact),
              SizedBox(height: isCompact ? 8 : 12),
              _buildTagsPanel(context, tagStats, isCompact),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageSummary(BuildContext context, int categoriesCount, int tagsCount, bool isCompact) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 8.0 : 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前页面摘要',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isCompact ? 14 : null,
              ),
            ),
            SizedBox(height: isCompact ? 6 : 8),
            _buildInfoRow('显示游戏数', '${currentPageGames.length}'),
            Divider(height: 16),
            _buildInfoRow('分类数', '$categoriesCount'),
            Divider(height: 16),
            _buildInfoRow('标签数', '$tagsCount'),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesPanel(BuildContext context, List<CategoryStat> categoryStats, bool isCompact) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 8.0 : 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前页面分类',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isCompact ? 14 : null,
              ),
            ),
            SizedBox(height: isCompact ? 6 : 8),
            categoryStats.isEmpty
                ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('无分类数据'),
            )
                : ListView.separated(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: categoryStats.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final category = categoryStats[index];
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: isCompact ? 6.0 : 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          category.name.isEmpty ? '(未分类)' : category.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: isCompact ? 12 : 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 6 : 8,
                            vertical: isCompact ? 1 : 2
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${category.count}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isCompact ? 10 : 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsPanel(BuildContext context, List<TagStat> tagStats, bool isCompact) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 8.0 : 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '当前页面标签',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isCompact ? 14 : null,
                  ),
                ),
                if (selectedTag != null && onTagSelected != null)
                  IconButton(
                    icon: Icon(Icons.clear, size: isCompact ? 16 : 18),
                    onPressed: () => onTagSelected!(selectedTag!),
                    tooltip: '清除筛选',
                    constraints: BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            SizedBox(height: isCompact ? 6 : 8),
            tagStats.isEmpty
                ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('无标签数据'),
            )
                : StatTagCloud(
              tags: tagStats,
              selectedTag: selectedTag,
              onTagSelected: onTagSelected,
              compact: isCompact,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}