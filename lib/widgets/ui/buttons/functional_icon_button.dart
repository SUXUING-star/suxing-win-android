// lib/widgets/ui/buttons/functional_icon_button.dart

/// 该文件定义了 FunctionalIconButton 组件，一个功能强大的图标按钮。
/// 该组件支持图标背景、加载状态、禁用状态和细粒度的颜色控制。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件

/// `FunctionalIconButton` 类：功能更强大的图标按钮组件。
///
/// 该组件支持图标背景容器、加载状态、禁用状态和自定义样式。
class FunctionalIconButton extends StatelessWidget {
  final VoidCallback? onPressed; // 按钮按下时触发的回调。加载中或为空时按钮禁用。
  final IconData icon; // 按钮上显示的图标数据。
  final String? tooltip; // 悬浮提示文本。
  final double iconSize; // 图标字形大小。
  final double containerSize; // 包裹图标的容器大小。
  final EdgeInsetsGeometry iconButtonPadding; // IconButton 自身的内边距。
  final bool isLoading; // 按钮是否处于加载状态。为 true 时显示加载指示器且按钮不可点击。
  final bool isEnabled; // 按钮是否可用。

  // --- 颜色控制 ---
  final Color? iconColor; // 图标字形颜色。
  final Color? iconBackgroundColor; // 图标背景容器的颜色。
  final Color? buttonBackgroundColor; // IconButton 按钮本身的背景色。
  final Color? splashColor; // 水波纹颜色。
  final Color? highlightColor; // 高亮色。
  final Color? hoverColor; // 悬停色。
  final Color? disabledIconColor; // 禁用时图标字形颜色。
  final Color? disabledIconBackgroundColor; // 禁用时图标背景容器颜色。
  final Color? disabledButtonBackgroundColor; // 禁用时 IconButton 按钮背景色。

  // --- 图标背景容器形状与边框 ---
  final BoxShape iconBackgroundShape; // 背景容器形状（圆形/矩形）。
  final BorderRadiusGeometry? iconBackgroundBorderRadius; // 如果是矩形，背景容器的圆角。
  final bool showIconContainerBorder; // 是否给图标背景容器添加边框。
  final Color? iconContainerBorderColor; // 背景容器边框颜色。
  final double iconContainerBorderWidth; // 背景容器边框宽度。

  // --- 加载指示器 ---
  final Color? loadingIndicatorColor; // 加载指示器颜色。
  final double loadingIndicatorStrokeWidth; // 加载指示器线条宽度。

