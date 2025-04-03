import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:io' show Platform; // 保持导入

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
    this.maxParticles = 15, // 可以适当调整个数
    this.particleLifespan = const Duration(milliseconds: 600), // 可以调整生命周期
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
  bool _isEnabled = true; // 默认启用

  @override
  void initState() {
    super.initState();
    // --- 修改平台判断逻辑 ---
    // 在 Windows, macOS, Linux 上启用特效
    _isEnabled = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    // 如果只想在 Windows 上启用:
    // _isEnabled = Platform.isWindows;
    // 如果想在所有平台启用 (包括移动端):
    // _isEnabled = true; // 或者直接删除这行和后续的 if(!_isEnabled) 判断

    if (!_isEnabled) return; // 如果平台不符，则不初始化动画等

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60 FPS
    )..addListener(_updateParticles);

    _cleanupTimer = Timer.periodic(
      const Duration(milliseconds: 50),
          (_) => _cleanupParticles(),
    );
  }

  void _updateParticles() {
    if (!_isEnabled) return; // 如果禁用了，不更新

    List<MouseTrailParticle> currentParticles = List.from(_particles);
    for (var particle in currentParticles) {
      particle.update();
    }
    if (mounted) setState(() {});
  }

  void _cleanupParticles() {
    if (!_isEnabled) return; // 如果禁用了，不清理

    _particles.removeWhere((particle) => particle.opacity < 0.01 || particle.size < 0.1);
    if (_particles.isEmpty && _animationController.isAnimating) {
      _animationController.stop();
    }
    // 不需要 setState，因为 _updateParticles 会触发刷新
  }

  void _addParticle(Offset position) {
    if (!_isEnabled) return; // 如果禁用了，不添加

    // 稍微增加粒子数量和调整参数可能效果更好
    if (_particles.length >= widget.maxParticles) {
      // 可以考虑移除最旧的几个，而不是只移除一个
      _particles.removeRange(0, (_particles.length - widget.maxParticles + 2).clamp(1, 5));
    }

    // 尝试生成更多样化的粒子
    for (int i = 0; i < 3; i++) { // 增加每次生成的粒子数
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 0.6 + _random.nextDouble() * 1.0; // 减小一点速度范围
      final initialSize = 2.0 + _random.nextDouble() * 2.0; // 稍微增大尺寸范围
      final initialOpacity = 0.5 + _random.nextDouble() * 0.4; // 增加基础不透明度

      _particles.add(MouseTrailParticle(
        position: position + Offset(_random.nextDouble()*4-2, _random.nextDouble()*4-2), // 初始位置稍微随机化
        size: initialSize,
        angle: angle,
        speed: speed,
        opacity: initialOpacity,
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
    // 如果禁用了，直接返回 child
    if (!_isEnabled) {
      return widget.child;
    }

    // 使用 Directionality 保证方向正确性
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child, // 应用内容在下面
          Positioned.fill( // 特效层铺满
            child: MouseRegion(
              opaque: false, // 允许下层接收事件
              onHover: (event) {
                // 优化：只有在鼠标移动时才添加粒子
                if (_lastPosition != null) {
                  final distanceMoved = (event.localPosition - _lastPosition!).distance;
                  if(distanceMoved > 1.0) { // 仅当移动超过一个像素时处理
                    // 使用插值让粒子轨迹更平滑
                    final numPoints = (distanceMoved / 6).clamp(1, 5).toInt(); // 根据距离插值，但限制数量
                    for (int i = 1; i <= numPoints; i++) {
                      final t = i / numPoints;
                      final interpolatedPosition = Offset.lerp(_lastPosition!, event.localPosition, t)!;
                      _addParticle(interpolatedPosition);
                    }
                    _lastPosition = event.localPosition;
                  }
                } else {
                  _lastPosition = event.localPosition;
                }

              },
              onExit: (_) {
                _lastPosition = null; // 鼠标移出区域时重置
              },
              child: IgnorePointer( // 特效层不响应指针事件
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
      ),
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
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;
    // 考虑移除模糊，看是否性能更好或效果更清晰
    // ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    // 复制列表以避免在迭代时修改
    List<MouseTrailParticle> currentParticles = List.from(particles);
    for (var particle in currentParticles) {
      paint.color = color.withOpacity(particle.opacity.clamp(0.0, 1.0)); // 确保透明度在0-1之间
      canvas.drawCircle(
        particle.position,
        particle.size.clamp(0.0, 10.0), // 限制粒子大小
        paint,
      );
    }
  }

  // 优化：只有当粒子列表或颜色改变时才重绘
  @override
  bool shouldRepaint(_MouseTrailPainter oldDelegate) =>
      particles != oldDelegate.particles || color != oldDelegate.color;

// 如果粒子列表是可变的，可能需要更复杂的比较，但这里 List.from 应该每次都创建新列表引用
// 或者直接返回 true 也可以，性能影响通常不大，除非粒子非常多
// @override
// bool shouldRepaint(_MouseTrailPainter oldDelegate) => true;
}