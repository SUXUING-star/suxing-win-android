import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/post/post_constants.dart'; // 需要 PostTag
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class TagFilter extends StatelessWidget {
  final List<String> tags;
  final PostTag? selectedTag;
  final ValueChanged<PostTag?> onTagSelected;

  const TagFilter({
    super.key,
    required this.tags, // 仍然需要字符串列表用于显示 Chip
    required this.selectedTag,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50, // 或根据需要调整
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), // 加点垂直 padding
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tags.length,
        itemBuilder: (context, index) {
          final tagString = tags[index]; // 当前 chip 的显示文本
          bool isSelected;

          // --- !!! 判断是否选中 !!! ---
          if (tagString == '全部') {
            isSelected = selectedTag == null; // "全部" 选中 <=> selectedTag 为 null
          } else {
            // 其他标签选中 <=> selectedTag 非 null 且其显示文本与当前 chip 文本一致
            isSelected = selectedTag != null && selectedTag!.displayText == tagString;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(tagString, /* ... style ... */),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  // --- !!! 回调时传递 PostTag? !!! ---
                  if (tagString == '全部') {
                    onTagSelected(null); // 选中 "全部" 时传递 null
                  } else {
                    // 选中其他标签时，从字符串转回枚举再传递
                    onTagSelected(PostTagsUtils.tagFromString(tagString));
                  }
                }
              },
              // 可以调整样式
              selectedColor: Theme.of(context).primaryColor.withSafeOpacity(0.8),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 13,
              ),
              backgroundColor: Colors.grey[200],
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // 调整内边距
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: BorderSide.none, // 去掉边框
            ),
          );
        },
      ),
    );
  }
}