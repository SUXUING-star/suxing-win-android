// lib/widgets/ui/buttons/generic_fab.dart

/// 该文件定义了 GenericFloatingActionButton 组件，一个通用的悬浮动作按钮。
/// 该组件支持自定义图标、颜色、工具提示和加载状态处理。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件

/// `GenericFloatingActionButton` 类：一个通用的悬浮动作按钮组件。
///
/// 该组件支持自定义图标或子组件、颜色、工具提示和加载状态。
class GenericFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed; // 按钮按下时触发的回调。加载中或为空时按钮禁用。
  final IconData? icon; // 按钮上显示的图标数据。
  final Widget? child; // 按钮内部的子组件。如果提供，将覆盖图标。
  final String? tooltip; // 悬浮提示文本。
  final Object? heroTag; // Hero 动画标签。
  final Color? backgroundColor; // 按钮的背景颜色。空值时使用主题默认背景色。
  final Color? foregroundColor; // 图标和加载指示器的颜色。空值时使用主题计算的前景色。
  final Color? loadingIndicatorColor; // 加载指示器的颜色。空值时使用前景颜色或主题默认指示器颜色。
  final bool isLoading; // 按钮是否处于加载状态。为 true 时显示加载指示器且按钮不可点击。
  final bool mini; // 是否使用迷你尺寸的悬浮动作按钮。
  final ShapeBorder? shape; // 按钮形状。圆形为默认值。
  final double? iconSize; // 图标大小。
  final double loadingIndicatorSize; // 加载指示器的大小。
  final double loadingIndicatorStrokeWidth; // 加载指示器的线条宽度。

  /// 构造函数。
  ///
  /// [onPressed]：点击回调。
  /// [icon]：图标。
  /// [child]：子组件。
  /// [tooltip]：提示。
  /// [heroTag]：Hero 标签。
  /// [backgroundColor]：背景色。
  /// [foregroundColor]：前景色。
  /// [loadingIndicatorColor]：加载指示器颜色。
  /// [isLoading]：是否加载中。
  /// [mini]：是否迷你尺寸。
  /// [shape]：形状。
  /// [iconSize]：图标大小。
  /// [loadingIndicatorSize]：加载指示器大小。
  /// [loadingIndicatorStrokeWidth]：加载指示器线条宽度。
  const GenericFloatingActionButton({
    super.key,
    required this.onPressed,
    this.icon,
    this.child,
    this.tooltip,
    this.heroTag,
    this.backgroundColor = Colors.white,
    this.foregroundColor,
    this.loadingIndicatorColor,
    this.isLoading = false,
    this.mini = false,
    this.shape,
    this.iconSize,
    this.loadingIndicatorSize = 20.0,
    this.loadingIndicatorStrokeWidth = 2.5,
  }) : assert(icon != null || child != null, '必须提供一个图标或一个子组件。');

  /// 构建悬浮动作按钮。
  ///
  /// 该方法根据按钮状态和属性生成不同的按钮内容和样式。
  @override
  Widget build(BuildContext context) {
    final VoidCallback? effectiveOnPressed =
        isLoading ? null : onPressed; // 有效的点击回调
    final Color effectiveLoadingIndicatorColor = loadingIndicatorColor ??
        foregroundColor ??
        Theme.of(context).colorScheme.onSecondaryContainer; // 有效的加载指示器颜色

    final Widget buttonContent = isLoading
        ? SizedBox(
            width: loadingIndicatorSize,
            height: loadingIndicatorSize,
            child: CircularProgressIndicator(
              strokeWidth: loadingIndicatorStrokeWidth,
              color: effectiveLoadingIndicatorColor,
            ),
          )
        : child ??
            Icon(
              icon!,
              size: iconSize,
            );

    return FloatingActionButton(
      onPressed: effectiveOnPressed, // 按钮点击回调
      tooltip: tooltip, // 悬浮提示文本
      heroTag: heroTag, // Hero 标签
      backgroundColor: backgroundColor, // 背景色
      foregroundColor: foregroundColor, // 前景色
      mini: mini, // 迷你尺寸
      shape: shape, // 形状
      elevation: isLoading ? 0 : null, // 阴影高度
      child: Center(child: buttonContent), // 按钮内容居中
    );
  }
}
