// lib/widgets/components/screen/forum/card/post_tag_row.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/components/post/post_tag_item.dart';

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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tags.map((tagString) {
          // 遍历字符串列表
          return Padding(
            padding: const EdgeInsets.only(right: 6.0), // 标签之间的间距
            child: PostTagItem(
              tagString: tagString,
              isMini: true,
            ),
          );
        }).toList(),
      ),
    );
  }
}
