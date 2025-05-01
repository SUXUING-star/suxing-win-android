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
  final Function(String?)? onTagSelected;
  final String? selectedCategory;
  final Function(String?)? onCategorySelected;

  // 服务实例
  final GameStatsService _statsService = GameStatsService();

  // <<< Added: List of all available categories >>>
  final List<String> availableCategories;

  GameRightPanel({
    super.key,
    required this.currentPageGames,
    required this.totalGamesCount,
    this.selectedTag,
    this.onTagSelected,
    // <<< Added parameters >>>
    required this.availableCategories,
    this.selectedCategory,
    this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    // 获取当前页的统计数据
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
          opacity: 0.8, // 透明度调整
          child: Container(
            color: Theme.of(context).cardColor, // Use card color
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题栏
                Container(
                  padding: EdgeInsets.all(12),
                  color: Theme.of(context).primaryColor, // Use theme primary color
                  child: Row(
                    children: [
                      Icon(
                        Icons.analytics,
                        color: Theme.of(context).colorScheme.onPrimary, // Use onPrimary color
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '统计信息', // Updated title
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary, // Use onPrimary color
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
                        '页面摘要 (当前页)', // Clarified scope
                        [
                          StatsItem('显示游戏数', '${currentPageGames.length}'),
                          // Changed to show total count under current filter
                          StatsItem('总游戏数', '$totalGamesCount'),
                          StatsItem('分类数 (当前页)', '$uniqueCategoriesCount'), // Clarified scope
                          StatsItem('标签数 (当前页)', '$uniqueTagsCount'), // Clarified scope
                        ],
                      ),
                      SizedBox(height: 16),

                      // <<< Added: Category Filter Section >>>
                      _buildCategoryFilter(context),
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

  // <<< New: Build Category Filter Section >>>
  Widget _buildCategoryFilter(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '分类筛选',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: theme.primaryColor,
              ),
            ),
            // <<< Added: Clear Category Button >>>
            if (selectedCategory != null && onCategorySelected != null)
              InkWell(
                onTap: () => onCategorySelected!(null), // Pass null to clear
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, size: 12, color: theme.primaryColor),
                      SizedBox(width: 4),
                      Text(
                        '清除',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 8),
        availableCategories.isEmpty
            ? Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              '暂无可用分类',
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
          children: [
            // Option to view "All" (no category filter)
            _buildFilterChip(
              context: context,
              label: '全部',
              value: null,
              isSelected: selectedCategory == null,
              onSelected: onCategorySelected,
            ),
            // List available categories
            ...availableCategories.map((category) {
              return _buildFilterChip(
                context: context,
                label: category,
                value: category,
                isSelected: selectedCategory == category,
                onSelected: onCategorySelected,
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  // <<< New: Helper to build filter chips >>>
  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required String? value,
    required bool isSelected,
    required Function(String?)? onSelected,
  }) {
    final theme = Theme.of(context);
    // Get count for this category *within the current page* for display
    // This is just for display stats, the filter applies globally
    final categoryStat = _statsService.getCategoryStatistics(currentPageGames).firstWhere(
          (stat) => stat.name == (value ?? ''), // Use '' for null category name
      orElse: () => CategoryStat(name: value ?? '', count: 0),
    );
    final displayCount = categoryStat.count;


    return InkWell(
      onTap: onSelected != null ? () => onSelected(value) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? null : Border.all(color: theme.primaryColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? theme.colorScheme.onPrimary : theme.primaryColor,
                fontSize: 12,
              ),
            ),
            if (displayCount > 0) ...[ // Only show count if > 0 in current page
              SizedBox(width: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.onPrimary.withOpacity(0.3) : theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$displayCount',
                  style: TextStyle(
                    color: isSelected ? theme.colorScheme.onPrimary : theme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }


  // Kept existing methods, modified _buildTagsStats slightly to match new chip style
  Widget _buildStatsCard(BuildContext context, String title, List<StatsItem> items) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: theme.primaryColor,
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
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.value,
                    style: TextStyle(
                      color: theme.primaryColor,
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
    final theme = Theme.of(context);
    if (categoryStats.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '分类统计 (当前页)', // Clarified scope
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: theme.primaryColor,
            ),
          ),
          SizedBox(height: 8),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                '暂无分类数据 (当前页)',
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

    // Sort stats by count descending for better display
    categoryStats.sort((a, b) => b.count.compareTo(a.count));
    final maxCount = categoryStats.isNotEmpty ? categoryStats.first.count : 1; // Avoid division by zero

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '分类统计 (当前页)', // Clarified scope
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: theme.primaryColor,
          ),
        ),
        SizedBox(height: 8),
        ...categoryStats.map((category) {
          // Don't show empty categories from stats if they exist
          if (category.count == 0 && category.name.isEmpty) return SizedBox.shrink();
          final displayName = category.name.isEmpty ? '(未分类)' : category.name;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded( // Use Expanded to prevent overflow if name is long
                      child: Text(
                        displayName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      '${category.count}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: maxCount > 0 ? category.count / maxCount : 0,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        Divider(height: 16),
      ],
    );
  }

  Widget _buildTagsStats(BuildContext context, List<TagStat> tagStats) {
    final theme = Theme.of(context);
    // Sort stats by count descending
    tagStats.sort((a, b) => b.count.compareTo(a.count));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '标签统计 (当前页)', // Clarified scope
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: theme.primaryColor,
              ),
            ),
            // This button clears the *global* tag filter, not just the current page stats
            if (selectedTag != null && onTagSelected != null)
              InkWell(
                onTap: () => onTagSelected!(null), // Pass null to clear
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, size: 12, color: theme.primaryColor),
                      SizedBox(width: 4),
                      Text(
                        '清除',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.primaryColor,
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
              '暂无标签数据 (当前页)',
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

            return InkWell(
              onTap: onTagSelected != null ? () => onTagSelected!(stat.name) : null,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? theme.primaryColor : theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected ? null : Border.all(color: theme.primaryColor.withOpacity(0.3)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        stat.name,
                        style: TextStyle(
                          color: isSelected ? theme.colorScheme.onPrimary : theme.primaryColor,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected ? theme.colorScheme.onPrimary.withOpacity(0.3) : theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${stat.count}',
                          style: TextStyle(
                            color: isSelected ? theme.colorScheme.onPrimary : theme.primaryColor,
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