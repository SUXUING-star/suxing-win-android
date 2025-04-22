// lib/widgets/ui/animation/fade_in_slide_lr_item.dart
import 'dart:async';
import 'package:flutter/material.dart';

// 定义滑动方向
enum SlideDirection { left, right }

class FadeInSlideLRItem extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double slideOffset;
  final SlideDirection slideDirection; // 新增：指定滑动方向

  const FadeInSlideLRItem({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 350), // 面板动画可以快一点
    this.delay = Duration.zero,
    this.slideOffset = 50.0, // 水平滑动距离
    required this.slideDirection, // 方向是必须的
  });

  @override
  _FadeInSlideLRItemState createState() => _FadeInSlideLRItemState();
}

class _FadeInSlideLRItemState extends State<FadeInSlideLRItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    // 根据方向确定起始 Offset
    final beginOffset = widget.slideDirection == SlideDirection.left
        ? Offset(-widget.slideOffset / 100, 0) // 从左侧屏幕外开始 (-x, 0)
        : Offset(widget.slideOffset / 100, 0);  // 从右侧屏幕外开始 (+x, 0)

    _slideAnimation = Tween<Offset>(
        begin: beginOffset,
        end: Offset.zero) // 结束位置是原始位置 (0, 0)
        .animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut, // 可以用 easeOutCubic 等其他曲线
      ),
    );

    // 应用延迟
    Timer(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}