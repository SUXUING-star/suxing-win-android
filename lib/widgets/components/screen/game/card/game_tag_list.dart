// 5. game_tag_list.dart
import 'package:flutter/material.dart';

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
    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          tag,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }
}