
import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/game/game_constants.dart';
import 'package:suxingchahui/widgets/ui/components/game/game_tag.dart';

class GameTagList extends StatelessWidget {
  final List<String> tags;
  final int maxTags;
  final bool isScrollable;

  const GameTagList({
    super.key,
    required this.tags,
    required this.maxTags,
    this.isScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final tagWidgets = tags.take(maxTags).map(_buildTagItem).toList();

    if (isScrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: tagWidgets),
      );
    } else {
      return Wrap(
        spacing: 4,
        runSpacing: 4,
        children: tagWidgets,
      );
    }
  }

  Widget _buildTagItem(String tag) {
    return GameTag(tag: tag);
  }
}
