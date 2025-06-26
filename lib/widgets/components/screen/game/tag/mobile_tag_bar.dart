// lib/widgets/components/screen/game/tag/mobile_tag_bar.dart

/// 该文件定义了 MobileTagBar 组件，用于移动端显示游戏标签栏。
/// MobileTagBar 提供水平滚动的标签列表和标签筛选功能。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:suxingchahui/models/game/game_tag.dart'; // 游戏标签模型所需
import 'package:suxingchahui/widgets/ui/components/game/game_tag_item.dart'; // 游戏标签项组件所需
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展方法所需

/// `MobileTagBar` 类：显示移动端标签栏的 StatelessWidget。
///
/// 该组件提供一个水平滚动的标签列表，用户可以点击标签进行筛选。
class MobileTagBar extends StatelessWidget implements PreferredSizeWidget {
  final List<GameTag> tags; // 游戏标签列表
  final String? selectedTag; // 当前选中的标签
  final Function(String) onTagSelected; // 标签选择回调

  /// 构造函数。
  ///
  /// [tags]：游戏标签列表。
  /// [selectedTag]：当前选中的标签。
  /// [onTagSelected]：标签选择回调。
  const MobileTagBar({
    super.key,
    required this.tags,
    required this.selectedTag,
    required this.onTagSelected,
  });

  @override
  Size get preferredSize => const Size.fromHeight(48.0); // 定义标签栏的首选尺寸

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height, // 设置容器高度
      color: Colors.white.withSafeOpacity(0.7), // 背景颜色
      child: Column(
        children: [
          // 顶部蓝色条
          Container(
            height: 2, // 高度
            color: Colors.blue, // 颜色
          ),

          // 标签列表
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal, // 水平滚动
              padding: const EdgeInsets.symmetric(
                  horizontal: 12.0, vertical: 8.0), // 内边距
              itemCount: tags.length, // 标签数量
              itemBuilder: (context, index) {
                final tag = tags[index]; // 当前标签
                final isSelected = selectedTag == tag.name; // 判断标签是否被选中

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0), // 右侧内边距
                  child: Material(
                    color: Colors.transparent, // Material 组件透明背景
                    child: InkWell(
                      onTap: () => onTagSelected(tag.name), // 点击标签回调
                      borderRadius: BorderRadius.circular(16.0), // 圆角
                      child: GameTagItem(
                        tag: tag.name, // 标签名称
                        count: tag.count, // 标签数量
                        isSelected: isSelected, // 标签选中状态
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
