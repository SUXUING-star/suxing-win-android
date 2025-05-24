// lib/widgets/ui/buttons/functional_icon_button.dart
import 'package:flutter/material.dart';

/// 一个功能更强大的 IconButton，支持：
/// - 图标背景容器 (颜色、形状、边框)
/// - 加载状态 (显示指示器)
/// - 禁用状态
/// - Tooltip
/// - 细粒度的颜色控制
/// - 紧凑的视觉密度和内边距控制
class FunctionalIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final double iconSize; // 图标字形大小
  final double containerSize; // 包裹图标的容器大小 (会影响背景区域)
  final EdgeInsetsGeometry iconButtonPadding; // IconButton 自身的内边距
  final bool isLoading;
  final bool isEnabled;

  // --- 颜色控制 ---
  final Color? iconColor; // 图标字形颜色
  final Color? iconBackgroundColor; // 图标背景容器的颜色
  final Color? buttonBackgroundColor; // IconButton 按钮本身的背景色 (容器外部)
  final Color? splashColor; // 水波纹颜色 (会被 overlayColor 覆盖)
  final Color? highlightColor; // 高亮色 (会被 overlayColor 覆盖)
  final Color? hoverColor; // 悬停色 (会被 overlayColor 覆盖)
  final Color? disabledIconColor; // 禁用时图标字形颜色
  final Color? disabledIconBackgroundColor; // 禁用时图标背景容器颜色
  final Color? disabledButtonBackgroundColor; // 禁用时 IconButton 按钮背景色

  // --- 图标背景容器形状与边框 ---
  final BoxShape iconBackgroundShape; // 背景容器形状 (圆形/矩形)
  final BorderRadiusGeometry? iconBackgroundBorderRadius; // 如果是矩形，圆角多少
  final bool showIconContainerBorder; // 是否给图标背景容器加边框
  final Color? iconContainerBorderColor; // 背景容器边框颜色
  final double iconContainerBorderWidth; // 背景容器边框宽度

  // --- 加载指示器 ---
  final Color? loadingIndicatorColor; // 加载指示器颜色
  final double loadingIndicatorStrokeWidth; // 加载指示器粗细

  const FunctionalIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.iconSize = 24.0,
    this.containerSize = 32.0, // 默认容器比图标大
    // *** 默认的 IconButton 内边距设为较小值 ***
    this.iconButtonPadding = const EdgeInsets.all(4.0),
    this.isLoading = false,
    this.isEnabled = true,
    // --- Colors ---
    this.iconColor,
    this.iconBackgroundColor,
    this.buttonBackgroundColor,
    this.splashColor,
    this.highlightColor,
    this.hoverColor,
    this.disabledIconColor,
    this.disabledIconBackgroundColor,
    this.disabledButtonBackgroundColor,
    // --- Icon Background Container ---
    this.iconBackgroundShape = BoxShape.circle,
    this.iconBackgroundBorderRadius,
    this.showIconContainerBorder = false,
    this.iconContainerBorderColor,
    this.iconContainerBorderWidth = 1.0,
    // --- Loading ---
    this.loadingIndicatorColor,
    this.loadingIndicatorStrokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    // --- 1. 解析有效状态 ---
    final bool effectiveIsEnabled = isEnabled && !isLoading;
    final VoidCallback? effectiveOnPressed =
        effectiveIsEnabled ? onPressed : null;

    // --- 2. 解析颜色 ---
    // 图标字形颜色
    final Color defaultIconColor = iconColor ??
        (iconBackgroundColor != null
            ? colorScheme.onPrimaryContainer
            : colorScheme.primary); // 优先用 onPrimaryContainer
    final Color effectiveIconColor = effectiveIsEnabled
        ? defaultIconColor
        : (disabledIconColor ?? theme.disabledColor.withAlpha(150)); // 禁用颜色稍微调淡

    // 图标背景容器颜色
    final Color? effectiveIconBackgroundColor = effectiveIsEnabled
        ? iconBackgroundColor // 启用时直接用
        : disabledIconBackgroundColor; // 禁用时用

    // 图标背景容器边框颜色
    final Color? effectiveIconContainerBorderColor = showIconContainerBorder
        ? effectiveIsEnabled
            ? (iconContainerBorderColor ??
                colorScheme.outline.withAlpha(77)) // 默认用 outline 30%
            : theme.disabledColor.withAlpha(51) // 禁用时更淡 20%
        : null;

    // IconButton 按钮本身的背景色
    final Color? effectiveButtonBackgroundColor = effectiveIsEnabled
        ? buttonBackgroundColor
        : disabledButtonBackgroundColor;

    // 加载指示器颜色
    final Color effectiveLoadingIndicatorColor =
        loadingIndicatorColor ?? effectiveIconColor;

    // --- 3. 构建作为 IconButton 'icon' 参数的 Widget ---
    Widget iconContentWidget;

    if (isLoading) {
      // 加载状态：显示指示器，大小适配 containerSize
      iconContentWidget = SizedBox(
        width: containerSize,
        height: containerSize,
        child: Center(
          // 确保指示器居中
          child: SizedBox(
            // 指示器大小基于 iconSize 更合理
            width: iconSize * 0.8,
            height: iconSize * 0.8,
            child: CircularProgressIndicator(
              strokeWidth: loadingIndicatorStrokeWidth,
              color: effectiveLoadingIndicatorColor,
            ),
          ),
        ),
      );
    } else {
      // 非加载状态：构建 "图标 + 背景容器"
      iconContentWidget = Container(
        width: containerSize,
        height: containerSize,
        decoration: BoxDecoration(
          color: effectiveIconBackgroundColor, // 应用图标背景色
          shape: iconBackgroundShape,
          borderRadius: (iconBackgroundShape == BoxShape.rectangle)
              ? (iconBackgroundBorderRadius ??
                  BorderRadius.circular(containerSize * 0.2)) // 矩形默认给点圆角
              : null,
          border: effectiveIconContainerBorderColor != null
              ? Border.all(
                  color: effectiveIconContainerBorderColor,
                  width: iconContainerBorderWidth,
                )
              : null, // 应用容器边框
          //可以考虑添加阴影效果
          boxShadow: effectiveIconBackgroundColor != null
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(30),
                    blurRadius: 3.0,
                    offset: Offset(0, 1),
                  )
                ]
              : null,
        ),
        // 使用 Center 确保图标在容器内居中
        child: Center(
          child: Icon(
            icon,
            size: iconSize,
            color: effectiveIconColor, // 应用图标字形颜色
          ),
        ),
      );
    }

    // --- 4. 构建 IconButton 的样式 (ButtonStyle) ---
    final ButtonStyle buttonStyle = IconButton.styleFrom(
      // IconButton 的背景色，如果设置了，会在 iconContentWidget 后面
      backgroundColor: effectiveButtonBackgroundColor,
      // disabledBackgroundColor: disabledButtonBackgroundColor, // 按钮自身的禁用背景
      padding:
          EdgeInsets.zero, // Style 的 padding 设为 0, 由 IconButton 的 padding 参数控制
      minimumSize: Size(containerSize, containerSize), // 最小尺寸基于容器
      // *** 设置 visualDensity 为 compact ***
      visualDensity: VisualDensity.compact, // 让按钮更紧凑，减少固有间距
      shape: const CircleBorder(), // IconButton 本身通常是圆形或体育场形状的点击区域
      alignment: Alignment.center,
    ).copyWith(
      // 使用 WidgetStateProperty 控制覆盖色 (水波纹、悬停等)
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          // 基于按钮的前景色或图标颜色来计算覆盖色
          final Color baseOverlayColor = iconColor ?? colorScheme.primary;
          // 使用 alpha 值设置透明度 (0-255)
          final Color hoverOverlay =
              hoverColor ?? baseOverlayColor.withAlpha(20); // ~8%
          final Color focusPressOverlay =
              splashColor ?? baseOverlayColor.withAlpha(31); // ~12%

          if (!effectiveIsEnabled) return null; // 禁用时不显示覆盖色

          if (states.contains(WidgetState.hovered)) return hoverOverlay;
          if (states.contains(WidgetState.focused) ||
              states.contains(WidgetState.pressed)) {
            return focusPressOverlay;
          }
          return null;
        },
      ),
    );

    // --- 5. 构建最终的 IconButton ---
    return IconButton(
      icon: iconContentWidget, // ** 把我们精心构建的 "图标+背景容器" Widget 传给 icon **
      onPressed: effectiveOnPressed,
      tooltip: tooltip, // 设置 tooltip
      iconSize: containerSize, // IconButton 的 iconSize 应该匹配我们容器的大小
      // *** 应用 iconButtonPadding ***
      padding: iconButtonPadding, // 应用 IconButton 的整体 padding
      alignment: Alignment.center,
      style: buttonStyle, // 应用按钮样式
      // color 和 disabledColor 在 style 中已处理，通常无需显式设置
      // color: effectiveIconColor,
      // disabledColor: disabledIconColor ?? theme.disabledColor.withAlpha(150),
    );
  }
}
