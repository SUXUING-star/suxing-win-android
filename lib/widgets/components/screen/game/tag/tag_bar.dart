// lib/widgets/components/screen/game/tag/tag_bar.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game_tag.dart';
import 'package:suxingchahui/widgets/ui/components/game/game_tag_item.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class MobileTagBar extends StatelessWidget implements PreferredSizeWidget {
  final List<GameTag> tags;
  final String? selectedTag;
  final Function(String) onTagSelected;

  const MobileTagBar({
    super.key,
    required this.tags,
    required this.selectedTag,
    required this.onTagSelected,
  });

  @override
  Size get preferredSize => Size.fromHeight(48.0);

  @override
  Widget build(BuildContext context) {
    // 背景和边框样式可以保留，也可以根据 GameTagItem 的风格进行调整
    // 这里保留了原来的背景和顶部蓝条，让它有个容器感
    return Container(
      height: preferredSize.height,
      // 使用带透明度的白色背景，与 GameTagItem 的磨砂效果更配
      color: Colors.white.withSafeOpacity(0.7),
      child: Column(
        children: [
          // 顶部蓝色条，作为视觉分隔
          Container(
            height: 2,
            color: Colors.blue,
          ),

          // 标签列表
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              // 调整了垂直内边距，使其更好地适应 GameTagItem 的尺寸
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              itemCount: tags.length,
              itemBuilder: (context, index) {
                final tag = tags[index];
                final isSelected = selectedTag == tag.name;

                // --- 核心修改在这里 ---
                // 1. 使用 Material 和 InkWell 包裹 GameTagItem，使其可以响应点击并有水波纹效果
                // 2. 将之前复杂的 UI 构建逻辑，替换为一行 GameTagItem 组件调用
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Material(
                    color: Colors.transparent, // Material 必须是透明的，否则会遮挡
                    child: InkWell(
                      onTap: () => onTagSelected(tag.name),
                      // 圆角最好和 GameTagItem 内部的圆角保持一致，以获得最佳视觉效果
                      borderRadius: BorderRadius.circular(16.0),
                      child: GameTagItem(
                        tag: tag.name,
                        count: tag.count,
                        isSelected: isSelected,
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
