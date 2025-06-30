// lib/widgets/components/screen/game/panel/game_right_panel.dart

/// 该文件定义了 [GameRightPanel] 组件，用于显示游戏列表的右侧面板。
/// [GameRightPanel] 展示统计信息、分类筛选和标签统计。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:suxingchahui/models/extension/theme/base/background_color_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_color_extension.dart';
import 'package:suxingchahui/models/game/game/enrich_game_category.dart';
import 'package:suxingchahui/models/game/game/enrich_game_tag.dart';
import 'package:suxingchahui/widgets/ui/components/game/game_tag_item.dart'; // 游戏标签项组件所需
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展方法所需
import 'package:suxingchahui/models/game/game/game.dart'; // 游戏模型所需
import 'package:suxingchahui/models/game/game/game_category_stat.dart'; // 分类统计模型所需
import 'package:suxingchahui/models/game/game/game_tag_stat.dart'; // 标签统计模型所需
import 'package:suxingchahui/services/main/game/game_stats_service.dart'; // 游戏统计服务所需

/// [GameRightPanel] 类：显示游戏列表右侧面板的 StatelessWidget。
///
/// 该组件负责展示当前页面的统计数据、分类筛选器和标签统计。
class GameRightPanel extends StatelessWidget {
  final double panelWidth; // 面板宽度
  final List<Game> currentPageGames; // 当前页面显示的游戏列表
  final int totalGamesCount; // 游戏总数
  final String? selectedTag; // 当前选中的标签
  final Function(EnrichGameTag?)? onTagSelected; // 标签选择回调
  final String? selectedCategory; // 当前选中的分类
  final Function(EnrichGameCategory?)? onCategorySelected; // 分类选择回调
  final List<EnrichGameCategory> availableCategories; // 所有可用分类列表

  /// 构造函数。
  ///
  /// [panelWidth]：面板宽度。
  /// [currentPageGames]：当前页面游戏列表。
  /// [totalGamesCount]：游戏总数。
  /// [availableCategories]：所有可用分类列表。
  /// [selectedTag]：当前选中标签。
  /// [onTagSelected]：标签选择回调。
  /// [selectedCategory]：当前选中分类。
  /// [onCategorySelected]：分类选择回调。
  const GameRightPanel({
    super.key,
    required this.panelWidth,
    required this.currentPageGames,
    required this.totalGamesCount,
    required this.availableCategories,
    this.selectedTag,
    this.onTagSelected,
    this.selectedCategory,
    this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<GameCategoryStat> categoryStats =
        GameStatsService.getCategoryStatistics(
            currentPageGames); // 获取当前页的分类统计数据
    final List<GameTagStat> tagStats =
        GameStatsService.getTagStatistics(currentPageGames); // 获取当前页的标签统计数据
    final int uniqueCategoriesCount = GameStatsService.getUniqueCategoriesCount(
        currentPageGames); // 获取当前页的唯一分类数量
    final int uniqueTagsCount =
        GameStatsService.getUniqueTagsCount(currentPageGames); // 获取当前页的唯一标签数量

    return Container(
      width: panelWidth, // 设置面板宽度
      margin: const EdgeInsets.all(8), // 设置外边距
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12), // 设置圆角
        child: Container(
          color: Theme.of(context).cardColor.withSafeOpacity(0.8), // 设置背景颜色
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.all(12), // 设置内边距
                color: Theme.of(context).primaryColor, // 设置背景颜色
                child: Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: Theme.of(context).colorScheme.onPrimary, // 设置图标颜色
                      size: 16,
                    ),
                    const SizedBox(width: 8), // 设置间距
                    Text(
                      '统计信息',
                      style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onPrimary, // 设置文字颜色
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
                  padding: const EdgeInsets.all(12), // 设置内边距
                  children: [
                    _buildStatsCard(
                      context,
                      '页面摘要 (当前页)',
                      [
                        _StatsItem('显示游戏数', '${currentPageGames.length}'),
                        _StatsItem('总游戏数', '$totalGamesCount'),
                        _StatsItem('分类数 (当前页)', '$uniqueCategoriesCount'),
                        _StatsItem('标签数 (当前页)', '$uniqueTagsCount'),
                      ],
                    ),
                    const SizedBox(height: 16), // 设置间距
                    _buildCategoryFilter(context), // 构建分类筛选区域
                    const SizedBox(height: 16), // 设置间距
                    _buildCategoriesStats(context, categoryStats), // 构建分类统计条形图
                    const SizedBox(height: 16), // 设置间距
                    _buildTagsStats(context, tagStats), // 构建标签统计
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建分类筛选区域。
  ///
  /// [context]：Build 上下文。
  /// 返回一个包含分类筛选标题和可筛选分类 Chip 的 Widget。
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
            if (selectedCategory != null &&
                onCategorySelected != null) // 选中分类存在且回调非空时显示清除按钮
              InkWell(
                onTap: () => onCategorySelected!(null), // 点击时清除选中分类
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withSafeOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, size: 12, color: theme.primaryColor),
                      const SizedBox(width: 4),
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
        const SizedBox(height: 8), // 设置间距
        availableCategories.isEmpty // 如果没有可用分类
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
                spacing: 8, // 设置水平间距
                runSpacing: 8, // 设置垂直间距
                children: [
                  _buildFilterChip(
                    context: context,
                    label: '全部',
                    enrichCategory: null, // null 表示全部
                    isSelected: selectedCategory == null,
                    onSelected: onCategorySelected,
                  ),
                  ...availableCategories.map((c) {
                    // 遍历所有可用分类并构建 Chip
                    return _buildFilterChip(
                      context: context,
                      label: c.category,
                      enrichCategory: c,
                      isSelected: selectedCategory == c.category,
                      onSelected: onCategorySelected,
                    );
                  }),
                ],
              ),
        const Divider(height: 24), // 分割线
      ],
    );
  }

