// lib/widgets/ui/animation/fade_in_slide_up_extension.dart
import 'package:flutter/material.dart';

class FadeInSlideUpItemCanPlay extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final bool play;

  const FadeInSlideUpItemCanPlay({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
    this.play = true,
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
  bool _hasStartedPlaying = false; // 标记动画是否已因 play=true 而启动过

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
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
      _startAnimation();
    }
  }

  void _startAnimation() {
    if (!mounted) return;
    if (!_hasStartedPlaying ||
        (_controller.status != AnimationStatus.forward &&
            _controller.status != AnimationStatus.completed)) {
      _hasStartedPlaying = true;
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant FadeInSlideUpItemCanPlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !oldWidget.play) {
      // 如果 play 从 false 变为 true，且动画未因 play=true 启动过或已结束，则重置并播放
      if (!_hasStartedPlaying ||
          (_controller.status != AnimationStatus.forward &&
              _controller.status != AnimationStatus.completed)) {
        _controller.reset();
        _startAnimation();
      }
    }
    // 当 play 从 true 变为 false 时，不再停止动画，让其自然完成
    // else if (!widget.play && oldWidget.play) {
    //   // _controller.stop(); // 已移除此行
    // }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 如果 play=false 且动画从未被 play=true 触发过，并且控制器处于初始状态，则初始不可见
    if (!widget.play &&
        !_hasStartedPlaying &&
        _controller.value == 0.0 &&
        !_controller.isAnimating) {
      return Opacity(opacity: 0, child: widget.child);
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
