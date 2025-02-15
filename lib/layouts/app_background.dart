import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:async';

class Particle {
  double x;
  double y;
  double speed;
  double size;
  double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
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

class AppBackground extends StatefulWidget {
  final Widget child;

  const AppBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground> with SingleTickerProviderStateMixin {
  late Timer _imageTimer;
  int _currentImageIndex = 0;
  final List<String> _backgroundImages = ['assets/images/bg-1.jpg', 'assets/images/bg-2.jpg'];
  final List<Particle> _particles = [];
  final int _particleCount = 50;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _initParticles();
    _setupAnimation();
    _setupImageRotation();
  }

  void _initParticles() {
    final random = math.Random();
    for (int i = 0; i < _particleCount; i++) {
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

  void _setupImageRotation() {
    _imageTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % _backgroundImages.length;
      });
    });
  }

  void _updateParticles() {
    setState(() {
      for (var particle in _particles) {
        particle.y -= particle.speed;
        if (particle.y < 0) {
          particle.y = 800;
          particle.x = math.Random().nextDouble() * 400;
        }
      }
    });
  }

  @override
  void dispose() {
    _imageTimer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color overlayColor = isDark ? Colors.black : Colors.white;
    final List<Color> gradientColors = isDark
        ? [
      Color.fromRGBO(0, 0, 0, 0.6),
      Color.fromRGBO(0, 0, 0, 0.4),
    ]
        : [
      Color.fromRGBO(255, 255, 255, 0.7),
      Color.fromRGBO(255, 255, 255, 0.5),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // 背景图片层带淡入淡出效果
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: Image.asset(
                _backgroundImages[_currentImageIndex],
                key: ValueKey<int>(_currentImageIndex),
                fit: BoxFit.cover,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
              ),
            ),
            // 毛玻璃效果层
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 7.0,
                sigmaY: 7.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: gradientColors,
                  ),
                ),
              ),
            ),
            // 粒子动画层
            CustomPaint(
              painter: ParticlesPainter(
                _particles,
                overlayColor,
              ),
              size: Size(constraints.maxWidth, constraints.maxHeight),
            ),
            // 内容层
            widget.child,
          ],
        );
      },
    );
  }
}