  /// 构建单个分类筛选 Chip。
  ///
  /// [context]：Build 上下文。
  /// [label]：Chip 显示的文本。
  /// [value]：Chip 对应的分类值，null 表示“全部”。
  /// [isSelected]：Chip 是否被选中。
  /// [onSelected]：Chip 选中回调。
  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required EnrichGameCategory? enrichCategory,
    required bool isSelected,
    required Function(EnrichGameCategory?)? onSelected,
  }) {
    final value = enrichCategory?.category;
    Color baseColor; // 基础颜色
    if (enrichCategory == null) {
      baseColor = Colors.grey.shade500; // “全部”选项的颜色
    } else {
      baseColor = enrichCategory.textColor;
    }

    final Color finalBgColor; // 最终背景颜色
    final Color finalTextColor; // 最终文字颜色
    final FontWeight finalFontWeight; // 最终字体粗细
    final Border? finalBorder; // 最终边框

    if (isSelected) {
      // 选中状态
      finalBgColor = baseColor; // 使用基础色作为背景
      finalTextColor = EnrichGameCategory.getCategoryTextColorForBackground(
          baseColor); // 确保文字颜色高对比度
      finalFontWeight = FontWeight.bold; // 字体加粗
      finalBorder = null; // 无边框
    } else {
      // 未选中状态
      finalBgColor = baseColor.withSafeOpacity(0.1); // 使用淡彩色背景
      finalTextColor = baseColor; // 使用彩色文字
      finalFontWeight = FontWeight.normal; // 字体正常
      finalBorder = Border.all(
        color: baseColor.withSafeOpacity(0.5), // 使用半透明基础色边框
        width: 1.0,
      );
    }

    final double borderRadius = 12.0; // 圆角半径
    final double horizontalPadding = 8.0; // 水平内边距
    final double verticalPadding = 4.0; // 垂直内边距
    final double fontSize = 11.0; // 字体大小
    final double countFontSize = 9.0; // 计数字体大小

    final categoryStat =
        GameStatsService.getCategoryStatistics(currentPageGames).firstWhere(
      (stat) => stat.category == value,
      orElse: () =>
          GameCategoryStat(category: value ?? '', count: 0), // 未找到时计数为 0
    );
    final displayCount = (value == null) // 非“全部”选项且计数大于 0 时显示
        ? 0
        : categoryStat.count;

    return InkWell(
      onTap: onSelected != null
          ? () => onSelected(enrichCategory)
          : null, // Chip 点击回调
      borderRadius: BorderRadius.circular(borderRadius), // 点击效果圆角
      splashColor: baseColor.withSafeOpacity(0.2), // 水波纹颜色
      highlightColor: baseColor.withSafeOpacity(0.1), // 高亮颜色
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding, vertical: verticalPadding),
        decoration: BoxDecoration(
          color: finalBgColor, // 背景颜色
          borderRadius: BorderRadius.circular(borderRadius), // 圆角
          border: finalBorder, // 边框
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label, // 分类文本
              style: TextStyle(
                color: finalTextColor, // 文字颜色
                fontWeight: finalFontWeight, // 字体粗细
                fontSize: fontSize, // 字体大小
              ),
              overflow: TextOverflow.ellipsis, // 文本溢出处理
            ),
            if (displayCount > 0) ...[
              // 计数大于 0 时显示计数
              const SizedBox(width: 5), // 间距
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: finalTextColor
                      .withSafeOpacity(isSelected ? 0.2 : 0.15), // 计数背景色
                  borderRadius: BorderRadius.circular(6), // 计数背景圆角
                ),
                child: Text(
                  '$displayCount', // 计数
                  style: TextStyle(
                    color: finalTextColor, // 计数文字颜色
                    fontWeight: FontWeight.bold, // 计数字体加粗
                    fontSize: countFontSize, // 计数字体大小
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  /// 构建页面摘要统计卡片。
  ///
  /// [context]：Build 上下文。
  /// [title]：卡片标题。
  /// [items]：统计项列表。
  /// 返回一个包含统计信息的卡片 Widget。
  Widget _buildStatsCard(
      BuildContext context, String title, List<_StatsItem> items) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title, // 卡片标题
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(height: 8), // 间距
        ...items.map((item) {
          // 遍历统计项
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0), // 底部内边距
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.label, // 统计项标签
                  style: const TextStyle(fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2), // 内边距
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withSafeOpacity(0.1), // 背景颜色
                    borderRadius: BorderRadius.circular(12), // 圆角
                  ),
                  child: Text(
                    item.value, // 统计项值
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
        const Divider(height: 16), // 分割线
      ],
    );
  }

  /// 构建分类统计条形图。
  ///
  /// [context]：Build 上下文。
  /// [categoryStats]：分类统计数据列表。
  /// 返回一个包含分类统计信息的条形图 Widget。
  Widget _buildCategoriesStats(
      BuildContext context, List<GameCategoryStat> categoryStats) {
    final theme = Theme.of(context);
    if (categoryStats.isEmpty) {
      // 分类统计数据为空时显示提示
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
          const SizedBox(height: 8), // 间距
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
          const Divider(height: 16), // 分割线
        ],
      );
    }

    categoryStats.sort((a, b) => b.count.compareTo(a.count)); // 按计数降序排序
    final maxCount =
        categoryStats.isNotEmpty ? categoryStats.first.count : 1; // 获取最大计数

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
        const SizedBox(height: 8), // 间距
        ...categoryStats.map((category) {
          // 遍历分类统计数据
          if (category.count == 0 && category.category.isEmpty) {
            return const SizedBox.shrink(); // 空的分类不显示
          }
          final displayName =
              category.category.isEmpty ? '(未分类)' : category.category; // 显示名称

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0), // 底部内边距
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        displayName, // 分类名称
                        overflow: TextOverflow.ellipsis, // 文本溢出处理
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      '${category.count}', // 分类计数
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4), // 间距
                ClipRRect(
                  borderRadius: BorderRadius.circular(2), // 圆角
                  child: LinearProgressIndicator(
                    value: maxCount > 0 ? category.count / maxCount : 0, // 进度条值
                    backgroundColor: Colors.grey[200], // 背景颜色
                    valueColor: AlwaysStoppedAnimation<Color>(
                        theme.primaryColor), // 进度条颜色
                    minHeight: 4, // 最小高度
                  ),
                ),
              ],
            ),
          );
        }),
        const Divider(height: 16), // 分割线
      ],
    );
  }

  /// 构建标签统计区域。
  ///
  /// [context]：Build 上下文。
  /// [tagStats]：标签统计数据列表。
  /// 返回一个包含标签统计信息的 Wrap Widget。
  Widget _buildTagsStats(BuildContext context, List<GameTagStat> tagStats) {
    final theme = Theme.of(context);
    tagStats.sort((a, b) => b.count.compareTo(a.count)); // 按计数降序排序
    final double tagTapBorderRadius = 12.0; // 标签点击区域圆角

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
            if (selectedTag != null &&
                onTagSelected != null) // 选中标签存在且回调非空时显示清除按钮
              InkWell(
                onTap: () => onTagSelected!(null), // 点击时清除选中标签
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withSafeOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, size: 12, color: theme.primaryColor),
                      const SizedBox(width: 4), // 间距
                      Text('清除',
                          style: TextStyle(
                              fontSize: 12, color: theme.primaryColor)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8), // 间距
        tagStats.isEmpty // 标签统计数据为空时显示提示
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text('暂无标签数据 (当前页)',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ),
              )
            : Wrap(
                spacing: 8, // 水平间距
                runSpacing: 8, // 垂直间距
                children: tagStats.map((stat) {
                  // 遍历标签统计数据
                  final enrichGameTag = stat.enrichTag;
                  final name = stat.enrichTag.tag;
                  final isSelected = selectedTag == name; // 判断标签是否被选中
                  final tagColor = stat.enrichTag.backgroundColor; // 获取标签颜色

                  return InkWell(
                    onTap: onTagSelected != null
                        ? () => onTagSelected!(enrichGameTag)
                        : null, // 标签点击回调
                    borderRadius:
                        BorderRadius.circular(tagTapBorderRadius), // 点击效果圆角
                    splashColor: tagColor.withSafeOpacity(0.2), // 水波纹颜色
                    highlightColor: tagColor.withSafeOpacity(0.1), // 高亮颜色
                    child: GameTagItem(
                      enrichTag: stat.enrichTag, // 标签名称
                      count: stat.count, // 标签计数
                      isSelected: isSelected, // 标签选中状态
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }
}

/// [_StatsItem] 类：表示一个统计项的数据模型。
class _StatsItem {
  final String label; // 统计项的标签
  final String value; // 统计项的值

  /// 构造函数。
  ///
  /// [label]：统计项的标签。
  /// [value]：统计项的值。
  _StatsItem(this.label, this.value);
}
