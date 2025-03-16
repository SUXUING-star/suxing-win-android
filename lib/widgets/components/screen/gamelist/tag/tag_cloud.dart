// lib/widgets/components/screen/gamelist/tag/tag_cloud.dart
import 'package:flutter/material.dart';
import '../../../../../models/tag/tag.dart';
import '../../../../../models/stats/tag_stat.dart';
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

    return Wrap(
      spacing: compact ? 6.0 : 8.0,
      runSpacing: compact ? 6.0 : 8.0,
      children: displayTags.map((tag) {
        // 计算颜色深度
        final colorIntensity = maxCount > minCount
            ? 0.5 + (0.5 * (tag.count - minCount) / (maxCount - minCount))
            : 0.8;

        final baseColor = tagTheme.colorScheme.primary;

        // 根据颜色深度调整颜色
        final tagColor = Color.fromRGBO(
          (baseColor.red * colorIntensity).round(),
          (baseColor.green * colorIntensity).round(),
          (baseColor.blue * colorIntensity).round(),
          1.0,
        );

        final isSelected = selectedTag == tag.name;

        // 设置选中颜色
        final finalColor = isSelected
            ? tagTheme.colorScheme.primary
            : tagColor;

        return Container(
          margin: EdgeInsets.only(bottom: 4),
          child: InkWell(
            onTap: () => onTagSelected(tag.name),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8.0 : 10.0,
                vertical: compact ? 4.0 : 6.0,
              ),
              decoration: BoxDecoration(
                color: finalColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tag.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: compact ? 12.0 : 13.0,
                    ),
                  ),
                  SizedBox(width: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${tag.count}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: compact ? 10.0 : 11.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    Key? key,
    required this.tags,
    this.onTagSelected,
    this.selectedTag,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tagTheme = Theme.of(context);

    // 确定最大计数以进行颜色缩放
    int maxCount = tags.isEmpty ? 1 :
    tags.map((t) => t.count).reduce((a, b) => a > b ? a : b);
    int minCount = tags.isEmpty ? 1 :
    tags.map((t) => t.count).reduce((a, b) => a < b ? a : b);

    return Wrap(
      spacing: compact ? 6.0 : 8.0,
      runSpacing: compact ? 6.0 : 8.0,
      children: tags.map((tag) {
        // 计算颜色深度
        final colorIntensity = maxCount > minCount
            ? 0.5 + (0.5 * (tag.count - minCount) / (maxCount - minCount))
            : 0.8;

        final baseColor = tagTheme.colorScheme.primary;

        // 根据颜色深度调整颜色
        final tagColor = Color.fromRGBO(
          (baseColor.red * colorIntensity).round(),
          (baseColor.green * colorIntensity).round(),
          (baseColor.blue * colorIntensity).round(),
          1.0,
        );

        final isSelected = selectedTag == tag.name;

        // 设置选中颜色
        final finalColor = isSelected
            ? tagTheme.colorScheme.primary
            : tagColor;

        return Container(
          margin: EdgeInsets.only(bottom: 4),
          child: InkWell(
            onTap: onTagSelected != null ? () => onTagSelected!(tag.name) : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8.0 : 10.0,
                vertical: compact ? 4.0 : 6.0,
              ),
              decoration: BoxDecoration(
                color: finalColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tag.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: compact ? 12.0 : 13.0,
                    ),
                  ),
                  SizedBox(width: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${tag.count}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: compact ? 10.0 : 11.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}