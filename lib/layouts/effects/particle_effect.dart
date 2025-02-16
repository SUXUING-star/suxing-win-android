// lib/layouts/effects/particle_effect.dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class Particle {
  double x;
  double y;
  double speed;
  double size;
  double opacity;
  double velocityX;
  double velocityY;

  Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
    this.velocityX = 0,
    this.velocityY = 0,
  });
}

class ParticlesPainter extends CustomPainter {
  final List<Particle> particles;
  final Color color;

  ParticlesPainter(this.particles, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      paint.color = color.withOpacity(particle.opacity);
      canvas.drawCircle(
        Offset(
          particle.x * size.width / 400,
          particle.y * size.height / 800,
        ),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) => true;
}

// 添加一个全局key类型
class ParticleEffectKey extends GlobalKey<ParticleEffectState> {
  const ParticleEffectKey() : super.constructor();
}

class ParticleEffect extends StatefulWidget {
  const ParticleEffect({
    Key? key,
    this.particleCount = 50,
  }) : super(key: key);

  final int particleCount;

  @override
  ParticleEffectState createState() => ParticleEffectState();
}

class ParticleEffectState extends State<ParticleEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _initParticles();
    _setupAnimation();
  }

  // 将方法改为公开
  void applyRippleEffect(Offset position, double strength) {
    for (var particle in _particles) {
      final dx = (particle.x - position.dx);
      final dy = (particle.y - position.dy);
      final distance = math.sqrt(dx * dx + dy * dy);

      if (distance < 100) {
        final angle = math.atan2(dy, dx);
        final force = (1 - distance / 100) * strength * 5;

        particle.velocityX += math.cos(angle) * force;
        particle.velocityY += math.sin(angle) * force;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initParticles() {
    final random = math.Random();
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(
        Particle(
          x: random.nextDouble() * 400,
          y: random.nextDouble() * 800,
          speed: 0.5 + random.nextDouble() * 1.5,
          size: 1 + random.nextDouble() * 3,
          opacity: 0.1 + random.nextDouble() * 0.4,
        ),
      );
    }
  }

  void _setupAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(() {
      _updateParticles();
    });
    _controller.repeat();
  }

  void _updateParticles() {
    setState(() {
      for (var particle in _particles) {
        // Apply base upward movement
        particle.y -= particle.speed;

        // Apply velocity from ripple effects
        particle.x += particle.velocityX;
        particle.y += particle.velocityY;

        // Dampen velocities
        particle.velocityX *= 0.95;
        particle.velocityY *= 0.95;

        // Reset particles that go out of bounds
        if (particle.y < 0) {
          particle.y = 800;
          particle.x = math.Random().nextDouble() * 400;
          particle.velocityX = 0;
          particle.velocityY = 0;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color overlayColor = isDark ? Colors.white : Colors.black;

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: ParticlesPainter(
            _particles,
            overlayColor,
          ),
          size: Size(constraints.maxWidth, constraints.maxHeight),
        );
      },
    );
  }
}