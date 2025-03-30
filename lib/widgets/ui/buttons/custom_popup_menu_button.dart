// lib/widgets/ui/buttons/custom_popup_menu_button.dart
import 'package:flutter/material.dart';

/// 一个可定制外观的 PopupMenuButton 封装
class CustomPopupMenuButton<T> extends StatelessWidget {
  /// 构建菜单项列表的回调函数
  final PopupMenuItemBuilder<T> itemBuilder;

  /// 菜单项被选中时的回调函数
  final PopupMenuItemSelected<T>? onSelected;

  /// 触发按钮的图标数据，默认为 Icons.more_vert
  final IconData icon;

  /// 触发按钮图标的大小，默认为 20.0
  final double iconSize;

  /// 触发按钮图标的颜色，默认为主题色或灰色
  final Color? iconColor;

  /// 按钮的提示文本
  final String? tooltip;

  /// 触发按钮周围的内边距，默认为 8.0
  final EdgeInsetsGeometry padding;

  /// 菜单弹出位置相对于按钮的偏移量
  final Offset offset;

  /// 菜单本身的形状，默认为圆角矩形
  final ShapeBorder? shape;

  /// 菜单的海拔高度（阴影）
  final double? elevation;

  /// 菜单的背景颜色
  final Color? menuBackgroundColor;

  /// 点击波纹效果的半径
  final double? splashRadius;

  const CustomPopupMenuButton({
    Key? key,
    required this.itemBuilder,
    this.onSelected,
    this.icon = Icons.more_vert, // 默认图标
    this.iconSize = 20.0, // 默认稍小的图标尺寸
    this.iconColor,
    this.tooltip,
    this.padding = const EdgeInsets.all(8.0), // 默认内边距
    this.offset = Offset.zero,
    this.shape,
    this.elevation,
    this.menuBackgroundColor = Colors.white,
    this.splashRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // 决定实际使用的图标颜色
    final Color effectiveIconColor = iconColor ?? theme.iconTheme.color ?? Colors.grey[600]!;

    return PopupMenuButton<T>(
      itemBuilder: itemBuilder,
      onSelected: onSelected,
      tooltip: tooltip,
      offset: offset,
      // 提供一个默认的圆角形状，除非外部传入了 shape
      shape: shape ?? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: elevation ?? 4.0, // 提供一个默认的海拔高度
      color: menuBackgroundColor, // 菜单背景色
      padding: padding, // 应用内边距
      splashRadius: splashRadius ?? iconSize * 1.2, // 基于图标大小计算默认波纹半径
      iconSize: iconSize, // 这个参数会影响按钮的可点击区域和布局大小
      // 直接使用 icon 参数来显示图标，更简洁
      icon: Icon(
        icon,
        // iconSize 参数已经处理了大小
        color: effectiveIconColor,
      ),
    );
  }
}