// lib/widgets/ui/buttons/floating_action_button_group.dart
import 'package:flutter/material.dart';

/// 一个用于垂直排列多个悬浮按钮（或类似外观的 Widget）的组件。
///
/// 通常放置在 Scaffold 的 floatingActionButton 属性中。
class FloatingActionButtonGroup extends StatelessWidget {
  /// 要在组中显示的 Widget 列表。
  /// 通常是 FloatingActionButton、GenericFloatingActionButton
  /// 或其他视觉上适配的小部件（如自定义的 LikeButton）。
  final List<Widget> children;

  /// 按钮之间的垂直间距。
  final double spacing;

  /// 按钮在垂直方向上的对齐方式。
  /// 对于 FAB，通常使用 MainAxisAlignment.end。
  final MainAxisAlignment alignment;

  /// 控制 Column 如何占据主轴空间。
  /// 对于 FAB 组，应使用 MainAxisSize.min 以避免占据整个屏幕高度。
  final MainAxisSize mainAxisSize;

  const FloatingActionButtonGroup({
    super.key,
    required this.children,
    this.spacing = 16.0, // 默认间距
    this.alignment = MainAxisAlignment.end, // 默认底部对齐
    this.mainAxisSize = MainAxisSize.min, // 默认最小化占用空间
  });

  @override
  Widget build(BuildContext context) {
    // 过滤掉 null 子项，以防传入的列表包含条件性 null
    final validChildren = children.where((child) => child != null).toList();

    // 如果没有有效的子项，则返回一个空容器
    if (validChildren.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisAlignment: alignment,
      mainAxisSize: mainAxisSize,
      // 使用 map 和 expand 添加间距，确保只在元素之间添加
      children: validChildren
          .expand((widget) => [
        widget,
        // 只在非最后一个元素后添加 SizedBox
        if (widget != validChildren.last) SizedBox(height: spacing),
      ])
          .toList(),

      // --- 或者使用下面的手动构建列表方法 (更清晰一点) ---
      // children: _buildChildrenWithSpacing(validChildren),
    );
  }

/* // 可选的构建方法，更清晰地处理间距
  List<Widget> _buildChildrenWithSpacing(List<Widget> validChildren) {
    if (validChildren.isEmpty) return [];

    final List<Widget> spacedChildren = [];
    for (int i = 0; i < validChildren.length; i++) {
      spacedChildren.add(validChildren[i]);
      // 如果不是最后一个元素，则在后面添加间距
      if (i < validChildren.length - 1) {
        spacedChildren.add(SizedBox(height: spacing));
      }
    }
    return spacedChildren;
  }
  */
}