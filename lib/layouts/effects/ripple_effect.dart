// lib/layouts/effects/ripple_effect.dart
import 'package:flutter/material.dart';

class RipplePoint {
  final Offset position;
  double radius;
  double opacity;
  double strength;
  double thickness;
  final Color color;
  final List<Color> gradientColors;

  RipplePoint({
    required this.position,
    this.radius = 0,
    this.opacity = 1.0,
    this.strength = 1.0,
    this.thickness = 2.0,
    required this.color,
    required this.gradientColors,
  });
}

class RippleEffect extends StatefulWidget {
  final Widget child;
  final Function(Offset position, double strength) onRippleEffect;

  const RippleEffect({
    super.key,
    required this.child,
    required this.onRippleEffect,
  });

  @override
  State<RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<RippleEffect> with SingleTickerProviderStateMixin {
  final List<RipplePoint> _ripples = [];
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  void _setupAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateRipples);
    _controller.repeat();
  }

  void _updateRipples() {
    setState(() {
      for (int i = _ripples.length - 1; i >= 0; i--) {
        var ripple = _ripples[i];
        // 使用非线性函数使扩散更自然
        ripple.radius += (10 - ripple.radius * 0.02).clamp(1, 10);
        ripple.opacity -= 0.015;
        ripple.strength *= 0.97;
        ripple.thickness = (2.0 * ripple.opacity).clamp(0.5, 2.0);

        if (ripple.opacity <= 0) {
          _ripples.removeAt(i);
        } else {
          widget.onRippleEffect(ripple.position, ripple.strength);
        }
      }
    });
  }

  void _addRipple(Offset position) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;

    setState(() {
      _ripples.add(RipplePoint(
        position: position,
        opacity: 0.8,
        strength: 1.0,
        color: baseColor,
        gradientColors: [
          baseColor.withOpacity(0.6),
          baseColor.withOpacity(0.3),
          baseColor.withOpacity(0.1),
        ],
      ));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => _addRipple(details.localPosition),
      child: CustomPaint(
        foregroundPainter: RipplePainter(_ripples),
        child: widget.child,
      ),
    );
  }
}

class RipplePainter extends CustomPainter {
  final List<RipplePoint> ripples;

  RipplePainter(this.ripples);

  @override
  void paint(Canvas canvas, Size size) {
    for (var ripple in ripples) {
      // 创建渐变效果
      final gradient = RadialGradient(
        colors: ripple.gradientColors,
        stops: const [0.0, 0.5, 1.0],
      );

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ripple.thickness
        ..shader = gradient.createShader(
          Rect.fromCircle(
            center: ripple.position,
            radius: ripple.radius,
          ),
        );

      // 绘制主要涟漪圈
      canvas.drawCircle(
        ripple.position,
        ripple.radius,
        paint,
      );

      // 绘制额外的内圈效果
      final innerPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ripple.thickness * 0.5
        ..color = ripple.color.withOpacity(ripple.opacity * 0.3);

      canvas.drawCircle(
        ripple.position,
        ripple.radius * 0.8,
        innerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) => true;
}