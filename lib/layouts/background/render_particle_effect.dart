// lib/layouts/background/render_particle_effect.dart
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:suxingchahui/layouts/background/particle_effect.dart'; // 引入 Particle 和 ParticleShape

/// ParticleEffectRenderObjectWidget 是一个高性能的粒子效果组件。
/// 它将所有动画和绘制逻辑封装在底层的 RenderObject 中，避免了 build 方法的开销。
class ParticleEffectRenderObjectWidget extends LeafRenderObjectWidget {
  final int particleCount;
  final bool isResizing; // 依然需要这个来控制是否显示

  const ParticleEffectRenderObjectWidget({
    super.key,
    required this.particleCount,
    required this.isResizing,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderParticleEffect(
      particleCount: particleCount,
      isResizing: isResizing,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderParticleEffect renderObject) {
    renderObject
      ..particleCount = particleCount
      ..isResizing = isResizing;
  }
}

/// RenderParticleEffect 是实际执行所有工作的 RenderBox。
class RenderParticleEffect extends RenderBox {
  int _particleCount;
  bool _isResizing;

  final List<Particle> _particles = [];
  final List<Color> _pastelColors = const [
    Color(0xFFFFB3BA), Color(0xFFBAE1FF), Color(0xFFBAFFBF),
    Color(0xFFFFDFBA), Color(0xFFE3BAFF),
  ];
  Ticker? _ticker;

  RenderParticleEffect({
    required int particleCount,
    required bool isResizing,
  }) : _particleCount = particleCount,
        _isResizing = isResizing {
    // 创建一个 Ticker，这是驱动动画的核心
    _ticker = Ticker(_tick);
  }

  // --- 属性 Setters ---
  set particleCount(int value) {
    if (_particleCount == value) return;
    _particleCount = value;
    // 粒子数量变化，需要重新初始化
    _initParticles();
  }

  set isResizing(bool value) {
    if (_isResizing == value) return;
    _isResizing = value;
    // 调整大小时，我们停止动画并隐藏绘制
    if (_isResizing) {
      _stopAnimation();
    } else {
      // 调整结束后，重新初始化并开始动画
      _initParticles();
      _startAnimation();
    }
    markNeedsPaint(); // 触发重绘（或不重绘）
  }

  // --- RenderBox 生命周期 ---

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    // 挂载时，如果不是在调整大小，就开始动画
    if (!_isResizing) {
      _startAnimation();
    }
  }

  @override
  void detach() {
    _stopAnimation(); // 卸载时必须停止动画
    super.detach();
  }

  @override
  bool get isRepaintBoundary => true; // 性能优化

  @override
  void performLayout() {
    // 布局很简单，填满父组件
    size = constraints.biggest;
    // 布局变化时，重新初始化粒子
    _initParticles();
  }

  void _initParticles() {
    if (size == Size.zero) return;
    _particles.clear();
    final random = math.Random();
    for (int i = 0; i < _particleCount; i++) {
      final shape = ParticleShape.values[random.nextInt(ParticleShape.values.length)];
      final color = _pastelColors[random.nextInt(_pastelColors.length)];
      _particles.add(Particle(
        x: random.nextDouble() * size.width,
        y: random.nextDouble() * size.height,
        speed: 0.3 + random.nextDouble() * 0.8,
        size: 2 + random.nextDouble() * 4,
        opacity: 0.3 + random.nextDouble() * 0.4,
        angle: random.nextDouble() * math.pi * 2,
        shape: shape,
        color: color,
      ));
    }
    // 初始化后，如果 Ticker 没在运行，就启动它
    _startAnimation();
  }

  void _startAnimation() {
    if (_ticker != null && !_ticker!.isTicking) {
      _ticker!.start();
    }
  }

  void _stopAnimation() {
    if (_ticker != null && _ticker!.isTicking) {
      _ticker!.stop();
    }
  }

  // Ticker 的每一帧都会调用这个方法
  void _tick(Duration elapsed) {
    _updateParticles();
  }

  void _updateParticles() {
    if (size == Size.zero) return;
    final random = math.Random();

    for (var particle in _particles) {
      particle.velocityX += (random.nextDouble() - 0.5) * 0.1;
      particle.y -= particle.speed;
      particle.x += particle.velocityX;
      particle.y += particle.velocityY;
      particle.angle += 0.02;
      particle.velocityX *= 0.98;
      particle.velocityY *= 0.98;

      if (particle.y < -particle.size) {
        particle.y = size.height + particle.size;
        particle.x = random.nextDouble() * size.width;
        particle.velocityX = 0;
        particle.velocityY = 0;
        particle.opacity = 0.3 + random.nextDouble() * 0.4;
        particle.shape = ParticleShape.values[random.nextInt(ParticleShape.values.length)];
        particle.color = _pastelColors[random.nextInt(_pastelColors.length)];
      }
      if (particle.x < -particle.size) {
        particle.x = size.width + particle.size;
      } else if (particle.x > size.width + particle.size) {
        particle.x = -particle.size;
      }
    }

    // 只标记需要重绘，而不是调用 setState()
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // 如果正在调整大小，或者没有粒子，就啥也不画
    if (_isResizing || _particles.isEmpty) {
      return;
    }

    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    // 把 ParticlesPainter 的绘制逻辑直接搬过来
    final painter = ParticlesPainter(_particles);
    painter.paint(canvas, size);

    canvas.restore();
  }
}