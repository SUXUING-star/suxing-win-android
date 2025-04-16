// lib/widgets/ui/animation/scale_in_item.dart
import 'dart:async';
import 'package:flutter/material.dart';

class ScaleInItem extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double initialScale;

  const ScaleInItem({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 450), // 放大可以稍慢，更有弹性感
    this.delay = Duration.zero,
    this.initialScale = 0.7, // 从小一点开始
  }) : super(key: key);

  @override
  _ScaleInItemState createState() => _ScaleInItemState();
}

class _ScaleInItemState extends State<ScaleInItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // 同时淡入
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut), // 淡入在前段完成
      ),
    );

    // 放大效果
    _scaleAnimation = Tween<double>(begin: widget.initialScale, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut, // 弹性效果比较 Q 弹
        // curve: Curves.easeOutBack, // 这个回弹效果也不错
      ),
    );

    // Apply delay
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
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}