  /// 构造函数。
  ///
  /// [onPressed]：点击回调。
  /// [icon]：图标。
  /// [tooltip]：提示。
  /// [iconSize]：图标字形大小。
  /// [containerSize]：容器大小。
  /// [iconButtonPadding]：按钮内边距。
  /// [isLoading]：是否加载中。
  /// [isEnabled]：是否可用。
  /// [iconColor]：图标字形颜色。
  /// [iconBackgroundColor]：图标背景容器颜色。
  /// [buttonBackgroundColor]：按钮背景色。
  /// [splashColor]：水波纹颜色。
  /// [highlightColor]：高亮色。
  /// [hoverColor]：悬停色。
  /// [disabledIconColor]：禁用时图标字形颜色。
  /// [disabledIconBackgroundColor]：禁用时图标背景容器颜色。
  /// [disabledButtonBackgroundColor]：禁用时按钮背景色。
  /// [iconBackgroundShape]：图标背景形状。
  /// [iconBackgroundBorderRadius]：图标背景圆角。
  /// [showIconContainerBorder]：是否显示图标容器边框。
  /// [iconContainerBorderColor]：图标容器边框颜色。
  /// [iconContainerBorderWidth]：图标容器边框宽度。
  /// [loadingIndicatorColor]：加载指示器颜色。
  /// [loadingIndicatorStrokeWidth]：加载指示器线条宽度。
  const FunctionalIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.iconSize = 24.0,
    this.containerSize = 32.0,
    this.iconButtonPadding = const EdgeInsets.all(4.0),
    this.isLoading = false,
    this.isEnabled = true,
    this.iconColor,
    this.iconBackgroundColor,
    this.buttonBackgroundColor,
    this.splashColor,
    this.highlightColor,
    this.hoverColor,
    this.disabledIconColor,
    this.disabledIconBackgroundColor,
    this.disabledButtonBackgroundColor,
    this.iconBackgroundShape = BoxShape.circle,
    this.iconBackgroundBorderRadius,
    this.showIconContainerBorder = false,
    this.iconContainerBorderColor,
    this.iconContainerBorderWidth = 1.0,
    this.loadingIndicatorColor,
    this.loadingIndicatorStrokeWidth = 2.0,
  });

  /// 构建功能图标按钮。
  ///
  /// 该方法根据按钮状态和属性生成不同的按钮内容和样式。
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context); // 获取当前主题
    final ColorScheme colorScheme = theme.colorScheme; // 获取颜色方案

    // --- 1. 解析有效状态 ---
    final bool effectiveIsEnabled = isEnabled && !isLoading; // 按钮是否有效
    final VoidCallback? effectiveOnPressed =
        effectiveIsEnabled ? onPressed : null; // 有效的点击回调

    // --- 2. 解析颜色 ---
    final Color defaultIconColor = iconColor ??
        (iconBackgroundColor != null
            ? colorScheme.onPrimaryContainer
            : colorScheme.primary); // 默认图标字形颜色
    final Color effectiveIconColor = effectiveIsEnabled
        ? defaultIconColor
        : (disabledIconColor ?? theme.disabledColor.withAlpha(150)); // 有效图标字形颜色

    final Color? effectiveIconBackgroundColor = effectiveIsEnabled
        ? iconBackgroundColor
        : disabledIconBackgroundColor; // 有效图标背景容器颜色

    final Color? effectiveIconContainerBorderColor = showIconContainerBorder
        ? effectiveIsEnabled
            ? (iconContainerBorderColor ?? colorScheme.outline.withAlpha(77))
            : theme.disabledColor.withAlpha(51)
        : null; // 有效图标背景容器边框颜色

    final Color? effectiveButtonBackgroundColor = effectiveIsEnabled
        ? buttonBackgroundColor
        : disabledButtonBackgroundColor; // 有效按钮背景色

    final Color effectiveLoadingIndicatorColor =
        loadingIndicatorColor ?? effectiveIconColor; // 有效加载指示器颜色

    // --- 3. 构建作为 IconButton 'icon' 参数的 Widget ---
    Widget iconContentWidget; // 图标内容组件

    if (isLoading) {
      // 加载状态时显示指示器
      iconContentWidget = SizedBox(
        width: containerSize, // 宽度
        height: containerSize, // 高度
        child: Center(
          child: SizedBox(
            width: iconSize * 0.8, // 宽度
            height: iconSize * 0.8, // 高度
            child: CircularProgressIndicator(
              strokeWidth: loadingIndicatorStrokeWidth, // 粗细
              color: effectiveLoadingIndicatorColor, // 颜色
            ),
          ),
        ),
      );
    } else {
      // 非加载状态时显示图标和背景容器
      iconContentWidget = Container(
        width: containerSize, // 宽度
        height: containerSize, // 高度
        decoration: BoxDecoration(
          color: effectiveIconBackgroundColor, // 图标背景色
          shape: iconBackgroundShape, // 形状
          borderRadius: (iconBackgroundShape == BoxShape.rectangle)
              ? (iconBackgroundBorderRadius ??
                  BorderRadius.circular(containerSize * 0.2))
              : null, // 圆角
          border: effectiveIconContainerBorderColor != null
              ? Border.all(
                  color: effectiveIconContainerBorderColor,
                  width: iconContainerBorderWidth,
                )
              : null, // 边框
          boxShadow: effectiveIconBackgroundColor != null
              ? [
                  // 阴影
                  BoxShadow(
                    color: Colors.black.withAlpha(30),
                    blurRadius: 3.0,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            icon, // 图标
            size: iconSize, // 大小
            color: effectiveIconColor, // 颜色
          ),
        ),
      );
    }

    // --- 4. 构建 IconButton 的样式 ---
    final ButtonStyle buttonStyle = IconButton.styleFrom(
      backgroundColor: effectiveButtonBackgroundColor, // 按钮背景色
      padding: EdgeInsets.zero, // 内边距
      minimumSize: Size(containerSize, containerSize), // 最小尺寸
      visualDensity: VisualDensity.compact, // 视觉密度
      shape: const CircleBorder(), // 形状
      alignment: Alignment.center, // 对齐方式
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        // 覆盖颜色
        (Set<WidgetState> states) {
          final Color baseOverlayColor =
              iconColor ?? colorScheme.primary; // 基础覆盖颜色
          final Color hoverOverlay =
              hoverColor ?? baseOverlayColor.withAlpha(20); // 悬停覆盖颜色
          final Color focusPressOverlay =
              splashColor ?? baseOverlayColor.withAlpha(31); // 焦点按下覆盖颜色

          if (!effectiveIsEnabled) return null; // 禁用时不显示覆盖颜色

          if (states.contains(WidgetState.hovered)) return hoverOverlay; // 悬停状态
          if (states.contains(WidgetState.focused) ||
              states.contains(WidgetState.pressed)) {
            // 焦点或按下状态
            return focusPressOverlay;
          }
          return null;
        },
      ),
    );

    // --- 5. 构建最终的 IconButton ---
    return IconButton(
      icon: iconContentWidget, // 图标内容组件
      onPressed: effectiveOnPressed, // 点击回调
      tooltip: tooltip, // 提示
      iconSize: containerSize, // 图标大小
      padding: iconButtonPadding, // 内边距
      alignment: Alignment.center, // 对齐方式
      style: buttonStyle, // 样式
    );
  }
}
