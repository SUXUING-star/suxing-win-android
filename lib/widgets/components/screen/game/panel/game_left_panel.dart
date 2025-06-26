// lib/widgets/components/screen/game/panel/game_left_panel.dart

/// 该文件定义了 [GameLeftPanel ]组件，用于显示游戏列表的左侧面板。
/// [GameLeftPanel ]展示热门标签并提供标签筛选功能。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:suxingchahui/models/game/game_tag.dart'; // 游戏标签模型所需
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // 错误组件所需
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 加载组件所需
import 'package:suxingchahui/widgets/ui/components/game/game_tag_item.dart'; // 游戏标签项组件所需
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展方法所需

/// [GameLeftPanel] 类：显示游戏列表左侧面板的 StatelessWidget。
///
/// 该组件负责渲染热门标签列表，并处理标签的选择和清除操作。
class GameLeftPanel extends StatelessWidget {
  final double panelWidth; // 面板宽度
  final String? errorMessage; // 错误信息
  final bool isTagLoading; // 标签加载状态
  final Function(bool forceRefresh) refreshTags; // 刷新标签的回调
  final List<GameTag> tags; // 游戏标签列表
  final String? selectedTag; // 当前选中的标签
  final Function(String?) onTagSelected; // 标签选择回调

  /// 构造函数。
  ///
  /// [errorMessage]：错误信息。
  /// [isTagLoading]：标签加载状态。
  /// [refreshTags]：刷新标签的回调。
  /// [panelWidth]：面板宽度。
  /// [tags]：游戏标签列表。
  /// [selectedTag]：当前选中的标签。
  /// [onTagSelected]：标签选择回调。
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
    return Container(
      width: panelWidth, // 设置面板宽度
      margin: const EdgeInsets.all(8), // 外边距
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12), // 圆角裁剪
        child: Container(
          color: Colors.white.withSafeOpacity(0.8), // 背景颜色
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.all(12), // 内边距
                color: Theme.of(context).primaryColor, // 标题栏背景色
                child: Row(
                  children: [
                    const Icon(Icons.label,
                        color: Colors.white, size: 16), // 标签图标
                    const SizedBox(width: 8), // 间距
                    const Text(
                      '热门标签',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(), // 占据剩余空间
                    if (selectedTag != null) // 选中标签存在时显示清除按钮
                      InkWell(
                        onTap: () => onTagSelected(null), // 点击清除标签
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2), // 内边距
                          decoration: BoxDecoration(
                            color: Colors.white.withSafeOpacity(0.3), // 背景颜色
                            borderRadius: BorderRadius.circular(12), // 圆角
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.close,
                                  size: 12, color: Colors.white), // 关闭图标
                              SizedBox(width: 4), // 间距
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
                  padding: const EdgeInsets.all(12), // 内边距
                  child: _buildTagsWrap(context), // 构建标签列表
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建标签列表。
  ///
  /// [context]：Build 上下文。
  /// 使用 Wrap 布局，自动换行显示标签项。
  Widget _buildTagsWrap(BuildContext context) {
    if (errorMessage != null) {
      // 存在错误信息时显示错误组件
      return InlineErrorWidget(
        errorMessage: '加载标签发生错误',
        icon: Icons.label_off,
        iconSize: 32,
        iconColor: Colors.grey[400],
        onRetry: () => refreshTags(true), // 刷新标签回调
      );
    }
    if (tags.isEmpty) {
      return InlineErrorWidget(
        errorMessage: "没有加载到任何标签",
        icon: Icons.label_off,
        iconSize: 32,
        iconColor: Colors.grey[400],
        onRetry: () => refreshTags(true), // 刷新标签回调
      );
    }

    if (isTagLoading) {
      // 标签加载中时显示加载组件
      return const LoadingWidget(
        size: 24,
      );
    }

    return Wrap(
      spacing: 8.0, // 标签项之间的水平间距
      runSpacing: 8.0, // 标签行之间的垂直间距
      children: tags.map((tag) {
        // 遍历标签列表
        final isSelected = selectedTag == tag.name; // 判断标签是否被选中

        return InkWell(
          onTap: () => onTagSelected(tag.name), // 点击标签回调
          borderRadius: BorderRadius.circular(16.0), // 圆角
          child: GameTagItem(
            tag: tag.name, // 标签名称
            count: tag.count, // 标签数量
            isSelected: isSelected, // 标签选中状态
          ),
        );
      }).toList(),
    );
  }
}
