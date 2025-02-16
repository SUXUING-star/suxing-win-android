// lib/widgets/effects/mouse_trail_effect.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

class MouseTrailParticle {
  Offset position;
  double opacity;
  double size;
  double angle;
  double speed;

  MouseTrailParticle({
    required this.position,
    this.opacity = 1.0,
    this.size = 3.0,
    this.angle = 0.0,
    this.speed = 1.5,
  });

  void update() {
    position = Offset(
        position.dx + math.cos(angle) * speed,
        position.dy + math.sin(angle) * speed
    );
    opacity *= 0.94;
    size *= 0.97;
  }
}

class MouseTrailEffect extends StatefulWidget {
  final Widget child;
  final Color particleColor;
  final int maxParticles;
  final Duration particleLifespan;

  const MouseTrailEffect({
    Key? key,
    required this.child,
    this.particleColor = Colors.blue,
    this.maxParticles = 15,
    this.particleLifespan = const Duration(milliseconds: 600),
  }) : super(key: key);

  @override
  State<MouseTrailEffect> createState() => _MouseTrailEffectState();
}

class _MouseTrailEffectState extends State<MouseTrailEffect>
    with SingleTickerProviderStateMixin {
  final List<MouseTrailParticle> _particles = [];
  Offset? _lastPosition;
  Timer? _cleanupTimer;
  late AnimationController _animationController;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateParticles);

    _cleanupTimer = Timer.periodic(
      const Duration(milliseconds: 50),
          (_) => _cleanupParticles(),
    );
  }

  void _updateParticles() {
    for (var particle in _particles) {
      particle.update();
    }
    if (mounted) setState(() {});
  }

  void _cleanupParticles() {
    _particles.removeWhere((particle) => particle.opacity < 0.01);
    if (_particles.isEmpty && _animationController.isAnimating) {
      _animationController.stop();
    }
    if (mounted) setState(() {});
  }

  void _addParticle(Offset position) {
    if (_particles.length >= widget.maxParticles) {
      _particles.removeAt(0);
    }

    for (int i = 0; i < 2; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 0.8 + _random.nextDouble() * 1.2;

      _particles.add(MouseTrailParticle(
        position: position,
        size: 2.0 + _random.nextDouble() * 1.5,
        angle: angle,
        speed: speed,
        opacity: 0.4 + _random.nextDouble() * 0.3,
      ));
    }

    if (!_animationController.isAnimating) {
      _animationController.repeat();
    }
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 主内容始终在底层
        widget.child,

        // 粒子效果层
        Positioned.fill(
          child: MouseRegion(
            opaque: false,
            onHover: (event) {
              final currentPosition = event.localPosition;
              if (_lastPosition != null) {
                final distance = (_lastPosition! - currentPosition).distance;
                final numberOfPoints = (distance / 10).round();

                if (numberOfPoints > 0) {
                  for (var i = 0; i < numberOfPoints; i++) {
                    final t = i / numberOfPoints;
                    final interpolatedPosition = Offset.lerp(
                      _lastPosition!,
                      currentPosition,
                      t,
                    )!;
                    _addParticle(interpolatedPosition);
                  }
                }
              }
              _lastPosition = currentPosition;
            },
            child: IgnorePointer(
              child: CustomPaint(
                size: Size.infinite,
                painter: _MouseTrailPainter(
                  particles: _particles,
                  color: widget.particleColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MouseTrailPainter extends CustomPainter {
  final List<MouseTrailParticle> particles;
  final Color color;

  _MouseTrailPainter({
    required this.particles,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

      canvas.drawCircle(
        particle.position,
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MouseTrailPainter oldDelegate) => true;
}