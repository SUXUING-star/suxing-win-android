// --- 保持 GenericFloatingActionButton 不变 ---
// lib/widgets/ui/buttons/generic_fab.dart
import 'package:flutter/material.dart';

/// 一个通用的悬浮动作按钮 (FAB) 组件。
///
/// 支持自定义图标、颜色、工具提示，并包含加载状态处理。
class GenericFloatingActionButton extends StatelessWidget {
  /// 当按钮被按下时触发的回调。
  /// 如果为 null 或 [isLoading] 为 true，按钮将被禁用。
  final VoidCallback? onPressed;

  /// 按钮上显示的图标数据。 (如果提供了 child，则忽略此项)
  final IconData? icon;

  /// 按钮内部的子 Widget。如果提供，将覆盖 [icon]。
  final Widget? child;

  /// 悬浮提示文本。
  final String? tooltip;

  /// Hero 动画标签，避免在页面转换中与相同标签的其他 FAB 冲突。
  final Object? heroTag;

  /// 按钮的背景颜色。
  /// 如果为 null，将使用主题的默认 FAB 背景色。
  final Color? backgroundColor;

  /// 图标和加载指示器的颜色（前景）。
  /// 如果为 null，将使用主题计算出的合适前景色（通常基于背景色）。
  final Color? foregroundColor;

  /// 加载指示器的颜色。
  /// 如果为 null，将尝试使用 [foregroundColor]，如果 [foregroundColor] 也为 null，
  /// 则使用主题的默认指示器颜色。
  final Color? loadingIndicatorColor;

  /// 指示按钮当前是否处于加载状态。
  /// 如果为 true，将显示一个加载指示器代替图标，并且按钮不可点击。
  final bool isLoading;

  /// 是否使用迷你尺寸的 FAB。
  final bool mini;

  /// FAB 的形状。默认为圆形。
  final ShapeBorder? shape;

  /// 图标的大小。FAB 会尝试适应，但这可以提供指导。
  /// 注意：FAB 的整体尺寸由 [mini] 和主题决定。
  final double? iconSize; // FAB 图标大小通常由主题控制，但可以尝试影响

  /// 加载指示器的大小。
  final double loadingIndicatorSize;

  /// 加载指示器的线条宽度。
  final double loadingIndicatorStrokeWidth;

  const GenericFloatingActionButton({
    super.key,
    required this.onPressed,
    this.icon, // 改为可选，因为可能用 child
    this.child, // 添加 child 参数
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
  }) : assert(icon != null || child != null,
            'Must provide either an icon or a child'); // 断言确保 icon 或 child 至少有一个

  @override
  Widget build(BuildContext context) {
    final VoidCallback? effectiveOnPressed = isLoading ? null : onPressed;
    final Color effectiveLoadingIndicatorColor = loadingIndicatorColor ??
        foregroundColor ??
        Theme.of(context).colorScheme.onSecondaryContainer;

    // 优先使用 child，然后是 icon，最后是加载指示器
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
              // 如果 child 不为 null 则用 child，否则用 icon
              icon!, // 断言保证了此时 icon 不为 null
              size: iconSize,
            );

    return FloatingActionButton(
      onPressed: effectiveOnPressed,
      tooltip: tooltip,
      heroTag: heroTag,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      mini: mini,
      shape: shape,
      elevation: isLoading ? 0 : null,
      // 使用 Center 确保加载指示器或提供的 child 居中
      child: Center(child: buttonContent),
    );
  }
}
