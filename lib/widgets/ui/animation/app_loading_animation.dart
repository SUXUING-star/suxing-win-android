// lib/widgets/ui/animation/app_loading_animation.dart

/// 该文件定义了 AppLoadingAnimation 组件，一个轻量级、带呼吸感的旋转加载动画。
/// 该组件用于显示加载状态，提供自定义尺寸、颜色和线条粗细。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'dart:math' as math; // 导入数学函数

/// `AppLoadingAnimation` 类：一个轻量级、带呼吸感的旋转加载动画组件。
///
/// 该组件用于显示加载状态，支持自定义尺寸、颜色和线条粗细。
class AppLoadingAnimation extends StatefulWidget {
  final double size; // 动画尺寸
  final Color? color; // 动画颜色
  final double strokeWidth; // 动画线条粗细

  /// 构造函数。
  ///
  /// [size]：尺寸。
  /// [color]：颜色。
  /// [strokeWidth]：线条粗细。
  const AppLoadingAnimation({
    super.key,
    this.size = 32.0,
    this.color,
    this.strokeWidth = 2.5,
  });

  /// 创建状态。
  @override
  _AppLoadingAnimationState createState() => _AppLoadingAnimationState();
}

/// `_AppLoadingAnimationState` 类：`AppLoadingAnimation` 的状态管理。
///
/// 管理动画控制器和动画的生命周期。
class _AppLoadingAnimationState extends State<AppLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller; // 动画控制器

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200), // 动画持续时间
      vsync: this,
    )..repeat(); // 重复播放动画
  }

  @override
  void dispose() {
    _controller.dispose(); // 销毁动画控制器
    super.dispose();
  }

  /// 构建加载动画组件。
  @override
  Widget build(BuildContext context) {
    final Color effectiveColor =
        widget.color ?? Theme.of(context).primaryColor; // 有效的动画颜色

    double validatedSize = widget.size; // 验证后的尺寸
    const double defaultInternalSize = 32.0; // 默认内部尺寸
    if (validatedSize.isInfinite || validatedSize.isNaN || validatedSize <= 0) {
      validatedSize = defaultInternalSize; // 无效尺寸时使用默认内部尺寸
    }

    return SizedBox(
      width: validatedSize, // 宽度
      height: validatedSize, // 高度
      child: CustomPaint(
        painter: _AppLoadingPainter(
          // 自定义绘制器
          animation: _controller, // 动画控制器
          color: effectiveColor, // 动画颜色
          strokeWidth: widget.strokeWidth, // 线条粗细
        ),
      ),
    );
  }
}

/// `_AppLoadingPainter` 类：自定义加载动画的绘制器。
///
/// 该绘制器根据动画值绘制一个旋转且呼吸感变化的圆弧。
class _AppLoadingPainter extends CustomPainter {
  final Animation<double> animation; // 动画控制器
  final Color color; // 绘制颜色
  final double strokeWidth; // 线条粗细

  static const double _minSweepAngle = 0.15 * math.pi; // 最小扫描角度
  static const double _maxSweepAngle = 1.5 * math.pi; // 最大扫描角度
  static const double _rotationCycles = 1.8; // 旋转周期数
  static const double _sweepCycles = 0.7; // 呼吸频率周期数

  /// 构造函数。
  ///
  /// [animation]：动画。
  /// [color]：颜色。
  /// [strokeWidth]：线条粗细。
  _AppLoadingPainter({
    required this.animation,
    required this.color,
    required this.strokeWidth,
  }) : super(repaint: animation); // 重绘时监听动画

  /// 绘制动画。
  ///
  /// [canvas]：画布。
  /// [size]：绘制区域尺寸。
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color // 颜色
      ..strokeWidth = strokeWidth // 线条粗细
      ..style = PaintingStyle.stroke // 样式为描边
      ..strokeCap = StrokeCap.round; // 笔触为圆角

    final double rotationAngle =
        animation.value * _rotationCycles * 2 * math.pi; // 旋转角度

    final double sweepProgress =
        (animation.value * _sweepCycles * 2 * math.pi); // 扫描进度
    final double easedSweepProgress = Curves.easeInOut
        .transform((math.sin(sweepProgress) + 1.0) / 2.0); // 缓动后的扫描进度

    final double currentSweepAngle = _minSweepAngle +
        (_maxSweepAngle - _minSweepAngle) * easedSweepProgress; // 当前扫描角度

    final double inset = strokeWidth / 2; // 边距
    final Rect arcRect = Rect.fromCircle(
        center: size.center(Offset.zero),
        radius: size.width / 2 - inset); // 圆弧矩形

    canvas.drawArc(
      arcRect, // 圆弧矩形
      rotationAngle, // 起始角度
      currentSweepAngle, // 扫描角度
      false, // 不使用中心
      paint, // 画笔
    );
  }

  /// 判断是否需要重绘。
  ///
  /// [oldDelegate]：旧的绘制器代理。
  @override
  bool shouldRepaint(covariant _AppLoadingPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth; // 动画、颜色或线条粗细变化时重绘
  }
}
