// lib/widgets/components/screen/effects/checkin_particle_effect.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class CheckInParticleEffect extends StatefulWidget {
  final AnimationController controller;
  final Color? color;
  final int particleCount;

  const CheckInParticleEffect({
    super.key,
    required this.controller,
    this.color,
    this.particleCount = 30,
  });

  @override
  _CheckInParticleEffectState createState() => _CheckInParticleEffectState();
}

class _CheckInParticleEffectState extends State<CheckInParticleEffect> {
  List<Particle> particles = [];
  final Random random = Random();
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    initParticles();
    widget.controller.addListener(_updateParticles);
  }

  void _updateParticles() {
    if (widget.controller.isAnimating && mounted && !_isDisposed) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    widget.controller.removeListener(_updateParticles);
    super.dispose();
  }

  void initParticles() {
    particles.clear();
    for (int i = 0; i < widget.particleCount; i++) {
      particles.add(Particle(
        position: Offset.zero,
        velocity: Offset(
          (random.nextDouble() * 2 - 1) * 5,
          (random.nextDouble() * 2 - 1) * 5,
        ),
        color: widget.color ?? Colors.blue,
        size: random.nextDouble() * 8 + 2,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ParticlePainter(
        particles: particles,
        progress: widget.controller.value,
        color: widget.color ?? Theme.of(context).primaryColor,
      ),
      child: Container(),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final Color color;

  ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);

    for (var particle in particles) {
      final position = center + (particle.velocity * progress * 100);
      final opacity = (1.0 - progress) * 0.8;

      if (opacity <= 0) continue;

      final paint = Paint()
        ..color = particle.color.withSafeOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(position, particle.size * (1 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class Particle {
  Offset position;
  Offset velocity;
  Color color;
  double size;

  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
  });
}
