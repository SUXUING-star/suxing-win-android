import 'dart:math' as math;
import 'package:flutter/material.dart';

class Particle {
  double x;
  double y;
  double speed;
  double size;
  double opacity;
  double velocityX;
  double velocityY;
  double angle;  // 用于旋转效果
  ParticleShape shape;  // 粒子形状
  Color color;  // 粒子颜色

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

// 定义粒子形状
enum ParticleShape {
  circle,
  heart,
  star,
  bubble
}

class ParticlesPainter extends CustomPainter {
  final List<Particle> particles;

  ParticlesPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      paint.color = particle.color.withOpacity(particle.opacity);

      final position = Offset(
        particle.x * size.width / 400,
        particle.y * size.height / 800,
      );

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
    // 绘制泡泡效果
    canvas.drawCircle(position, size, paint);

    // 添加高光效果
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(position.dx - size * 0.3, position.dy - size * 0.3),
      size * 0.2,
      highlightPaint,
    );
  }

  void _drawHeart(Canvas canvas, Offset position, double size, Paint paint, double angle) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(angle);

    final path = Path();
    path.moveTo(0, size * 0.2);
    path.cubicTo(
      size * 0.5, -size * 0.3,
      size, size * 0.2,
      0, size,
    );
    path.cubicTo(
      -size, size * 0.2,
      -size * 0.5, -size * 0.3,
      0, size * 0.2,
    );

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawStar(Canvas canvas, Offset position, double size, Paint paint, double angle) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(angle);

    final path = Path();
    final points = 5;
    final innerRadius = size * 0.4;
    final outerRadius = size;

    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final anglePoint = i * math.pi / points;
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

class ParticleEffectKey extends GlobalKey<ParticleEffectState> {
  const ParticleEffectKey() : super.constructor();
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

class ParticleEffectState extends State<ParticleEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final List<Color> _pastelColors = [
    Color(0xFFFFB3BA), // 粉红
    Color(0xFFBAE1FF), // 天蓝
    Color(0xFFBAFFBF), // 薄荷绿
    Color(0xFFFFDFBA), // 桃色
    Color(0xFFE3BAFF), // 淡紫
  ];

  @override
  void initState() {
    super.initState();
    _initParticles();
    _setupAnimation();
  }

  void applyRippleEffect(Offset position, double strength) {
    for (var particle in _particles) {
      final dx = (particle.x - position.dx);
      final dy = (particle.y - position.dy);
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initParticles() {
    final random = math.Random();
    for (int i = 0; i < widget.particleCount; i++) {
      final shape = ParticleShape.values[random.nextInt(ParticleShape.values.length)];
      final color = _pastelColors[random.nextInt(_pastelColors.length)];

      _particles.add(
        Particle(
          x: random.nextDouble() * 400,
          y: random.nextDouble() * 800,
          speed: 0.3 + random.nextDouble() * 0.8, // 降低基础速度
          size: 2 + random.nextDouble() * 4,  // 略微增大粒子
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
      _updateParticles();
    });
    _controller.repeat();
  }

  void _updateParticles() {
    final random = math.Random();

    setState(() {
      for (var particle in _particles) {
        // 添加随机摆动
        particle.velocityX += (random.nextDouble() - 0.5) * 0.1;

        // 基础向上运动
        particle.y -= particle.speed;

        // 应用速度
        particle.x += particle.velocityX;
        particle.y += particle.velocityY;

        // 旋转角度
        particle.angle += 0.02;

        // 速度衰减
        particle.velocityX *= 0.98;
        particle.velocityY *= 0.98;

        // 边界检查
        if (particle.y < 0) {
          // 重置粒子
          particle.y = 800;
          particle.x = random.nextDouble() * 400;
          particle.velocityX = 0;
          particle.velocityY = 0;
          // 随机新的形状和颜色
          particle.shape = ParticleShape.values[random.nextInt(ParticleShape.values.length)];
          particle.color = _pastelColors[random.nextInt(_pastelColors.length)];
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: ParticlesPainter(_particles),
          size: Size(constraints.maxWidth, constraints.maxHeight),
        );
      },
    );
  }
}