// lib/widgets/ui/animation/fade_in_slide_up_item.dart

/// 该文件定义了 FadeInSlideUpItem 组件，一个用于实现淡入上滑效果的动画组件。
/// FadeInSlideUpItem 使其子组件在显示时从下方逐渐淡入并上滑。
library;

import 'dart:async'; // 异步操作所需
import 'package:flutter/material.dart'; // Flutter UI 框架

/// `FadeInSlideUpItem` 类：淡入上滑效果动画组件。
///
/// 该组件使其子组件在显示时从下方逐渐淡入并上滑，支持自定义动画时长、延迟和滑动距离。
class FadeInSlideUpItem extends StatefulWidget {
  final Widget child; // 要应用淡入上滑效果的子组件
  final Duration duration; // 动画持续时间
  final Duration delay; // 动画延迟开始时间
  final double slideOffset; // 向上滑动的距离

  /// 构造函数。
  ///
  /// [key]：可选的 Key。
  /// [child]：要应用淡入上滑效果的子组件。
  /// [duration]：动画持续时间，默认为 400 毫秒。
  /// [delay]：动画延迟开始时间，默认为零。
  /// [slideOffset]：向上滑动的距离，默认为 30.0。
  const FadeInSlideUpItem({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.slideOffset = 30.0,
  });

  /// 创建 `_FadeInSlideUpItemState` 状态。
  @override
  _FadeInSlideUpItemState createState() => _FadeInSlideUpItemState();
}

/// `_FadeInSlideUpItemState` 类：`FadeInSlideUpItem` 的状态。
///
/// 混入 `SingleTickerProviderStateMixin` 提供动画控制器。
class _FadeInSlideUpItemState extends State<FadeInSlideUpItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller; // 动画控制器
  late Animation<double> _fadeAnimation; // 淡入动画
  late Animation<Offset> _slideAnimation; // 滑动动画

  /// 初始化状态。
  ///
  /// 创建并配置动画控制器、淡入动画和滑动动画。
  /// 根据延迟时间启动动画。
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

    _slideAnimation = Tween<Offset>(
            // 创建滑动动画
            begin: Offset(0, widget.slideOffset / 100), // 起始位置在下方
            end: Offset.zero) // 结束位置是原始位置
        .animate(
      CurvedAnimation(
        parent: _controller, // 动画父级
        curve: Curves.easeOut, // 动画曲线
      ),
    );

    if (widget.delay == Duration.zero) {
      // 无延迟时直接启动动画
      _controller.forward();
    } else {
      // 有延迟时设置定时器启动动画
      Timer(widget.delay, () {
        if (mounted) {
          // 组件已挂载时
          _controller.forward(); // 启动动画
        }
      });
    }
  }

  /// 销毁状态。
  ///
  /// 销毁动画控制器。
  @override
  void dispose() {
    _controller.dispose(); // 销毁动画控制器
    super.dispose();
  }

  /// 构建淡入上滑动画 UI。
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
