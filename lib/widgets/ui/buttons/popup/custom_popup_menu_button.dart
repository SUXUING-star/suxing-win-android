import 'package:flutter/material.dart';

/// 一个可定制外观的 PopupMenuButton 封装 (已修正，正确处理 menuBackgroundColor)
class CustomPopupMenuButton<T> extends StatelessWidget {
  final PopupMenuItemBuilder<T> itemBuilder;
  final PopupMenuItemSelected<T>? onSelected;
  final IconData icon;
  final double iconSize;
  final Color? iconColor;
  final String? tooltip;
  final EdgeInsetsGeometry padding;
  final Offset offset;
  final ShapeBorder? shape;
  final double? elevation;
  // *** 确保 menuBackgroundColor 在构造函数里 ***
  final Color? menuBackgroundColor;
  final double? splashRadius;
  final bool isEnabled;
  final Widget? child; // 支持 child 的版本

  const CustomPopupMenuButton({
    super.key,
    required this.itemBuilder,
    this.onSelected,
    this.icon = Icons.more_vert,
    this.iconSize = 20.0,
    this.iconColor,
    this.tooltip,
    this.padding = const EdgeInsets.all(8.0),
    this.offset = Offset.zero,
    this.shape,
    this.elevation,
    // *** 接收 menuBackgroundColor ***
    this.menuBackgroundColor, // 允许为 null，让 PopupMenuButton 用默认值或由 Theme 控制
    this.splashRadius,
    this.isEnabled = true,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color disabledColor = theme.disabledColor;
    final Color defaultIconColor = theme.iconTheme.color ?? Colors.grey[600]!;
    final Color calculatedIconColor = iconColor ?? defaultIconColor;
    final Color effectiveIconColor = isEnabled ? calculatedIconColor : disabledColor;

    final Widget triggerWidget = child ?? Icon(
      icon,
      size: iconSize,
      color: effectiveIconColor,
    );

    return PopupMenuButton<T>(
      itemBuilder: itemBuilder,
      onSelected: isEnabled ? onSelected : null,
      tooltip: tooltip,
      offset: offset,
      shape: shape ?? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: elevation ?? 4.0,
      // *** 把接收到的 menuBackgroundColor 传递给底层 PopupMenuButton 的 color 属性 ***
      color: menuBackgroundColor, // 这才是设置菜单面板背景色的地方！
      padding: padding,
      splashRadius: splashRadius,
      enabled: isEnabled,
      child: triggerWidget,
    );
  }
}