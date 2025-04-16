// lib/widgets/ui/animation/fade_in_slide_up_item.dart
import 'dart:async';
import 'package:flutter/material.dart';

class FadeInSlideUpItem extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double slideOffset;

  const FadeInSlideUpItem({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 400), // 动画持续时间
    this.delay = Duration.zero,                      // 动画延迟开始时间
    this.slideOffset = 30.0,                         // 向上滑动的距离
  }) : super(key: key);

  @override
  _FadeInSlideUpItemState createState() => _FadeInSlideUpItemState();
}

class _FadeInSlideUpItemState extends State<FadeInSlideUpItem>
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
        curve: Curves.easeOut, // 淡出效果好一点
      ),
    );

    _slideAnimation = Tween<Offset>(
        begin: Offset(0, widget.slideOffset / 100), // 起始位置在下方一点
        end: Offset.zero) // 结束位置是原始位置
        .animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    // 应用延迟
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Timer(widget.delay, () {
        if (mounted) { // 增加 mounted 检查
          _controller.forward();
        }
      });
    }
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