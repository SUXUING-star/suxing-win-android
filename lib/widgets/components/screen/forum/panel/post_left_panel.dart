// lib/widgets/components/screen/forum/panel/post_left_panel.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/post/post_constants.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/components/post/post_tag_item.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class PostLeftPanel extends StatelessWidget {
  final double panelWidth;
  final List<PostTag> tags;
  final PostTag? selectedTag;
  final Function(PostTag?) onTagSelected;

  const PostLeftPanel({
    super.key,
    required this.panelWidth,
    required this.tags,
    required this.selectedTag,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    // 整体容器样式向 GameLeftPanel 看齐
    final primaryColor = Theme.of(context).primaryColor;
    return Container(
      width: panelWidth,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withSafeOpacity(0.9), // 跟随主题卡片颜色
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withSafeOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: primaryColor.withSafeOpacity(0.85),
              child: const Row(
                children: [
                  Icon(Icons.label_important_outline,
                      color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '帖子分类',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // --- 标签区域，用 Expanded + SingleChildScrollView ---
            Expanded(
              child: tags.isEmpty
                  ? const EmptyStateWidget(
                      iconData: Icons.label_off_outlined,
                      message: '暂无分类标签',
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: _buildTagsWrap(context), // 用 Wrap 布局，更灵活
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 使用 Wrap 布局来构建标签列表，自动换行，更灵活。
  Widget _buildTagsWrap(BuildContext context) {
    // 把 "全部" 和其他标签整合到一个列表里，方便统一处理
    final allOptions = <PostTag?>[null, ...tags]; // null 代表 "全部"

    return Wrap(
      spacing: 8.0, // 水平间距
      runSpacing: 8.0, // 垂直间距
      children: allOptions.map((tagOption) {
        // --- 核心逻辑部分 ---
        final String tagStringToShow = tagOption?.displayText ?? '全部';
        final bool isSelected = selectedTag == tagOption;

        // 直接返回 PostTagItem，把 isSelected 状态传进去就行
        // count 不传，它自己就是 null
        return PostTagItem(
          tagString: tagStringToShow,
          isSelected: isSelected,
          onTap: (_) => onTagSelected(tagOption), // 点击时回调，传递的是枚举本身
          isMini: false, // 左侧面板用标准大小，显得大气
        );
      }).toList(),
    );
  }
}
