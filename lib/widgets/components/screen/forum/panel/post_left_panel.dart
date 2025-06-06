// lib/widgets/components/screen/forum/panel/post_left_panel.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/post/post_constants.dart'; // 需要 PostTag 和扩展
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/components/post/post_tag_item.dart'; // <--- 引入 PostTagItem
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';

class PostLeftPanel extends StatelessWidget {
  final List<PostTag> tags; // 接收枚举列表 (所有可用标签)
  final PostTag? selectedTag; // 接收可空的枚举 (当前选中项)
  final Function(PostTag?) onTagSelected; // 回调函数 (传递选中的枚举或 null)

  const PostLeftPanel({
    super.key,
    required this.tags,
    required this.selectedTag,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    final panelWidth = DeviceUtils.getSidePanelWidth(context);

    return Container(
      width: panelWidth,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        // 使用 Decoration 代替旧的组合
        color: Colors.white.withSafeOpacity(0.9), // 轻微调整透明度
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withSafeOpacity(0.08), // 调整阴影
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        // 内部内容需要裁剪圆角
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12), // 调整 padding
              decoration: BoxDecoration(
                // 使用渐变或纯色
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor.withSafeOpacity(0.9),
                    Theme.of(context).primaryColor.withSafeOpacity(0.7),
                  ],
                ),
                // color: Theme.of(context).primaryColor.withSafeOpacity(0.85),
                // 不需要单独设置圆角，因为 ClipRRect 会处理
              ),
              child: Row(
                children: [
                  const Icon(Icons.label_outline,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    '分类标签',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(), // 推到右边
                  // --- 清除按钮逻辑 ---
                  // 仅当选中了某个具体标签 (selectedTag != null) 时才显示
                  if (selectedTag != null)
                    Material(
                      // 添加 Material 提供水波纹效果
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onTagSelected(null), // 点击时调用回调并传递 null
                        borderRadius: BorderRadius.circular(12), // 匹配形状
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4), // 调整 padding
                          decoration: BoxDecoration(
                            color: Colors.white.withSafeOpacity(0.25), // 调整背景透明度
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.clear_all,
                                  size: 14, color: Colors.white), // 换个更明确的图标
                              SizedBox(width: 4),
                              Text(
                                '全部', // 显示 "全部" 更直观
                                style: TextStyle(
                                    fontSize: 12, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // 标签区域
            Expanded(
              child: SingleChildScrollView(
                // 保证内容可滚动
                padding: const EdgeInsets.all(12), // 统一内边距
                child: _buildTagsGrid(context), // 构建网格
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建标签网格 (使用 PostTagItem)
  Widget _buildTagsGrid(BuildContext context) {
    // 将 "全部" (null) 和其他标签组合起来
    List<PostTag?> allOptions = [null, ...tags]; // null 在第一个

    if (allOptions.length <= 1) {
      // 只有 "全部" 或没有标签
      return const EmptyStateWidget(
        iconData: Icons.label_off_outlined,
        message: '暂无分类标签',
      );
    }

    return GridView.builder(
      shrinkWrap: true, // 在 SingleChildScrollView 中必须
      physics: const NeverScrollableScrollPhysics(), // 禁止 GridView 自身滚动
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 每行2个
        childAspectRatio: 3.5, // 调整宽高比，让按钮更宽一点
        crossAxisSpacing: 5, // 横向间距
        mainAxisSpacing: 10, // 纵向间距
      ),
      itemCount: allOptions.length, // 包含 "全部"
      itemBuilder: (context, index) {
        final PostTag? tagOption = allOptions[index]; // 获取当前项 (可能为 null)
        // 1. 获取要显示的字符串
        final String tagStringToShow =
            tagOption?.displayText ?? '全部'; // null 时显示 '全部'

        // 2. 构建 PostTagItem, 传递 tagString
        return PostTagItem(
          tagString: tagStringToShow, // <--- 传递字符串！
          isSelected: selectedTag == tagOption, // 判断选中状态仍然用枚举比较
          onTap: onTagSelected, // 回调函数不变，传递 PostTag?
          isMini: false, // 左侧面板用标准大小
        );
      },
    );
  }
} // ForumLeftPanel 类结束
