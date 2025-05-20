import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 你的颜色扩展

// --- Constants ---
const double _kMinOpacity = 0.01;
const double _kMinSize = 0.1;
const Duration _kParticleUpdateInterval = Duration(milliseconds: 16);

class MouseTrailParticle {
  Offset position;
  double opacity;
  double size;
  double angle;
  double speed;
  Color color;
  bool isActive;

  MouseTrailParticle({
    required this.position,
    this.opacity = 1.0,
    this.size = 3.0,
    this.angle = 0.0,
    this.speed = 1.5,
    required this.color,
    this.isActive = false,
  });

  void reset({
    required Offset newPosition,
    required double newAngle,
    required double newSpeed,
    required double newSize,
    required double newOpacity,
    required Color newColor,
  }) {
    position = newPosition;
    angle = newAngle;
    speed = newSpeed;
    size = newSize;
    opacity = newOpacity;
    color = newColor;
    isActive = true;
  }

  void update() {
    if (!isActive) return;
    position = Offset(
      position.dx + math.cos(angle) * speed,
      position.dy + math.sin(angle) * speed,
    );
    opacity *= 0.94;
    size *= 0.97;
    if (opacity < _kMinOpacity || size < _kMinSize) {
      isActive = false;
    }
  }
}

class MouseTrailEffect extends StatefulWidget {
  final Widget child;
  final Color particleColor;
  final int maxParticles;

  const MouseTrailEffect({
    super.key,
    required this.child,
    this.particleColor = Colors.blue,
    this.maxParticles = 20,
  });

  @override
  State<MouseTrailEffect> createState() => _MouseTrailEffectState();
}

class _MouseTrailEffectState extends State<MouseTrailEffect>
    with SingleTickerProviderStateMixin {
  final List<MouseTrailParticle> _particlePool = [];
  final List<MouseTrailParticle> _activeParticles = [];
  Offset? _lastMousePosition;
  late AnimationController _animationController;
  final math.Random _random = math.Random();
  bool _isEnabled = true;

  @override
  void initState() {
    super.initState();
    _isEnabled =
        !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

    if (!_isEnabled) return;

    for (int i = 0; i < widget.maxParticles * 2; i++) {
      _particlePool.add(MouseTrailParticle(
        position: Offset.zero,
        color: widget.particleColor,
        isActive: false,
      ));
    }

    _animationController = AnimationController(
      vsync: this,
      duration: _kParticleUpdateInterval,
    )..addListener(_updateParticlesAndCheckCleanup);
    // _animationController.repeat(); // 不在 initState 中 repeat，在有粒子时才 repeat
  }

  void _updateParticlesAndCheckCleanup() {
    if (!_isEnabled || !mounted) return;

    for (int i = _activeParticles.length - 1; i >= 0; i--) {
      final particle = _activeParticles[i];
      particle.update();
      if (!particle.isActive) {
        _activeParticles.removeAt(i);
        _particlePool.add(particle);
      }
    }

    if (_activeParticles.isEmpty && _animationController.isAnimating) {
      _animationController.stop();
    }
    // 不需要 setState，CustomPaint 通过 repaint Listenable 更新
  }

  void _addParticlesAtPosition(Offset position) {
    if (!_isEnabled) return;
    const int particlesToAddPerEvent = 2;
    int addedCount = 0;

    for (int i = 0;
        i < _particlePool.length && addedCount < particlesToAddPerEvent;
        i++) {
      if (!_particlePool[i].isActive) {
        final particle = _particlePool.removeAt(i);
        final angle = _random.nextDouble() * 2 * math.pi;
        final speed = 0.8 + _random.nextDouble() * 1.2;
        final initialSize = 2.5 + _random.nextDouble() * 2.5;
        final initialOpacity = 0.6 + _random.nextDouble() * 0.4;

        // --- 修正颜色 Hue 的获取和设置 ---
        HSLColor hslColor = HSLColor.fromColor(widget.particleColor);
        // 随机调整 hue 值，例如在 +/- 15 度范围内
        double newHue =
            (hslColor.hue + _random.nextDouble() * 30.0 - 15.0) % 360.0;
        if (newHue < 0) newHue += 360.0; // 确保 hue 在 0-360
        final newParticleColor = hslColor.withHue(newHue).toColor();

        particle.reset(
          newPosition: position +
              Offset(
                  _random.nextDouble() * 6 - 3, _random.nextDouble() * 6 - 3),
          newAngle: angle,
          newSpeed: speed,
          newSize: initialSize,
          newOpacity: initialOpacity,
          newColor: newParticleColor,
        );
        _activeParticles.add(particle);
        addedCount++;

        if (_activeParticles.length > widget.maxParticles) {
          final oldestParticle = _activeParticles.removeAt(0);
          oldestParticle.isActive = false;
          _particlePool.add(oldestParticle);
        }
      }
    }

    if (!_animationController.isAnimating && _activeParticles.isNotEmpty) {
      _animationController.repeat();
    }
  }

  void _handleMouseMove(Offset localPosition) {
    if (_lastMousePosition != null) {
      final distanceMoved = (localPosition - _lastMousePosition!).distance;
      if (distanceMoved > 0.5) {
        final int numInterpolationPoints =
            (distanceMoved / 5.0).clamp(1, 4).toInt();
        for (int i = 0; i < numInterpolationPoints; i++) {
          final t = (i + 1) / numInterpolationPoints;
          final interpolatedPosition =
              Offset.lerp(_lastMousePosition!, localPosition, t)!;
          _addParticlesAtPosition(interpolatedPosition);
        }
        _lastMousePosition = localPosition;
      }
    } else {
      _addParticlesAtPosition(localPosition);
      _lastMousePosition = localPosition;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEnabled) {
      return widget.child;
    }

    return Listener(
      onPointerHover: (event) => _handleMouseMove(event.localPosition),
      onPointerDown: (event) => _handleMouseMove(event.localPosition),
      onPointerMove: (event) => _handleMouseMove(event.localPosition),
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                // --- 修正 CustomPaint 的 repaint 方式 ---
                // 将 AnimationController 传递给 Painter
                painter: _MouseTrailPainter(
                  particles: _activeParticles,
                  animation:
                      _animationController, // <--- 将 animationController 传递给 painter
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MouseTrailPainter extends CustomPainter {
  final List<MouseTrailParticle> particles;

  _MouseTrailPainter({required this.particles, required Listenable animation})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    for (final particle in particles) {
      if (particle.isActive) {
        paint.color =
            particle.color.withSafeOpacity(particle.opacity.clamp(0.0, 1.0));
        canvas.drawCircle(
          particle.position,
          particle.size.clamp(0.0, 15.0),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MouseTrailPainter oldDelegate) {
    return particles != oldDelegate.particles ||
        particles.length != oldDelegate.particles.length;
  }
}
