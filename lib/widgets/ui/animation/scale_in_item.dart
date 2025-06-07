// lib/widgets/ui/animation/scale_in_item.dart

/// 该文件定义了 ScaleInItem 组件，一个用于实现放大淡入效果的动画组件。
/// ScaleInItem 使其子组件在显示时从一个较小尺寸逐渐放大并淡入。
library;

import 'dart:async'; // 异步操作所需
import 'package:flutter/material.dart'; // Flutter UI 框架

/// `ScaleInItem` 类：放大淡入效果动画组件。
///
/// 该组件使其子组件在显示时从一个较小尺寸逐渐放大并淡入，支持自定义动画时长、延迟和初始缩放比例。
class ScaleInItem extends StatefulWidget {
  final Widget child; // 要应用放大淡入效果的子组件
  final Duration duration; // 动画持续时间
  final Duration delay; // 动画开始前的延迟
  final double initialScale; // 初始缩放比例

  /// 构造函数。
  ///
  /// [key]：可选的 Key。
  /// [child]：要应用放大淡入效果的子组件。
  /// [duration]：动画持续时间，默认为 450 毫秒。
  /// [delay]：动画开始前的延迟，默认为零。
  /// [initialScale]：初始缩放比例，默认为 0.7。
  const ScaleInItem({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 450),
    this.delay = Duration.zero,
    this.initialScale = 0.7,
  });

  /// 创建 `_ScaleInItemState` 状态。
  @override
  _ScaleInItemState createState() => _ScaleInItemState();
}

/// `_ScaleInItemState` 类：`ScaleInItem` 的状态。
///
/// 混入 `SingleTickerProviderStateMixin` 提供动画控制器。
class _ScaleInItemState extends State<ScaleInItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller; // 动画控制器
  late Animation<double> _fadeAnimation; // 淡入动画
  late Animation<double> _scaleAnimation; // 缩放动画

  /// 初始化状态。
  ///
  /// 创建并配置动画控制器、淡入动画和缩放动画。
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
        curve: Interval(0.0, 0.6, curve: Curves.easeOut), // 淡入在前段完成
      ),
    );

    _scaleAnimation =
        Tween<double>(begin: widget.initialScale, end: 1.0).animate(
      // 创建缩放动画
      CurvedAnimation(
        parent: _controller, // 动画父级
        curve: Curves.elasticOut, // 动画曲线
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

  /// 构建放大淡入动画 UI。
  ///
  /// [context]：Build 上下文。
  /// 返回一个 `FadeTransition` 组件，内部嵌套 `ScaleTransition`，应用淡入和缩放效果到子组件。
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      // 淡入过渡组件
      opacity: _fadeAnimation, // 淡入动画
      child: ScaleTransition(
        // 缩放过渡组件
        scale: _scaleAnimation, // 缩放动画
        child: widget.child, // 子组件
      ),
    );
  }
}
