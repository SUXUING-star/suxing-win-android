// lib/widgets/components/screen/gamelist/panel/game_right_panel.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/components/game/game_tag.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/constants/game/game_constants.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/stats/category_stat.dart';
import 'package:suxingchahui/models/stats/tag_stat.dart';
import 'package:suxingchahui/services/main/game/stats/game_stats_service.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';

class GameRightPanel extends StatelessWidget {
  final List<Game> currentPageGames;
  final int totalGamesCount;
  final String? selectedTag;
  final Function(String?)? onTagSelected;
  final String? selectedCategory;
  final Function(String?)? onCategorySelected;
  final List<String> availableCategories; // 所有可用分类列表

  const GameRightPanel({
    super.key,
    required this.currentPageGames,
    required this.totalGamesCount,
    required this.availableCategories, // 确保传入
    this.selectedTag,
    this.onTagSelected,
    this.selectedCategory,
    this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    // 获取当前页的统计数据
    final List<CategoryStat> categoryStats =
        GameStatsService.getCategoryStatistics(currentPageGames);
    final List<TagStat> tagStats =
        GameStatsService.getTagStatistics(currentPageGames);
    final int uniqueCategoriesCount =
        GameStatsService.getUniqueCategoriesCount(currentPageGames);
    final int uniqueTagsCount =
        GameStatsService.getUniqueTagsCount(currentPageGames);

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
            color: Theme.of(context).cardColor, // 使用卡片颜色
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题栏
                Container(
                  padding: EdgeInsets.all(12),
                  color: Theme.of(context).primaryColor, // 使用主题主色
                  child: Row(
                    children: [
                      Icon(
                        Icons.analytics,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary, // 使用 onPrimary 颜色
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '统计信息',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary, // 使用 onPrimary 颜色
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
                        '页面摘要 (当前页)',
                        [
                          StatsItem('显示游戏数', '${currentPageGames.length}'),
                          StatsItem('总游戏数', '$totalGamesCount'),
                          StatsItem('分类数 (当前页)', '$uniqueCategoriesCount'),
                          StatsItem('标签数 (当前页)', '$uniqueTagsCount'),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildCategoryFilter(
                          context), // 分类筛选区域 (使用修改后的 _buildFilterChip)
                      SizedBox(height: 16),
                      _buildCategoriesStats(
                          context, categoryStats), // 分类统计条形图 (样式不变)
                      SizedBox(height: 16),
                      _buildTagsStats(context, tagStats), // 标签统计 (使用 GameTag)
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

  // 分类筛选区域构建方法 (内部调用修改后的 _buildFilterChip)
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
                color: theme.primaryColor, // 标题颜色用主色
              ),
            ),
            // 清除分类按钮
            if (selectedCategory != null && onCategorySelected != null)
              InkWell(
                onTap: () => onCategorySelected!(null), // 传递 null 清除
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    // 清除按钮样式保持和标签清除一致
                    color: theme.primaryColor.withSafeOpacity(0.1),
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
                // 无可用分类提示
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
                // 使用 Wrap 排列 FilterChip
                spacing: 8, // 调整间距
                runSpacing: 8,
                children: [
                  // "全部" 选项
                  _buildFilterChip(
                    context: context,
                    label: '全部',
                    value: null, // value 为 null 代表 "全部"
                    isSelected: selectedCategory == null,
                    onSelected: onCategorySelected,
                  ),
                  // 遍历所有可用分类
                  ...availableCategories.map((category) {
                    return _buildFilterChip(
                      context: context,
                      label: category,
                      value: category,
                      isSelected: selectedCategory == category,
                      onSelected: onCategorySelected,
                    );
                  }),
                ],
              ),
        Divider(height: 24), // 加个分隔线
      ],
    );
  }

  // --- 重点修改了这个方法 ---
  // 构建单个分类筛选 Chip 的辅助方法
  Widget _buildFilterChip({
    required BuildContext context,
    required String label, // 显示的文字 ('全部', '汉化', '生肉')
    required String? value, // 对应的分类值 (null 代表 '全部')
    required bool isSelected,
    required Function(String?)? onSelected,
  }) {
    // final theme = Theme.of(context);

    // 1. --- 获取分类的基础颜色 ---
    Color baseColor;
    if (value == null) {
      // '全部' 特殊处理
      // '全部' 选项的颜色，可以用灰色或主题色中的一种
      baseColor = Colors.grey.shade500; // 使用中性灰色
      // 或者用主题色: baseColor = theme.primaryColor;
    } else {
      // 从 GameCategoryUtils 获取特定分类的颜色
      baseColor = GameCategoryUtils.getCategoryColor(value);
    }

    // 2. --- 计算最终样式 (逻辑同 GameTag) ---
    final Color finalBgColor;
    final Color finalTextColor;
    final FontWeight finalFontWeight;
    final Border? finalBorder;

    if (isSelected) {
      // --- 选中状态：用基础色做背景，高对比度文字 ---
      finalBgColor = baseColor;
      // 使用 GameTagUtils 的方法来计算文字颜色，确保一致性
      finalTextColor = GameTagUtils.getTextColorForBackground(baseColor);
      finalFontWeight = FontWeight.bold;
      finalBorder = null;
    } else {
      // --- 未选中状态：淡彩背景 + 彩色边框 + 彩色文字 ---
      finalBgColor = baseColor.withSafeOpacity(0.1); // 非常淡的彩色背景
      finalTextColor = baseColor; // 彩色文字
      finalFontWeight = FontWeight.normal;
      finalBorder = Border.all(
        color: baseColor.withSafeOpacity(0.5), // 半透明的基础色边框
        width: 1.0,
      );
    }

    // 3. --- 样式参数 (尽量和 GameTag 统一) ---
    final double borderRadius = 12.0;
    final double horizontalPadding = 8.0;
    final double verticalPadding = 4.0;
    final double fontSize = 11.0;
    final double countFontSize = 9.0;

    // --- 获取当前页该分类的计数 (可选显示) ---
    // 注意：这个计数是基于 currentPageGames 的，仅用于显示，不影响筛选逻辑
    final categoryStat =
        GameStatsService.getCategoryStatistics(currentPageGames).firstWhere(
      (stat) => stat.name == value, // 如果 value 是 null 会怎样？需要处理
      orElse: () => CategoryStat(name: value ?? '', count: 0), // 找不到则计数为 0
    );
    final displayCount = (value == null) // 如果是"全部"，显示总数或不显示？这里先不显示"全部"的计数
        ? 0
        : categoryStat.count;

    // 4. 构建 Widget
    return InkWell(
      // 使用 InkWell 使其可点击
      onTap: onSelected != null ? () => onSelected(value) : null,
      borderRadius: BorderRadius.circular(borderRadius), // 点击效果也用圆角
      splashColor: baseColor.withSafeOpacity(0.2), // 水波纹用基础色
      highlightColor: baseColor.withSafeOpacity(0.1), // 高亮用基础色
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding, vertical: verticalPadding),
        decoration: BoxDecoration(
          color: finalBgColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: finalBorder, // 应用边框
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // 包裹内容
          children: [
            // 分类文本
            Text(
              label,
              style: TextStyle(
                color: finalTextColor,
                fontWeight: finalFontWeight,
                fontSize: fontSize,
              ),
              overflow: TextOverflow.ellipsis, // 防止文本溢出
            ),
            // 显示计数值 (如果计数大于0且不是"全部"选项)
            if (displayCount > 0) ...[
              SizedBox(width: 5), // 文本和计数的间距
              Container(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  // 计数的背景：用文字颜色的更淡透明度
                  color:
                      finalTextColor.withSafeOpacity(isSelected ? 0.2 : 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$displayCount',
                  style: TextStyle(
                    color: finalTextColor,
                    fontWeight: FontWeight.bold, // 计数恒定加粗
                    fontSize: countFontSize,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  // --- 以下方法保持不变 (除了 _buildTagsStats 已在上一轮修改) ---

  // 页面摘要卡片
  Widget _buildStatsCard(
      BuildContext context, String title, List<StatsItem> items) {
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
                    color: theme.primaryColor.withSafeOpacity(0.1),
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

  // 分类统计条形图
  Widget _buildCategoriesStats(
      BuildContext context, List<CategoryStat> categoryStats) {
    final theme = Theme.of(context);
    if (categoryStats.isEmpty) {
      return Column(
        /* ... 无数据提示 ... */
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '分类统计 (当前页)',
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

    categoryStats.sort((a, b) => b.count.compareTo(a.count));
    final maxCount = categoryStats.isNotEmpty ? categoryStats.first.count : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '分类统计 (当前页)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: theme.primaryColor,
          ),
        ),
        SizedBox(height: 8),
        ...categoryStats.map((category) {
          if (category.count == 0 && category.name.isEmpty) {
            return const SizedBox.shrink();
          }
          final displayName = category.name.isEmpty ? '(未分类)' : category.name;

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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(theme.primaryColor),
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

  // 标签统计 (使用 GameTag - 已在上一轮修改)
  Widget _buildTagsStats(BuildContext context, List<TagStat> tagStats) {
    final theme = Theme.of(context);
    tagStats.sort((a, b) => b.count.compareTo(a.count));
    final double tagTapBorderRadius = 12.0; // 和分类筛选及 GameTag 协调

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '标签统计 (当前页)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: theme.primaryColor,
              ),
            ),
            if (selectedTag != null && onTagSelected != null)
              InkWell(
                onTap: () => onTagSelected!(null),
                child: Container(
                  // 清除按钮样式
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withSafeOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, size: 12, color: theme.primaryColor),
                      SizedBox(width: 4),
                      Text('清除',
                          style: TextStyle(
                              fontSize: 12, color: theme.primaryColor)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 8),
        tagStats.isEmpty
            ? Center(
                // 无数据提示
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text('暂无标签数据 (当前页)',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ),
              )
            : Wrap(
                // 使用 Wrap 排列 GameTag
                spacing: 8,
                runSpacing: 8,
                children: tagStats.map((stat) {
                  final isSelected = selectedTag == stat.name;
                  final tagColor =
                      GameTagUtils.getTagColor(stat.name); // 获取标签颜色用于水波纹

                  return InkWell(
                    onTap: onTagSelected != null
                        ? () => onTagSelected!(stat.name)
                        : null,
                    borderRadius: BorderRadius.circular(tagTapBorderRadius),
                    splashColor: tagColor.withSafeOpacity(0.2), // 使用标签颜色
                    highlightColor: tagColor.withSafeOpacity(0.1), // 使用标签颜色
                    child: GameTagItem(
                      tag: stat.name,
                      count: stat.count,
                      isSelected: isSelected,
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }
}

// 辅助类 StatsItem
class StatsItem {
  final String label;
  final String value;
  StatsItem(this.label, this.value);
}
