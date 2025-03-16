// lib/widgets/components/tag_cloud/tag_cloud.dart
import 'package:flutter/material.dart';
import '../../../../../models/tag/tag.dart';
import '../../../../../utils/device/device_utils.dart';

class TagCloud extends StatelessWidget {
  final List<Tag> tags;
  final Function(String) onTagSelected;
  final String? selectedTag;
  final int? maxTags;
  final bool compact;

  const TagCloud({
    Key? key,
    required this.tags,
    required this.onTagSelected,
    this.selectedTag,
    this.maxTags,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tagTheme = Theme.of(context);

    // 如果设置了最大标签数，只显示指定数量的标签
    final displayTags = maxTags != null && maxTags! < tags.length
        ? tags.sublist(0, maxTags)
        : tags;

    // 确定最大和最小计数以进行标签大小缩放
    int maxCount = displayTags.isEmpty ? 1 : displayTags.first.count;
    int minCount = displayTags.isEmpty ? 1 : displayTags.last.count;
    double fontScale = maxCount == minCount ? 1.0 : 1.5;

    return Wrap(
      spacing: compact ? 6.0 : 8.0,
      runSpacing: compact ? 6.0 : 8.0,
      children: displayTags.map((tag) {
        // 计算字体大小
        double fontSize = compact ? 12.0 : 14.0;
        if (maxCount > minCount) {
          double scale = minCount + (tag.count - minCount) / (maxCount - minCount) * fontScale;
          fontSize *= (0.8 + scale * 0.2);
        }

        final isSelected = selectedTag == tag.name;

        return InkWell(
          onTap: () => onTagSelected(tag.name),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8.0 : 12.0,
              vertical: compact ? 4.0 : 6.0,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? tagTheme.colorScheme.primary
                  : tagTheme.colorScheme.primaryContainer.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${tag.name} (${tag.count})',
              style: TextStyle(
                fontSize: fontSize,
                color: isSelected
                    ? tagTheme.colorScheme.onPrimary
                    : tagTheme.colorScheme.onPrimaryContainer,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}