import 'package:flutter/material.dart';

// 扩展 FadeInSlideUpItem 以接收 play 参数
class FadeInSlideUpItemCanPlay extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final bool play; // 新增参数

  const FadeInSlideUpItemCanPlay({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
    this.play = true, // 默认为 true，保持原有行为
  });

  @override
  _FadeInSlideUpItemCanPlayState createState() =>
      _FadeInSlideUpItemCanPlayState();
}

class _FadeInSlideUpItemCanPlayState extends State<FadeInSlideUpItemCanPlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3), // 从下方0.3处开始
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuad,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    if (widget.play) {
      // 根据 play 参数决定是否立即播放
      _startAnimation();
    }
  }

  void _startAnimation() {
    if (!mounted) return;
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void didUpdateWidget(covariant FadeInSlideUpItemCanPlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果 play 状态从 false 变为 true，则启动动画
    if (widget.play && !oldWidget.play) {
      // 可以选择重置动画并播放，或者如果动画已完成则不操作
      // 这里假设如果之前没播放，现在要播放了就从头开始
      _controller.reset();
      _startAnimation();
    }
    // 如果 play 状态从 true 变为 false，可以选择暂停或重置动画
    // else if (!widget.play && oldWidget.play) {
    //   _controller.stop(); // 或者 _controller.reset();
    // }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.play && !_controller.isAnimating && _controller.value == 0.0) {
      // 如果不播放，并且动画未开始或已重置，则直接显示子组件（无动画效果）
      // 或者根据需要返回一个透明/占位的 widget
      return Opacity(opacity: 0, child: widget.child); // 初始不可见
    }
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _offsetAnimation,
        child: widget.child,
      ),
    );
  }
}
