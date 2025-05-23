import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class Particle {
  double x;
  double y;
  double speed;
  double size;
  double opacity;
  double velocityX;
  double velocityY;
  double angle;
  ParticleShape shape;
  Color color;

  Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
    this.velocityX = 0,
    this.velocityY = 0,
    this.angle = 0,
    this.shape = ParticleShape.circle,
    required this.color,
  });
}

enum ParticleShape { circle, heart, star, bubble }

class ParticlesPainter extends CustomPainter {
  final List<Particle> particles;

  ParticlesPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      paint.color = particle.color.withSafeOpacity(particle.opacity);
      final position = Offset(particle.x, particle.y);

      switch (particle.shape) {
        case ParticleShape.circle:
          _drawBubble(canvas, position, particle.size, paint);
          break;
        case ParticleShape.heart:
          _drawHeart(canvas, position, particle.size, paint, particle.angle);
          break;
        case ParticleShape.star:
          _drawStar(canvas, position, particle.size, paint, particle.angle);
          break;
        case ParticleShape.bubble:
          _drawBubble(canvas, position, particle.size, paint);
          break;
      }
    }
  }

  void _drawBubble(Canvas canvas, Offset position, double size, Paint paint) {
    canvas.drawCircle(position, size, paint);
    final highlightPaint = Paint()
      ..color = Colors.white.withSafeOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(position.dx - size * 0.3, position.dy - size * 0.3),
      size * 0.2,
      highlightPaint,
    );
  }

  void _drawHeart(
      Canvas canvas, Offset position, double size, Paint paint, double angle) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(angle);
    final path = Path();
    path.moveTo(0, size * 0.2);
    path.cubicTo(
      size * 0.5,
      -size * 0.3,
      size,
      size * 0.2,
      0,
      size,
    );
    path.cubicTo(
      -size,
      size * 0.2,
      -size * 0.5,
      -size * 0.3,
      0,
      size * 0.2,
    );
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawStar(
      Canvas canvas, Offset position, double size, Paint paint, double angle) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(angle);
    final path = Path();
    const points = 5;
    final innerRadius = size * 0.4;
    final outerRadius = size;
    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final anglePoint = (i * math.pi / points) - (math.pi / 2);
      final x = math.cos(anglePoint) * radius;
      final y = math.sin(anglePoint) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) => true;
}

class ParticleEffect extends StatefulWidget {
  const ParticleEffect({
    super.key,
    this.particleCount = 50,
  });

  final int particleCount;

  @override
  ParticleEffectState createState() => ParticleEffectState();
}

class ParticleEffectState extends State<ParticleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final List<Color> _pastelColors = [
    const Color(0xFFFFB3BA),
    const Color(0xFFBAE1FF),
    const Color(0xFFBAFFBF),
    const Color(0xFFFFDFBA),
    const Color(0xFFE3BAFF),
  ];
  Size _currentSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initParticlesIfNeeded(Size size) {
    if (_particles.isNotEmpty &&
        (_currentSize.width - size.width).abs() < 1 &&
        (_currentSize.height - size.height).abs() < 1) {
      return;
    }
    _currentSize = size;
    _particles.clear();
    final random = math.Random();
    for (int i = 0; i < widget.particleCount; i++) {
      final shape =
          ParticleShape.values[random.nextInt(ParticleShape.values.length)];
      final color = _pastelColors[random.nextInt(_pastelColors.length)];
      _particles.add(
        Particle(
          x: random.nextDouble() * _currentSize.width,
          y: random.nextDouble() * _currentSize.height,
          speed: 0.3 + random.nextDouble() * 0.8,
          size: 2 + random.nextDouble() * 4,
          opacity: 0.3 + random.nextDouble() * 0.4,
          angle: random.nextDouble() * math.pi * 2,
          shape: shape,
          color: color,
        ),
      );
    }
  }

  void _setupAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(() {
        if (_controller.isAnimating && mounted) {
          _updateParticles();
        }
      });
  }

  void _startAnimationIfNeeded() {
    if (mounted && !_controller.isAnimating && _particles.isNotEmpty) {
      _controller.repeat();
    }
  }

  void _updateParticles() {
    if (!mounted || _currentSize == Size.zero) return;
    final random = math.Random();
    setState(() {
      for (var particle in _particles) {
        particle.velocityX += (random.nextDouble() - 0.5) * 0.1;
        particle.y -= particle.speed;
        particle.x += particle.velocityX;
        particle.y += particle.velocityY;
        particle.angle += 0.02;
        particle.velocityX *= 0.98;
        particle.velocityY *= 0.98;

        if (particle.y < -particle.size) {
          particle.y = _currentSize.height + particle.size;
          particle.x = random.nextDouble() * _currentSize.width;
          particle.velocityX = 0;
          particle.velocityY = 0;
          particle.opacity = 0.3 + random.nextDouble() * 0.4;
          particle.shape =
              ParticleShape.values[random.nextInt(ParticleShape.values.length)];
          particle.color = _pastelColors[random.nextInt(_pastelColors.length)];
        }
        if (particle.x < -particle.size) {
          particle.x = _currentSize.width + particle.size;
        } else if (particle.x > _currentSize.width + particle.size) {
          particle.x = -particle.size;
        }
      }
    });
  }

  void applyRippleEffect(Offset position, double strength) {
    if (!mounted || _currentSize == Size.zero) return;
    // final localPosition = position; // 确保 position 是正确的局部坐标

    for (var particle in _particles) {
      final dx = (particle.x - position.dx); // 使用传入的 position
      final dy = (particle.y - position.dy); // 使用传入的 position
      final distance = math.sqrt(dx * dx + dy * dy);

      if (distance < 100) {
        final angle = math.atan2(dy, dx);
        final force = (1 - distance / 100) * strength * 3;
        particle.velocityX += math.cos(angle) * force;
        particle.velocityY += math.sin(angle) * force;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final newSize = constraints.biggest;
        if (_currentSize != newSize || _particles.isEmpty) {
          _initParticlesIfNeeded(newSize);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startAnimationIfNeeded();
          });
        }
        if (_particles.isEmpty) {
          return const SizedBox.shrink();
        }
        return CustomPaint(
          painter: ParticlesPainter(_particles),
          size: Size.infinite,
        );
      },
    );
  }
}
