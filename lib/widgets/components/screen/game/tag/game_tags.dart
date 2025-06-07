// lib/widgets/components/screen/game/tag/game_tags.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/widgets/ui/components/game/game_tag_item.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class GameTags extends StatelessWidget {
  final Game game;
  final double? fontSize;
  final bool wrap;
  final int? maxTags;
  final EdgeInsets? padding;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final Function(BuildContext context, String tag)? onClickFilterGameTag;
  final bool needOnClick;

  const GameTags({
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
    final List<String> tags = game.tags;

    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayTags = maxTags != null && tags.length > maxTags!
        ? tags.sublist(0, maxTags!)
        : tags;

    final tagWidgets =
        displayTags.map((tag) => _buildClickableTag(context, tag)).toList();

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
          children: tagWidgets.map((widget) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: widget,
            );
          }).toList(),
        ),
      );
    }
  }

  Widget _buildClickableTag(BuildContext context, String tag) {
    if (!needOnClick || onClickFilterGameTag == null) {
      return GameTagItem(
        tag: tag,
        isSelected: true,
      );
    }

    return InkWell(
      onTap: () => onClickFilterGameTag!(context, tag),
      borderRadius: BorderRadius.circular(GameTagItem.tagBorderRadius),
      child: GameTagItem(
        tag: tag,
        isSelected: true,
      ),
    );
  }

  Widget _buildMoreIndicator(BuildContext context, int moreCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withSafeOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withSafeOpacity(0.3),
          width: 1,
        ),
      ),
      child: AppText(
        "+$moreCount",
        style: TextStyle(
          fontSize: fontSize ?? 12,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}
