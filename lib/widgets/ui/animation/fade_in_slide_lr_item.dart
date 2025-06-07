// lib/widgets/ui/animation/fade_in_slide_lr_item.dart

/// 该文件定义了 FadeInSlideLRItem 组件，一个用于实现从左右两侧淡入滑动的动画组件。
/// FadeInSlideLRItem 使其子组件在显示时逐渐淡入并从指定方向滑入。
library;

import 'dart:async'; // 异步操作所需
import 'package:flutter/material.dart'; // Flutter UI 框架

/// `SlideDirection` 枚举：定义滑动方向。
enum SlideDirection {
  left, // 从左侧滑入
  right, // 从右侧滑入
}

/// `FadeInSlideLRItem` 类：从左右两侧淡入滑动的动画组件。
///
/// 该组件使其子组件在显示时逐渐淡入并从指定方向滑入，支持自定义动画时长、延迟和滑动距离。
class FadeInSlideLRItem extends StatefulWidget {
  final Widget child; // 要应用淡入滑动效果的子组件
  final Duration duration; // 动画持续时间
  final Duration delay; // 动画开始前的延迟
  final double slideOffset; // 水平滑动距离
  final SlideDirection slideDirection; // 滑动方向

  /// 构造函数。
  ///
  /// [key]：可选的 Key。
  /// [child]：要应用淡入滑动效果的子组件。
  /// [duration]：动画持续时间，默认为 350 毫秒。
  /// [delay]：动画开始前的延迟，默认为零。
  /// [slideOffset]：水平滑动距离，默认为 50.0。
  /// [slideDirection]：滑动方向，必须指定。
  const FadeInSlideLRItem({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 350),
    this.delay = Duration.zero,
    this.slideOffset = 50.0,
    required this.slideDirection,
  });

  /// 创建 `_FadeInSlideLRItemState` 状态。
  @override
  _FadeInSlideLRItemState createState() => _FadeInSlideLRItemState();
}

/// `_FadeInSlideLRItemState` 类：`FadeInSlideLRItem` 的状态。
///
/// 混入 `SingleTickerProviderStateMixin` 提供动画控制器。
class _FadeInSlideLRItemState extends State<FadeInSlideLRItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller; // 动画控制器
  late Animation<double> _fadeAnimation; // 淡入动画
  late Animation<Offset> _slideAnimation; // 滑动动画

  /// 初始化状态。
  ///
  /// 创建并配置动画控制器、淡入动画和滑动动画。
  /// 根据滑动方向设置起始偏移量。
  /// 设置动画延迟后启动。
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      // 创建动画控制器
      vsync: this, // 垂直同步
      duration: widget.duration, // 动画持续时间
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      // 创建淡入动画
      CurvedAnimation(
        parent: _controller, // 动画父级
        curve: Curves.easeOut, // 动画曲线
      ),
    );

    final beginOffset =
        widget.slideDirection == SlideDirection.left // 根据滑动方向确定起始偏移量
            ? Offset(-widget.slideOffset / 100, 0) // 从左侧屏幕外开始
            : Offset(widget.slideOffset / 100, 0); // 从右侧屏幕外开始

    _slideAnimation =
        Tween<Offset>(begin: beginOffset, end: Offset.zero) // 结束位置是原始位置
            .animate(
      CurvedAnimation(
        parent: _controller, // 动画父级
        curve: Curves.easeOut, // 动画曲线
      ),
    );

    Timer(widget.delay, () {
      // 设置动画延迟
      if (mounted) {
        // 组件已挂载时
        _controller.forward(); // 启动动画
      }
    });
  }

  /// 销毁状态。
  ///
  /// 销毁动画控制器。
  @override
  void dispose() {
    _controller.dispose(); // 销毁动画控制器
    super.dispose();
  }

  /// 构建淡入滑动动画 UI。
  ///
  /// [context]：Build 上下文。
  /// 返回一个 `FadeTransition` 组件，内部嵌套 `SlideTransition`，应用淡入和滑动效果到子组件。
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      // 淡入过渡组件
      opacity: _fadeAnimation, // 淡入动画
      child: SlideTransition(
        // 滑动过渡组件
        position: _slideAnimation, // 滑动动画
        child: widget.child, // 子组件
      ),
    );
  }
}
