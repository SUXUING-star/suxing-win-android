// lib/widgets/ui/animation/fade_in_item.dart
import 'dart:async';
import 'package:flutter/material.dart';

class FadeInItem extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const FadeInItem({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 350), // 可以比滑动稍快
    this.delay = Duration.zero,
  });

  @override
  _FadeInItemState createState() => _FadeInItemState();
}

class _FadeInItemState extends State<FadeInItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

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
        curve: Curves.easeIn, // 纯淡入用 easeIn 效果不错
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
      child: widget.child,
    );
  }
}

