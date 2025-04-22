// lib/widgets/game/tag/game_tags.dart
import 'package:flutter/material.dart';
import '../../../../../../models/game/game.dart';

class GameTags extends StatelessWidget {
  final Game game;
  final double? fontSize;
  final bool wrap;
  final int? maxTags;
  final EdgeInsets? padding;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const GameTags({
    super.key,
    required this.game,
    this.fontSize,
    this.wrap = true,
    this.maxTags,
    this.padding,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    // 安全获取tags，处理可能的null值
    final List<String> tags = game.tags ?? [];

    if (tags.isEmpty) {
      return SizedBox.shrink();
    }

    final displayTags = maxTags != null && tags.length > maxTags!
        ? tags.sublist(0, maxTags)
        : tags;

    final tagWidgets = displayTags.map((tag) => _buildTag(context, tag)).toList();

    // 如果需要显示更多标签的指示器
    if (maxTags != null && tags.length > maxTags!) {
      tagWidgets.add(_buildMoreIndicator(context, tags.length - maxTags!));
    }

    if (wrap) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: tagWidgets,
      );
    } else {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        child: Row(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          children: tagWidgets.map((tag) {
            return Padding(
              padding: EdgeInsets.only(right: 8),
              child: tag,
            );
          }).toList(),
        ),
      );
    }
  }

  Widget _buildTag(BuildContext context, String tag) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: fontSize ?? 12,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildMoreIndicator(BuildContext context, int moreCount) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        "+$moreCount",
        style: TextStyle(
          fontSize: fontSize ?? 12,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}