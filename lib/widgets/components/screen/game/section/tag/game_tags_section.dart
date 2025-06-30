// lib/widgets/components/screen/game/section/tag/game_tags_section.dart

/// 该文件定义了 GameTagsSection 组件，用于显示游戏的标签列表。
/// GameTagsSection 负责展示游戏标签，并提供点击筛选功能。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:suxingchahui/models/game/game/enrich_game_tag.dart';
import 'package:suxingchahui/models/game/game/game_extension.dart';
import 'package:suxingchahui/widgets/ui/components/base_tag_view.dart'; // 基础标签视图所需
import 'package:suxingchahui/widgets/ui/text/app_text.dart'; // 应用文本组件所需
import 'package:suxingchahui/models/game/game/game.dart'; // 游戏模型所需
import 'package:suxingchahui/widgets/ui/components/game/game_tag_item.dart'; // 游戏标签项组件所需
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展方法所需

/// `GameTagsSection` 类：显示游戏标签列表的 StatelessWidget。
///
/// 该组件负责渲染游戏的标签列表，支持自定义字体大小、布局方式、标签数量限制和点击筛选功能。
class GameTagsSection extends StatelessWidget {
  final Game game; // 游戏数据
  final double? fontSize; // 标签字体大小
  final bool wrap; // 是否自动换行
  final int? maxTags; // 显示的最大标签数量
  final EdgeInsets? padding; // 内部填充
  final MainAxisAlignment mainAxisAlignment; // 主轴对齐方式
  final CrossAxisAlignment crossAxisAlignment; // 交叉轴对齐方式
  final Function(BuildContext context, String tag)?
      onClickFilterGameTag; // 点击标签筛选回调
  final bool needOnClick; // 是否需要点击功能

  /// 构造函数。
  ///
  /// [game]：游戏数据。
  /// [fontSize]：标签字体大小。
  /// [wrap]：是否自动换行。
  /// [maxTags]：显示的最大标签数量。
  /// [padding]：内部填充。
  /// [mainAxisAlignment]：主轴对齐方式。
  /// [crossAxisAlignment]：交叉轴对齐方式。
  /// [onClickFilterGameTag]：点击标签筛选回调。
  /// [needOnClick]：是否需要点击功能。
  const GameTagsSection({
    super.key,
    required this.game,
    this.fontSize,
    this.wrap = true,
    this.maxTags,
    this.padding,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.onClickFilterGameTag,
    this.needOnClick = true,
  });

  @override
  Widget build(BuildContext context) {
    final List<EnrichGameTag> tags = game.enrichTags; // 获取游戏标签列表

    if (tags.isEmpty) {
      // 标签列表为空时隐藏组件
      return const SizedBox.shrink();
    }

    final displayTags = maxTags != null && tags.length > maxTags! // 确定要显示的标签
        ? tags.sublist(0, maxTags!)
        : tags;

    final tagWidgets = displayTags
        .map((tag) => _buildClickableTag(context, tag))
        .toList(); // 构建可点击的标签 Widget 列表

    if (maxTags != null && tags.length > maxTags!) {
      // 存在更多标签时添加更多指示器
      tagWidgets.add(_buildMoreIndicator(context, tags.length - maxTags!));
    }

    if (wrap) {
      // 自动换行布局
      return Wrap(
        spacing: 8, // 水平间距
        runSpacing: 8, // 垂直间距
        crossAxisAlignment: WrapCrossAlignment.center, // 交叉轴对齐方式
        children: tagWidgets, // 标签 Widget 列表
      );
    } else {
      // 单行滚动布局
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal, // 水平滚动
        padding: padding, // 内部填充
        child: Row(
          mainAxisAlignment: mainAxisAlignment, // 主轴对齐方式
          crossAxisAlignment: crossAxisAlignment, // 交叉轴对齐方式
          children: tagWidgets.map((widget) {
            return Padding(
              padding: const EdgeInsets.only(right: 8), // 右侧内边距
              child: widget,
            );
          }).toList(),
        ),
      );
    }
  }

  /// 构建可点击的标签 Widget。
  ///
  /// [context]：Build 上下文。
  /// [tag]：标签文本。
  /// 返回一个可点击的标签项。
  Widget _buildClickableTag(BuildContext context, EnrichGameTag enrichTag) {
    if (!needOnClick || onClickFilterGameTag == null) {
      // 不需要点击功能时直接返回标签项
      return GameTagItem(
        enrichTag: enrichTag,
        isSelected: true,
      );
    }

    return InkWell(
      onTap: () => onClickFilterGameTag!(context, enrichTag.tag), // 点击标签筛选回调
      borderRadius: BorderRadius.circular(BaseTagView.tagRadius), // 圆角
      child: GameTagItem(
        enrichTag: enrichTag,
        isSelected: true,
      ),
    );
  }

  /// 构建“更多”指示器。
  ///
  /// [context]：Build 上下文。
  /// [moreCount]：额外标签的数量。
  /// 返回一个显示额外标签数量的容器。
  Widget _buildMoreIndicator(BuildContext context, int moreCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 内边距
      decoration: BoxDecoration(
        color: Colors.grey.withSafeOpacity(0.1), // 背景颜色
        borderRadius: BorderRadius.circular(12), // 圆角
        border: Border.all(
          color: Colors.grey.withSafeOpacity(0.3), // 边框颜色
          width: 1, // 边框宽度
        ),
      ),
      child: AppText(
        "+$moreCount", // 额外标签数量文本
        style: TextStyle(
          fontSize: fontSize ?? 12, // 字体大小
          color: Colors.grey[700], // 字体颜色
        ),
      ),
    );
  }
}
