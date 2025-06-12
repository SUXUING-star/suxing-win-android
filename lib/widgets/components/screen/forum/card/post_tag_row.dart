// lib/widgets/components/screen/forum/card/post_tag_row.dart

/// 该文件定义了 PostTagsRow 组件，用于显示帖子标签行。
/// PostTagsRow 在水平滚动视图中展示帖子标签。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件
import 'package:suxingchahui/widgets/ui/components/post/post_tag_item.dart'; // 帖子标签项组件

/// `PostTagsRow` 类：显示帖子标签行的无状态组件。
///
/// 该组件负责在水平滚动视图中显示帖子标签。
class PostTagsRow extends StatelessWidget {
  final List<String> tags; // 标签字符串列表
  final bool isAndroidPortrait; // 是否为 Android 竖屏模式，控制尺寸

  /// 构造函数。
  ///
  /// [key]：Widget 的 Key。
  /// [tags]：要显示的标签字符串列表。
  /// [isAndroidPortrait]：是否为 Android 竖屏模式。
  const PostTagsRow({
    super.key,
    required this.tags,
    this.isAndroidPortrait = false,
  });

  /// 构建 Widget。
  ///
  /// 如果标签列表为空，返回空 Widget。
  /// 否则，在水平滚动视图中显示每个标签项。
  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      // 标签列表为空时
      return const SizedBox.shrink(); // 返回空 Widget
    }

    return SingleChildScrollView(
      // 单一子项可滚动视图
      scrollDirection: Axis.horizontal, // 设置为水平滚动
      child: Row(
        // 行布局，用于排列标签项
        children: tags.map((tagString) {
          // 遍历标签字符串列表
          return Padding(
            padding: const EdgeInsets.only(right: 6.0), // 标签之间的右侧间距
            child: PostTagItem(
              // 帖子标签项组件
              tagString: tagString, // 标签字符串
              isMini: true, // 使用迷你模式
              isSelected: true, // 设置为选中状态
            ),
          );
        }).toList(), // 将遍历结果转换为 Widget 列表
      ),
    );
  }
}
