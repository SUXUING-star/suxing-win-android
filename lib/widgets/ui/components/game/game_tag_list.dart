// lib/widgets/ui/components/game/game_tag_list.dart

/// 该文件定义了 GameTagList 组件，一个用于显示游戏标签列表的 StatelessWidget。
/// GameTagList 展示标签，并支持限制数量和滚动。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/widgets/ui/components/game/game_tag_item.dart'; // 导入游戏标签项组件

/// `GameTagList` 类：显示游戏标签列表的组件。
///
/// 该组件展示指定数量的游戏标签，并根据配置决定是否可水平滚动。
class GameTagsRow extends StatelessWidget {
  final List<String> tags; // 标签列表
  final int maxTags; // 最大显示标签数量
  final bool isScrollable; // 是否可水平滚动

  final bool isCompact;

  final double tagSpacing;
  final double tagRunSpacing;

  /// 构造函数。
  ///
  /// [tags]：标签列表。
  /// [maxTags]：最大标签数。
  /// [isScrollable]：是否可滚动。
  const GameTagsRow({
    super.key,
    required this.tags,
    required this.maxTags,
    this.isCompact = false,
    this.isScrollable = false,
  })  : tagSpacing = isCompact ? 2.0 : 4.0,
        tagRunSpacing = isCompact ? 2.0 : 4.0;

  /// 构建游戏标签列表。
  ///
  /// 根据 [isScrollable] 参数选择使用 [SingleChildScrollView] 或 [Wrap] 布局。
  @override
  Widget build(BuildContext context) {
    final tagWidgets =
        tags.take(maxTags).map(_buildTagItem).toList(); // 获取指定数量的标签组件

    if (isScrollable) {
      // 可水平滚动时
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal, // 水平滚动
        child: Row(children: tagWidgets), // 行布局
      );
    } else {
      // 不可滚动时
      return Wrap(
        spacing: tagSpacing, // 水平间距
        runSpacing: tagRunSpacing, // 垂直间距
        children: tagWidgets, // Wrap 布局
      );
    }
  }

  /// 构建单个标签项。
  ///
  /// [tag]：标签文本。
  Widget _buildTagItem(String tag) {
    return GameTagItem(tag: tag); // 返回游戏标签项组件
  }
}
