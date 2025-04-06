// lib/widgets/ui/animation/modern_loading_animation.dart
import 'package:flutter/material.dart';
import 'dart:math' as math; // 需要导入 math 库

/// 一个现代风格的、会呼吸旋转的加载动画指示器 Widget。
class ModernLoadingAnimation extends StatefulWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const ModernLoadingAnimation({
    Key? key,
    this.size = 32.0, // 默认大小
    this.color,      // 颜色可选，不提供则使用主题色
    this.strokeWidth = 2.5, // 默认线宽
  }) : super(key: key);

  @override
  _ModernLoadingAnimationState createState() => _ModernLoadingAnimationState();
}

class _ModernLoadingAnimationState extends State<ModernLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500), // 动画周期
      vsync: this,
    )..repeat(); // 创建并重复播放动画
  }

  @override
  void dispose() {
    _controller.dispose(); // 销毁控制器
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 如果未指定颜色，则使用主题的 primaryColor
    final Color effectiveColor = widget.color ?? Theme.of(context).primaryColor;

    // 使用 SizedBox 约束大小，并应用 CustomPaint
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _ModernLoadingPainter(
          animation: _controller,
          color: effectiveColor,
          strokeWidth: widget.strokeWidth,
        ),
      ),
    );
  }
}

// --- 内部使用的 Painter (和之前改进版的基本一样) ---
class _ModernLoadingPainter extends CustomPainter {
  final Animation<double> animation; // 0.0 to 1.0 repeating
  final Color color;
  final double strokeWidth;

  static const double _minSweepAngle = 0.1 * math.pi;
  static const double _maxSweepAngle = 1.6 * math.pi;
  static const double _rotationCycles = 2.0;
  static const double _sweepCycles = 0.8;

  _ModernLoadingPainter({
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
      ..strokeCap = StrokeCap.round;

    final double rotationAngle = animation.value * _rotationCycles * 2 * math.pi;

    // 使用 Curves.easeInOut 来使 sweep 变化更平滑
    final double sweepProgress = (animation.value * _sweepCycles * 2 * math.pi);
    final double easedSweepProgress = Curves.easeInOut.transform((math.sin(sweepProgress) + 1.0) / 2.0);

    final double currentSweepAngle = _minSweepAngle + (_maxSweepAngle - _minSweepAngle) * easedSweepProgress;

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
  bool shouldRepaint(covariant _ModernLoadingPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}