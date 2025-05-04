// lib/widgets/components/screen/forum/card/post_tag_row.dart
import 'package:flutter/material.dart';
// import 'package:suxingchahui/constants/post_constants.dart'; // 不再需要直接访问 PostTag
import 'package:suxingchahui/widgets/ui/components/post/post_tag_item.dart'; // 引入 PostTagItem

class PostTagRow extends StatelessWidget {
  final List<String> tags; // 接收来自 Post 模型的字符串列表
  final bool isAndroidPortrait; // 控制是否用更小的尺寸

  const PostTagRow({
    super.key,
    required this.tags, // 接收 List<String>
    this.isAndroidPortrait = false,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    // --- !!! 使用 PostTagItem 构建列表 !!! ---
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // 可以给 Row 加点 padding，如果需要的话
      // padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: tags.map((tagString) { // 遍历字符串列表
          return Padding(
            padding: const EdgeInsets.only(right: 6.0), // 标签之间的间距
            child: PostTagItem(
              tagString: tagString, // <--- 传递字符串
              // isSelected: false, // 卡片预览不选中
              // onTap: null, // 卡片预览不可点
              isMini: true, // 卡片预览统一用 Mini 样式
            ),
          );
        }).toList(),
      ),
    );
  }
}