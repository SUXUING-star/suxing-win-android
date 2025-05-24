// lib/widgets/ui/buttons/floating_action_button_group.dart
import 'package:flutter/material.dart';
import 'dart:math' as math; // 用于旋转动画 (可选)
import 'generic_fab.dart'; // 确保引入了 GenericFloatingActionButton

/// 一个用于垂直排列多个悬浮按钮（或类似外观的 Widget）的组件。
///
/// 包含一个主切换按钮，用于展开或收起子按钮列表。
/// 通常放置在 Scaffold 的 floatingActionButton 属性中。
class FloatingActionButtonGroup extends StatefulWidget {
  /// 要在组中显示的子按钮列表（不包括主切换按钮）。
  /// 通常是 FloatingActionButton、GenericFloatingActionButton
  /// 或其他视觉上适配的小部件。
  final List<Widget> children;

  /// 按钮之间的垂直间距。
  final double spacing;

  /// 按钮在垂直方向上的对齐方式。
  /// 对于 FAB，通常使用 MainAxisAlignment.end。
  final MainAxisAlignment alignment;

  /// 控制 Column 如何占据主轴空间。
  /// 对于 FAB 组，应使用 MainAxisSize.min 以避免占据整个屏幕高度。
  final MainAxisSize mainAxisSize;

  /// 主切换按钮的展开状态图标。
  final IconData expandIcon;

  /// 主切换按钮的收起状态图标。
  final IconData collapseIcon;

  /// 主切换按钮的背景颜色。
  final Color? toggleButtonBackgroundColor;

  /// 主切换按钮的图标颜色。
  final Color? toggleButtonForegroundColor;

  /// 主切换按钮的 Hero 动画标签。
  final Object? toggleButtonHeroTag;

  /// 初始状态是否为展开。
  final bool initiallyExpanded;

  /// 切换展开/收起状态时的动画时长。
  final Duration animationDuration;

  const FloatingActionButtonGroup({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.alignment = MainAxisAlignment.end, // 默认底部对齐
    this.mainAxisSize = MainAxisSize.min,
    this.expandIcon = Icons.unfold_more, // 默认展开图标
    this.collapseIcon = Icons.unfold_less, // 默认收起图标
    this.toggleButtonBackgroundColor, // = Colors.white, // 可以从 Theme 获取或保持默认
    this.toggleButtonForegroundColor,
    this.toggleButtonHeroTag = const _DefaultHeroTag('toggle'), // 默认 Tag
    this.initiallyExpanded = false, // 默认收起
    this.animationDuration = const Duration(milliseconds: 250), // 默认动画时长
  });

  @override
  State<FloatingActionButtonGroup> createState() =>
      _FloatingActionButtonGroupState();
}

// 用于默认 HeroTag 的私有类，以避免与其他默认 Tag 冲突
class _DefaultHeroTag {
  final String description;
  const _DefaultHeroTag(this.description);
  @override
  String toString() => 'Default HeroTag: $description';
}

class _FloatingActionButtonGroupState extends State<FloatingActionButtonGroup>
    with SingleTickerProviderStateMixin {
  // 需要 TickerProvider 用于动画
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _rotateAnimation; // 用于图标旋转动画 (可选)
  late Animation<double> _opacityAnimation; // 用于子按钮淡入淡出

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    // 图标旋转动画 (0.0 -> 0.5 Pi, 即 90 度) - 可选，如果不需要可以移除
    _rotateAnimation =
        Tween<double>(begin: 0.0, end: 0.375) // 旋转 135 度 (Add -> Close 效果)
            .animate(CurvedAnimation(
                parent: _animationController, curve: Curves.easeInOut));

    // 子按钮透明度动画
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        // 在动画的后半段淡入，前半段淡出
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    if (_isExpanded) {
      _animationController.value = 1.0; // 如果初始展开，动画直接到结束状态
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward(); // 播放展开动画
      } else {
        _animationController.reverse(); // 播放收起动画
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 确定主切换按钮的颜色
    final bgColor = widget.toggleButtonBackgroundColor ??
        theme.colorScheme.secondary; // 优先使用传入颜色，否则用主题色
    final fgColor =
        widget.toggleButtonForegroundColor ?? theme.colorScheme.onSecondary;

    // 过滤掉 null 子项
    final validChildren = widget.children.toList();

    return Column(
      mainAxisAlignment: widget.alignment,
      mainAxisSize: widget.mainAxisSize,
      crossAxisAlignment: CrossAxisAlignment.end, // FAB 通常右对齐
      children: [
        // ----- 子按钮部分 (带动画) -----
        // 使用 AnimatedBuilder 来根据动画状态构建子按钮列表
        AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              // 只有在动画进行中或已完成展开时才渲染子按钮（避免收起时占用空间）
              if (_animationController.value == 0) {
                return const SizedBox.shrink(); // 完全收起时不渲染
              }
              return FadeTransition(
                  opacity: _opacityAnimation, // 应用淡入淡出效果
                  child: IgnorePointer(
                      // 收起过程中或完全收起时，子按钮不可交互
                      ignoring: !_isExpanded,
                      child: Padding(
                        // 在子按钮和主按钮之间添加一点间距
                        padding: EdgeInsets.only(bottom: widget.spacing),
                        child: Column(
                          mainAxisAlignment: widget.alignment,
                          mainAxisSize: widget.mainAxisSize,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: validChildren
                              .expand((subChild) => [
                                    subChild,
                                    // 在子按钮之间添加间距
                                    if (subChild != validChildren.last)
                                      SizedBox(height: widget.spacing),
                                  ])
                              .toList(),
                        ),
                      )));
            }),

        // ----- 主切换按钮 -----
        GenericFloatingActionButton(
          onPressed: _toggleExpand,
          // tooltip: _isExpanded ? '收起' : '展开', // Tooltip 可以动态改变
          tooltip: '', // 或者留空/移除，避免与旋转动画冲突观感
          heroTag: widget.toggleButtonHeroTag,
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          // 使用 AnimatedBuilder 来动态改变图标 (带旋转)
          child: AnimatedBuilder(
            animation: _rotateAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateAnimation.value * math.pi * 2, // 转换为弧度
                child:
                    Icon(_isExpanded ? widget.collapseIcon : widget.expandIcon),
              );
            },
          ),
          // 如果不想用旋转动画，可以直接用下面的代码：
          // icon: _isExpanded ? widget.collapseIcon : widget.expandIcon,
        ),
      ],
    );
  }
}
