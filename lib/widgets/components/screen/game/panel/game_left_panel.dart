// lib/widgets/components/screen/game/panel/game_left_panel.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game_tag.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/components/game/game_tag_item.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class GameLeftPanel extends StatelessWidget {
  final double panelWidth;
  final String? errorMessage;
  final bool isTagLoading;
  final Function() refreshTags;
  final List<GameTag> tags;
  final String? selectedTag;
  final Function(String?) onTagSelected;

  const GameLeftPanel({
    super.key,
    this.errorMessage,
    required this.isTagLoading,
    required this.refreshTags,
    required this.panelWidth,
    required this.tags,
    required this.selectedTag,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    // 整体容器和标题栏样式保持不变
    return Container(
      width: panelWidth,
      margin: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: Colors.white.withSafeOpacity(0.8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.all(12),
                color: Theme.of(context).primaryColor,
                child: Row(
                  children: [
                    const Icon(Icons.label, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      '热门标签',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (selectedTag != null)
                      InkWell(
                        onTap: () => onTagSelected(null), // 点击清除
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withSafeOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.close, size: 12, color: Colors.white),
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
                  padding: const EdgeInsets.all(12),
                  // 调用新的 _buildTagsWrap 方法
                  child: _buildTagsWrap(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 使用 Wrap 布局来构建标签列表，自动换行，更灵活。
  Widget _buildTagsWrap(BuildContext context) {
    if (errorMessage != null) {
      return InlineErrorWidget(
        errorMessage: '加载标签发生错误',
        icon: Icons.label_off,
        iconSize: 32,
        iconColor: Colors.grey[400],
        onRetry: () => refreshTags(),
      );
    }

    if (isTagLoading) {
      return const LoadingWidget(
        size: 24,
      );
    }

    return Wrap(
      spacing: 8.0, // 标签之间的水平间距
      runSpacing: 8.0, // 标签之间的垂直间距
      children: tags.map((tag) {
        final isSelected = selectedTag == tag.name;

        // 使用 InkWell 包裹 GameTagItem 来添加点击事件和水波纹效果
        // GameTagItem 本身只负责显示，不处理点击
        return InkWell(
          onTap: () => onTagSelected(tag.name),
          borderRadius: BorderRadius.circular(16.0), // 匹配 GameTagItem 的圆角
          child: GameTagItem(
            tag: tag.name,
            count: tag.count,
            isSelected: isSelected,
          ),
        );
      }).toList(),
    );
  }
}
