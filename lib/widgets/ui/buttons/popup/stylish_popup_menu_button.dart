// lib/widgets/ui/buttons/popup/stylish_popup_menu_button.dart

/// 该文件定义了 StylishPopupMenuButton 组件，一个带有自定义样式和行为的弹出菜单按钮。
/// 该组件支持自定义触发器和菜单项的外观，并处理选中事件。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件

/// `StylishPopupMenuButton` 类：带有自定义样式和行为的弹出菜单按钮组件。
///
/// 该组件支持自定义图标或子组件作为触发器，并显示可定制外观的菜单项列表。
class StylishPopupMenuButton<T> extends StatelessWidget {
  /// 触发按钮相关属性。
  final IconData? icon; // 触发按钮图标
  final Widget? child; // 自定义触发按钮组件，优先于图标
  final double iconSize; // 触发图标大小
  final Color? iconColor; // 触发图标颜色
  final EdgeInsetsGeometry triggerPadding; // 触发按钮的内边距

  /// 菜单数据和行为属性。
  final List<StylishMenuItemData<T?>> items; // 菜单项数据列表
  final PopupMenuItemSelected<T>? onSelected; // 菜单项选中回调
  final String? tooltip; // 悬浮提示文本
  final bool isEnabled; // 整个按钮是否可用

  /// 菜单外观属性。
  final Color? menuColor; // 菜单背景色
  final double? elevation; // 菜单阴影
  final ShapeBorder? shape; // 菜单形状
  final Offset offset; // 菜单偏移量
  final double itemHeight; // 统一的菜单项高度
  final EdgeInsetsGeometry itemPadding; // 统一的菜单项内边距

  /// 构造函数。
  ///
  /// [items]：菜单项列表。
  /// [onSelected]：选中回调。
  /// [icon]：图标。
  /// [child]：子组件。
  /// [iconSize]：图标大小。
  /// [iconColor]：图标颜色。
  /// [triggerPadding]：触发器内边距。
  /// [tooltip]：提示。
  /// [isEnabled]：是否可用。
  /// [menuColor]：菜单颜色。
  /// [elevation]：阴影。
  /// [shape]：形状。
  /// [offset]：偏移量。
  /// [itemHeight]：项高度。
  /// [itemPadding]：项内边距。
  const StylishPopupMenuButton({
    super.key,
    required this.items,
    this.onSelected,
    this.icon,
    this.child,
    this.iconSize = 24.0,
    this.iconColor,
    this.triggerPadding = const EdgeInsets.all(8.0),
    this.tooltip,
    this.isEnabled = true,
    this.menuColor = Colors.white,
    this.elevation,
    this.shape,
    this.offset = Offset.zero,
    this.itemHeight = 42.0,
    this.itemPadding =
        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
  }) : assert(icon != null || child != null, '必须提供一个图标或一个子组件。');

  /// 构建弹出菜单按钮。
  ///
  /// 该方法根据配置生成触发器和菜单项列表，并显示弹出菜单。
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context); // 获取当前主题
    final Color effectiveMenuColor = menuColor ?? theme.canvasColor; // 有效菜单背景色
    final ShapeBorder effectiveShape = shape ??
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0), // 默认圆角
        );

    final Widget trigger = child ?? // 触发器组件
        Icon(
          icon, // 图标
          size: iconSize, // 大小
          color: isEnabled // 颜色
              ? (iconColor ?? theme.iconTheme.color)
              : theme.disabledColor,
        );

    return PopupMenuButton<T>(
      tooltip: tooltip, // 提示
      enabled: isEnabled, // 是否启用
      offset: offset, // 偏移量
      padding: triggerPadding, // 触发器内边距
      color: effectiveMenuColor, // 菜单背景色
      elevation: elevation ?? 2.0, // 阴影
      shape: effectiveShape, // 形状
      onSelected: onSelected, // 选中回调

      itemBuilder: (BuildContext context) {
        final entries = <PopupMenuEntry<T>>[]; // 菜单项列表

        if (items.isEmpty) {
          // 列表为空时添加禁用项
          entries.add(_buildDisabledItem(context, '无可用操作'));
          return entries;
        }

        for (int i = 0; i < items.length; i++) {
          final itemData = items[i];

          if (itemData is StylishMenuDividerData) {
            // 添加分割线
            if (i > 0 && items[i - 1] is! StylishMenuDividerData) {
              entries.add(const PopupMenuDivider(height: 1)); // 添加分割线
            }
          } else if (itemData.value != null) {
            // 添加普通菜单项
            entries.add(
              PopupMenuItem<T>(
                value: itemData.value as T, // 菜单项值
                enabled: itemData.enabled, // 是否启用
                padding: EdgeInsets.zero, // 移除内边距
                height: itemHeight, // 项高度

                child: _buildItemContent(
                    // 构建项内容
                    context,
                    itemData.child,
                    itemData.enabled,
                    itemData.value == null),
              ),
            );
          }
        }
        if (entries.isNotEmpty && entries.last is PopupMenuDivider) {
          // 移除末尾多余的分割线
          entries.removeLast();
        }
        return entries;
      },
      child: trigger, // 触发器组件
    );
  }

  /// 内部辅助方法：构建菜单项的内容 UI。
  ///
  /// [context]：Build 上下文。
  /// [child]：菜单项的子组件。
  /// [enabled]：菜单项是否启用。
  /// [isSelected]：菜单项是否选中。
  /// 返回菜单项的内容组件。
  Widget _buildItemContent(
      BuildContext context, Widget child, bool enabled, bool isSelected) {
    final theme = Theme.of(context);
    final Color textColor = enabled // 文本颜色
        ? theme.textTheme.bodyLarge?.color ?? Colors.black87
        : theme.disabledColor;

    return Container(
      width: double.infinity, // 宽度填满
      padding: itemPadding, // 内边距
      child: DefaultTextStyle(
        // 统一文本样式
        style: TextStyle(color: textColor, fontSize: 14),
        child: child, // 子组件
      ),
    );
  }

  /// 内部辅助方法：构建禁用的提示菜单项。
  ///
  /// [context]：Build 上下文。
  /// [text]：提示文本。
  /// 返回禁用的提示菜单项。
  PopupMenuItem<T> _buildDisabledItem(BuildContext context, String text) {
    return PopupMenuItem<T>(
      value: null, // 无有效值
      enabled: false, // 禁用
      padding: EdgeInsets.zero, // 内边距
      height: itemHeight, // 项高度
      child: _buildItemContent(context, Text(text), false, false), // 内容
    );
  }
}

/// `StylishMenuItemData` 类：描述一个菜单项的数据。
///
/// 封装了菜单项的值、显示内容和启用状态。
class StylishMenuItemData<T> {
  final T value; // 菜单项的值
  final Widget child; // 菜单项要显示的内容
  final bool enabled; // 菜单项是否启用

  /// 构造函数。
  ///
  /// [value]：值。
  /// [child]：子组件。
  /// [enabled]：是否启用。
  const StylishMenuItemData({
    required this.value,
    required this.child,
    this.enabled = true,
  });
}

/// `StylishMenuDividerData` 类：表示菜单分割线。
///
/// 继承自 [StylishMenuItemData]，用于在菜单中添加分割线。
class StylishMenuDividerData<T> extends StylishMenuItemData<T?> {
  /// 构造函数。
  const StylishMenuDividerData()
      : super(value: null, child: const SizedBox.shrink());
}
