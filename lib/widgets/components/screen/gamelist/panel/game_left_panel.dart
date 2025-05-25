// lib/widgets/components/screen/gamelist/panel/game_left_panel.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game_tag.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/components/game/game_tag.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class GameLeftPanel extends StatelessWidget {
  final List<GameTag> tags;
  final String? selectedTag;
  final Function(String?) onTagSelected;

  const GameLeftPanel({
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
      margin: EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: 0.8, // 透明度可以按需调整
          child: Container(
            color: Colors.white, // 背景色可以按需调整
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题栏
                Container(
                  padding: EdgeInsets.all(12),
                  color: Theme.of(context).primaryColor,
                  child: Row(
                    children: [
                      Icon(Icons.label, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        '热门标签',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Spacer(), // <--- 使用 Spacer 把清除按钮推到最右边
                      if (selectedTag != null)
                        InkWell(
                          // onTap: () => onTagSelected(selectedTag!), // 旧逻辑
                          onTap: () =>
                              onTagSelected(null), // <--- 点击清除按钮时传递 null
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withSafeOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.close,
                                    size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  '清除',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 标签区域
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(12),
                    child: _buildTagsGrid(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagsGrid(BuildContext context) {
    if (tags.isEmpty) {
      return InlineErrorWidget(
        errorMessage: '加载标签发生错误',
        icon: Icons.label_off,
        iconSize: 32,
        iconColor: Colors.grey[400],
      );
    }

    // --- 参数可以调 ---
    final double itemAspectRatio = 3.0; // 宽高比，可能还要调
    final double cornerRadius = 12.0; // <--- 加大圆角！整个标签区域用这个圆角
    final double gridSpacing = 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: itemAspectRatio,
        crossAxisSpacing: gridSpacing,
        mainAxisSpacing: gridSpacing,
      ),
      itemCount: tags.length,
      itemBuilder: (context, index) {
        final tag = tags[index];
        final isSelected = selectedTag == tag.name;

        // 用 ClipRRect 来强制圆角，InkWell 的水波纹也会是圆角的
        return ClipRRect(
          borderRadius: BorderRadius.circular(cornerRadius), // <--- 用统一的大圆角
          child: InkWell(
            onTap: () => onTagSelected(tag.name),
            child: Container(
              // **核心改动：背景色处理**
              color: isSelected
                  ? Theme.of(context)
                      .primaryColor
                      .withSafeOpacity(0.1) // 选中时淡主色背景
                  : Colors.transparent, // **未选中时完全透明！干掉那个傻逼边框和背景！**

              child: Padding(
                // 微调 GameTag 周围的 Padding，让它呼吸一下
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                child: GameTagItem(
                  tag: tag.name,
                  count: tag.count,
                  isSelected: isSelected,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
