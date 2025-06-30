// lib/widgets/components/screen/forum/mobile_tag_filter.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/post/enrich_post_tag.dart';
import 'package:suxingchahui/utils/dart/func_extension.dart';
import 'package:suxingchahui/widgets/ui/components/post/post_tag_item.dart'; // 引入你的 PostTagItem

/// 移动端帖子标签筛选器组件
class MobileTagFilter extends StatelessWidget {
  final List<EnrichPostTag> tags;

  /// 当前选中的标签，如果选择的是 "全部"，则为 null
  final String? selectedTag;

  /// 标签被选中时的回调，回传选中的 PostTag?
  final VoidCallbackNullableString onTagSelected;

  const MobileTagFilter({
    super.key,
    required this.tags,
    required this.selectedTag,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // 高度可以由 PostTagItem 的大小自适应，或者你也可以指定一个固定高度
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tags.length,
        itemBuilder: (context, index) {
          final enrichTag = tags[index];
          final tag = enrichTag.tag;

          // 判断当前标签是否被选中，这个逻辑依然需要
          bool isSelected;
          if (tag == '全部') {
            isSelected = selectedTag == null;
          } else {
            isSelected = selectedTag != null && selectedTag! == tag;
          }

          return Padding(
            // 给每个标签之间加点间距
            padding: const EdgeInsets.only(right: 8.0),
            child: PostTagItem(
              enrichTag: enrichTag,
              isSelected: isSelected,
              // ✨ 核心改动：直接把 onTagSelected 回调传给 PostTagItem 的 onTap
              // PostTagItem 内部会处理好 "全部" -> null 和 "其他" -> PostTag 的转换
              onTap: onTagSelected,
              // 筛选条里的标签通常小一点，使用 isMini 模式
              isMini: true,
            ),
          );
        },
      ),
    );
  }
}
