// lib/widgets/ui/buttons/generic_fab.dart
import 'package:flutter/material.dart';

/// 一个通用的悬浮动作按钮 (FAB) 组件。
///
/// 支持自定义图标、颜色、工具提示，并包含加载状态处理。
class GenericFloatingActionButton extends StatelessWidget {
  /// 当按钮被按下时触发的回调。
  /// 如果为 null 或 [isLoading] 为 true，按钮将被禁用。
  final VoidCallback? onPressed;

  /// 按钮上显示的图标数据。
  final IconData icon;

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
    required this.icon,
    this.tooltip,
    this.heroTag,
    this.backgroundColor = Colors.white,
    this.foregroundColor,
    this.loadingIndicatorColor,
    this.isLoading = false,
    this.mini = false,
    this.shape,
    this.iconSize, // 通常 FAB 会自动处理图标大小
    this.loadingIndicatorSize = 20.0, // 加载圈的大小
    this.loadingIndicatorStrokeWidth = 2.5, // 加载圈的粗细
  });

  @override
  Widget build(BuildContext context) {
    // 确定实际的 onPressed 回调 (加载中或传入 null 时禁用)
    final VoidCallback? effectiveOnPressed = isLoading ? null : onPressed;

    // 确定加载指示器的颜色
    final Color effectiveLoadingIndicatorColor = loadingIndicatorColor ??
        foregroundColor ?? // 优先用指定的加载颜色，其次用前景色
        Theme.of(context).colorScheme.onSecondaryContainer; // 最后用主题色（根据FAB背景推断）

    // 确定按钮子组件 (图标或加载指示器)
    final Widget child = isLoading
        ? SizedBox(
      width: loadingIndicatorSize,
      height: loadingIndicatorSize,
      child: CircularProgressIndicator(
        strokeWidth: loadingIndicatorStrokeWidth,
        color: effectiveLoadingIndicatorColor, // 使用计算出的颜色
      ),
    )
        : Icon(
      icon,
      size: iconSize, // 应用图标大小 (如果指定)
      // color: foregroundColor, // FAB 会自动处理前景色，除非你想强制覆盖
    );

    // 构建 FAB
    return FloatingActionButton(
      onPressed: effectiveOnPressed,
      tooltip: tooltip,
      heroTag: heroTag,
      backgroundColor: backgroundColor, // 应用背景色
      foregroundColor: foregroundColor, // 应用前景色 (图标颜色)
      mini: mini,                     // 应用迷你模式
      shape: shape,                   // 应用形状
      elevation: isLoading ? 0 : null, // 加载时可以移除阴影，看起来更像禁用
      child: Center(child: child), // 使用 Center 确保加载指示器居中
    );
  }
}