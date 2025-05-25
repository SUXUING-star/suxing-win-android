// lib/widgets/components/screen/gamelist/tag/tag_cloud.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import '../../../../../models/game/game_tag.dart';
import '../../../../../models/stats/tag_stat.dart';

class TagCloud extends StatelessWidget {
  final List<GameTag> tags;
  final Function(String) onTagSelected;
  final String? selectedTag;
  final int? maxTags;
  final bool compact;

  const TagCloud({
    super.key,
    required this.tags,
    required this.onTagSelected,
    this.selectedTag,
    this.maxTags,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    // 如果设置了最大标签数，只显示指定数量的标签
    final displayTags = maxTags != null && maxTags! < tags.length
        ? tags.sublist(0, maxTags)
        : tags;

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: displayTags.map((tag) {
        final isSelected = selectedTag == tag.name;

        return ActionChip(
          label: Text(tag.name),
          avatar: CircleAvatar(
            backgroundColor: isSelected ? Colors.white : Colors.blue,
            foregroundColor: isSelected ? Colors.blue : Colors.white,
            radius: 10,
            child: Text(
              '${tag.count}',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
          backgroundColor: isSelected ? Colors.blue : Colors.blue.withSafeOpacity(0.1),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.blue,
            fontSize: compact ? 12.0 : 13.0,
          ),
          onPressed: () => onTagSelected(tag.name),
        );
      }).toList(),
    );
  }
}

// 用于右侧面板的标签云组件（接受TagStat类型）
class StatTagCloud extends StatelessWidget {
  final List<TagStat> tags;
  final Function(String)? onTagSelected;
  final String? selectedTag;
  final bool compact;

  const StatTagCloud({
    super.key,
    required this.tags,
    this.onTagSelected,
    this.selectedTag,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: tags.map((tag) {
        final isSelected = selectedTag == tag.name;

        return ActionChip(
          label: Text(tag.name),
          avatar: CircleAvatar(
            backgroundColor: isSelected ? Colors.white : Colors.blue,
            foregroundColor: isSelected ? Colors.blue : Colors.white,
            radius: 10,
            child: Text(
              '${tag.count}',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
          backgroundColor: isSelected ? Colors.blue : Colors.blue.withSafeOpacity(0.1),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.blue,
            fontSize: compact ? 12.0 : 13.0,
          ),
          onPressed: onTagSelected != null ? () => onTagSelected!(tag.name) : null,
        );
      }).toList(),
    );
  }
}