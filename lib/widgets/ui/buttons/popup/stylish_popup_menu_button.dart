// lib/widgets/ui/buttons/popup/stylish_popup_menu_button.dart

import 'package:flutter/material.dart';

// 导入你的数据类定义
class StylishPopupMenuButton<T> extends StatelessWidget {
  // --- 触发按钮相关 ---
  final IconData? icon; // 触发图标 (可选)
  final Widget? child; // 自定义触发 Widget (可选, 优先于 icon)
  final double iconSize;
  final Color? iconColor;
  final EdgeInsetsGeometry triggerPadding; // 触发按钮的内边距

  // --- 菜单数据和行为 ---
  /// 菜单项数据列表 (核心！)
  final List<StylishMenuItemData<T?>> items;
  final PopupMenuItemSelected<T>? onSelected;
  final String? tooltip;
  final bool isEnabled; // 整个按钮是否可用

  // --- 菜单外观 ---
  final Color? menuColor; // 菜单背景色
  final double? elevation; // 菜单阴影
  final ShapeBorder? shape; // 菜单形状
  final Offset offset; // 菜单偏移量
  final double itemHeight; // 统一的菜单项高度
  final EdgeInsetsGeometry itemPadding; // 统一的菜单项内边距

  const StylishPopupMenuButton({
    super.key,
    required this.items,
    this.onSelected,
    // --- 触发器 ---
    this.icon,
    this.child,
    this.iconSize = 24.0,
    this.iconColor,
    this.triggerPadding = const EdgeInsets.all(8.0),
    // --- 行为 ---
    this.tooltip,
    this.isEnabled = true,
    // --- 外观 ---
    this.menuColor = Colors.white,
    this.elevation, // 允许为 null，使用默认
    this.shape, // 允许为 null，使用默认
    this.offset = Offset.zero,
    // --- Item 外观 ---
    this.itemHeight = 42.0, // 默认 Item 高度
    this.itemPadding = const EdgeInsets.symmetric(
        horizontal: 16.0, vertical: 12.0), // 默认 Item 内边距
  }) : assert(icon != null || child != null,
            'Either icon or child must be provided.');

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color effectiveMenuColor = menuColor ?? theme.canvasColor; // 决定菜单背景色
    final ShapeBorder effectiveShape = shape ??
        RoundedRectangleBorder(
          // 决定菜单形状
          borderRadius: BorderRadius.circular(8.0),
        );

    // 决定触发器 Widget
    final Widget trigger = child ??
        Icon(
          icon,
          size: iconSize,
          color: isEnabled
              ? (iconColor ?? theme.iconTheme.color)
              : theme.disabledColor,
        );

    // *** 直接使用底层的 PopupMenuButton ***
    return PopupMenuButton<T>(
      tooltip: tooltip,
      enabled: isEnabled,
      offset: offset,
      padding: triggerPadding, // 应用触发器 padding
      color: effectiveMenuColor, // 应用菜单背景色
      elevation: elevation ?? 2.0, // 应用阴影
      shape: effectiveShape, // 应用形状
      onSelected: onSelected, // 传递回调

      // *** 核心：内部实现的 itemBuilder，直接构建带样式的 PopupMenuItem ***
      itemBuilder: (BuildContext context) {
        final entries = <PopupMenuEntry<T>>[];

        if (items.isEmpty) {
          // 处理空列表
          entries.add(_buildDisabledItem(context, '无可用操作'));
          return entries;
        }

        for (int i = 0; i < items.length; i++) {
          final itemData = items[i];

          if (itemData is StylishMenuDividerData) {
            // 添加分割线 (避免连续分割线或首尾分割线)
            if (i > 0 && items[i - 1] is! StylishMenuDividerData) {
              entries.add(const PopupMenuDivider(height: 1));
            }
          } else if (itemData.value != null) {
            // 添加普通菜单项
            entries.add(
              PopupMenuItem<T>(
                // **标准 PopupMenuItem**
                value: itemData.value as T,
                enabled: itemData.enabled,
                padding: EdgeInsets.zero, // **关键：移除外部 padding**
                height: itemHeight, // **使用统一高度**

                // *** 关键：child 直接构建漂亮 UI ***
                child: _buildItemContent(
                    context,
                    itemData.child,
                    itemData.enabled,
                    itemData.value == null // 理论上不会是 null 了，但加个判断
                    // 可以根据 value == 当前选中值 来高亮，但这需要外部传入当前值
                    ),
              ),
            );
          }
        }
        // 移除末尾可能多余的分割线
        if (entries.isNotEmpty && entries.last is PopupMenuDivider) {
          entries.removeLast();
        }
        return entries;
      },
      child: trigger, // 使用我们计算好的触发器
    );
  }

  // --- 内部辅助方法，构建 Item 的内容 UI ---
  Widget _buildItemContent(
      BuildContext context, Widget child, bool enabled, bool isSelected) {
    final theme = Theme.of(context);
    // 这里可以根据 enabled 和 isSelected (如果需要高亮) 调整样式
    final Color textColor = enabled
        ? theme.textTheme.bodyLarge?.color ?? Colors.black87
        : theme.disabledColor;

    // 使用 Container 提供背景和内边距
    return Container(
      width: double.infinity, // 填满宽度
      // color: isSelected ? theme.highlightColor : null, // 如果需要选中高亮背景
      padding: itemPadding,
      child: DefaultTextStyle(
        // 统一设置文字样式
        style: TextStyle(color: textColor, fontSize: 14), // 调整基础样式
        child: child,
      ),
    );
  }

  // --- 内部辅助方法，构建禁用的提示 Item ---
  PopupMenuItem<T> _buildDisabledItem(BuildContext context, String text) {
    // final theme = Theme.of(context);
    return PopupMenuItem<T>(
      value: null, // 没有有效值
      enabled: false,
      padding: EdgeInsets.zero,
      height: itemHeight,
      child: _buildItemContent(context, Text(text), false, false),
    );
  }
}

/// 描述一个菜单项的数据
class StylishMenuItemData<T> {
  final T value;
  final Widget child; // 你想显示的内容
  final bool enabled;

  const StylishMenuItemData({
    required this.value,
    required this.child,
    this.enabled = true,
  });
}

/// 特殊类型，表示分割线
class StylishMenuDividerData<T> extends StylishMenuItemData<T?> {
  const StylishMenuDividerData()
      : super(value: null, child: const SizedBox.shrink());
}
