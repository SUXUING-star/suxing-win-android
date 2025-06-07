// lib/widgets/ui/animation/fade_in_slide_up_can_play.dart

/// 该文件定义了 FadeInSlideUpItemCanPlay 组件，一个可控制播放的淡入上滑动画组件。
/// FadeInSlideUpItemCanPlay 使其子组件在 `play` 为 true 时从下方淡入上滑。
library;

import 'package:flutter/material.dart'; // Flutter UI 框架

/// `FadeInSlideUpItemCanPlay` 类：可控制播放的淡入上滑动画组件。
///
/// 该组件使其子组件在 `play` 为 true 时从下方淡入上滑，支持自定义动画时长和延迟。
class FadeInSlideUpItemCanPlay extends StatefulWidget {
  final Widget child; // 要应用淡入上滑效果的子组件
  final Duration delay; // 动画开始前的延迟
  final Duration duration; // 动画持续时间
  final bool play; // 控制动画是否播放的标记

  /// 构造函数。
  ///
  /// [key]：可选的 Key。
  /// [child]：要应用淡入上滑效果的子组件。
  /// [delay]：动画开始前的延迟，默认为零。
  /// [duration]：动画持续时间，默认为 400 毫秒。
  /// [play]：控制动画是否播放的标记，默认为 true。
  const FadeInSlideUpItemCanPlay({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
    this.play = true,
  });

  /// 创建 `_FadeInSlideUpItemCanPlayState` 状态。
  @override
  _FadeInSlideUpItemCanPlayState createState() =>
      _FadeInSlideUpItemCanPlayState();
}

/// `_FadeInSlideUpItemCanPlayState` 类：`FadeInSlideUpItemCanPlay` 的状态。
///
/// 混入 `SingleTickerProviderStateMixin` 提供动画控制器。
class _FadeInSlideUpItemCanPlayState extends State<FadeInSlideUpItemCanPlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller; // 动画控制器
  late Animation<Offset> _offsetAnimation; // 偏移动画
  late Animation<double> _fadeAnimation; // 淡入动画
  bool _hasStartedPlaying = false; // 标记动画是否已因 play=true 而启动过

  /// 初始化状态。
  ///
  /// 创建并配置动画控制器、偏移动画和淡入动画。
  /// 如果 `widget.play` 为 true，则启动动画。
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      // 创建动画控制器
      duration: widget.duration, // 动画持续时间
      vsync: this, // 垂直同步
    );

    _offsetAnimation = Tween<Offset>(
      // 创建偏移动画
      begin: const Offset(0.0, 0.3), // 起始偏移量
      end: Offset.zero, // 结束偏移量
    ).animate(CurvedAnimation(
      parent: _controller, // 动画父级
      curve: Curves.easeOutQuad, // 动画曲线
    ));

    _fadeAnimation = Tween<double>(
      // 创建淡入动画
      begin: 0.0, // 起始不透明度
      end: 1.0, // 结束不透明度
    ).animate(CurvedAnimation(
      parent: _controller, // 动画父级
      curve: Curves.easeIn, // 动画曲线
    ));

    if (widget.play) {
      // 如果播放标记为 true
      _startAnimation(); // 启动动画
    }
  }

  /// 启动动画。
  ///
  /// 如果组件已挂载且动画未启动或已完成，则设置延迟后启动动画。
  void _startAnimation() {
    if (!mounted) return; // 组件未挂载时返回
    if (!_hasStartedPlaying ||
        (_controller.status != AnimationStatus.forward &&
            _controller.status != AnimationStatus.completed)) {
      // 动画未启动或已完成
      _hasStartedPlaying = true; // 标记动画已启动
      Future.delayed(widget.delay, () {
        // 设置延迟
        if (mounted) {
          // 组件已挂载时
          _controller.forward(); // 启动动画
        }
      });
    }
  }

  /// 组件更新时调用。
  ///
  /// 当 `play` 从 false 变为 true 且动画未启动或已完成时，重置并启动动画。
  @override
  void didUpdateWidget(covariant FadeInSlideUpItemCanPlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !oldWidget.play) {
      // `play` 从 false 变为 true
      if (!_hasStartedPlaying ||
          (_controller.status != AnimationStatus.forward &&
              _controller.status != AnimationStatus.completed)) {
        // 动画未启动或已完成
        _controller.reset(); // 重置动画控制器
        _startAnimation(); // 启动动画
      }
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
    if (!widget.play && // 如果 `play` 为 false
        !_hasStartedPlaying && // 动画未被触发
        _controller.value == 0.0 && // 控制器值为 0.0
        !_controller.isAnimating) {
      // 动画未在进行
      return Opacity(opacity: 0, child: widget.child); // 返回透明的子组件
    }

    return FadeTransition(
      // 淡入过渡组件
      opacity: _fadeAnimation, // 淡入动画
      child: SlideTransition(
        // 滑动过渡组件
        position: _offsetAnimation, // 偏移动画
        child: widget.child, // 子组件
      ),
    );
  }
}
