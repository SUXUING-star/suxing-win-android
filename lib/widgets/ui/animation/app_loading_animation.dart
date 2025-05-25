// lib/widgets/ui/animation/app_loading_animation.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 一个轻量级、带呼吸感的旋转加载动画。
class AppLoadingAnimation extends StatefulWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const AppLoadingAnimation({
    super.key,
    this.size = 32.0,
    this.color,
    this.strokeWidth = 2.5,
  });

  @override
  _AppLoadingAnimationState createState() => _AppLoadingAnimationState();
}

class _AppLoadingAnimationState extends State<AppLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      // 周期可以短一点，响应更快
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = widget.color ?? Theme.of(context).primaryColor;

    // 尺寸校验 (保留基础的，防止极端情况)
    double validatedSize = widget.size;
    const double defaultInternalSize = 32.0;
    if (validatedSize.isInfinite || validatedSize.isNaN || validatedSize <= 0) {
      validatedSize = defaultInternalSize;
    }
    // 对于超快加载，太大的动画本身就没意义，可以再加个上限，但主要靠调用处控制
    // validatedSize = validatedSize.clamp(8.0, 64.0);

    return SizedBox(
      width: validatedSize,
      height: validatedSize,
      child: CustomPaint(
        painter: _AppLoadingPainter(
          animation: _controller,
          color: effectiveColor,
          strokeWidth: widget.strokeWidth,
        ),
      ),
    );
  }
}

class _AppLoadingPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final double strokeWidth;

  // 调整呼吸效果的参数，使其更平滑和快速
  static const double _minSweepAngle = 0.15 * math.pi; // 起始角度稍大，更快看到
  static const double _maxSweepAngle = 1.5 * math.pi; // 最大角度可以不用太大
  static const double _rotationCycles = 1.8; // 旋转圈数/周期
  static const double _sweepCycles = 0.7; // 呼吸频率/周期

  _AppLoadingPainter({
    required this.animation,
    required this.color,
    required this.strokeWidth,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round; // 圆角笔触

    // 旋转
    final double rotationAngle =
        animation.value * _rotationCycles * 2 * math.pi;

    // 呼吸 (扫描角度变化)
    // 使用 Curves.easeInOut 使变化更平滑
    final double sweepProgress = (animation.value * _sweepCycles * 2 * math.pi);
    // (sin(x)+1)/2 将 sin 的值域从 [-1, 1] 映射到 [0, 1]
    final double easedSweepProgress =
        Curves.easeInOut.transform((math.sin(sweepProgress) + 1.0) / 2.0);

    final double currentSweepAngle =
        _minSweepAngle + (_maxSweepAngle - _minSweepAngle) * easedSweepProgress;

    final double inset = strokeWidth / 2;
    final Rect arcRect = Rect.fromCircle(
        center: size.center(Offset.zero), radius: size.width / 2 - inset);

    canvas.drawArc(
      arcRect,
      rotationAngle,
      currentSweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _AppLoadingPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
