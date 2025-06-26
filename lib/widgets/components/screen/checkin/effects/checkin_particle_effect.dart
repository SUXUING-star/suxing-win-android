// lib/widgets/components/screen/checkin/effects/checkin_particle_effect.dart

/// 该文件定义了 CheckInParticleEffect 组件，用于创建签到时的粒子动画效果。
/// CheckInParticleEffect 负责管理粒子生成、动画更新和渲染。
library;

import 'dart:math'; // 导入数学库
import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展方法所需

/// `CheckInParticleEffect` 类：签到粒子效果的 StatefulWidget。
///
/// 该组件根据动画控制器创建和显示粒子动画。
class CheckInParticleEffect extends StatefulWidget {
  final AnimationController controller; // 动画控制器
  final Color? color; // 粒子颜色
  final int particleCount; // 粒子数量

  /// 构造函数。
  ///
  /// [controller]：动画控制器。
  /// [color]：粒子颜色。
  /// [particleCount]：粒子数量。
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
  List<_Particle> particles = []; // 粒子列表
  final Random random = Random(); // 随机数生成器
  bool _isDisposed = false; // 销毁标记

  @override
  void initState() {
    super.initState(); // 调用父类 initState
    initParticles(); // 初始化粒子
    widget.controller.addListener(_updateParticles); // 添加动画监听器
  }

  /// 更新粒子状态。
  ///
  /// 当动画控制器动画时，更新组件状态。
  void _updateParticles() {
    if (widget.controller.isAnimating && mounted && !_isDisposed) {
      // 动画进行中且组件挂载时
      setState(() {}); // 更新状态以触发重绘
    }
  }

  @override
  void dispose() {
    _isDisposed = true; // 设置销毁标记
    widget.controller.removeListener(_updateParticles); // 移除动画监听器
    super.dispose(); // 调用父类 dispose
  }

  /// 初始化粒子。
  ///
  /// 清空现有粒子并生成新的粒子列表。
  void initParticles() {
    particles.clear(); // 清空粒子列表
    for (int i = 0; i < widget.particleCount; i++) {
      // 根据粒子数量生成新粒子
      particles.add(_Particle(
        position: Offset.zero, // 初始位置为中心
        velocity: Offset(
          (random.nextDouble() * 2 - 1) * 5, // 随机水平速度
          (random.nextDouble() * 2 - 1) * 5, // 随机垂直速度
        ),
        color: widget.color ?? Colors.blue, // 粒子颜色
        size: random.nextDouble() * 8 + 2, // 粒子大小
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ParticlePainter(
        // 自定义绘制器
        particles: particles, // 粒子列表
        progress: widget.controller.value, // 动画进度
        color: widget.color ?? Theme.of(context).primaryColor, // 粒子颜色
      ),
      child: Container(), // 绘制区域的占位符
    );
  }
}

/// `_ParticlePainter` 类：负责绘制粒子的 CustomPainter。
///
/// 该类根据粒子数据和动画进度在画布上绘制圆形粒子。
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles; // 粒子列表
  final double progress; // 动画进度
  final Color color; // 粒子颜色

  /// 构造函数。
  ///
  /// [particles]：粒子列表。
  /// [progress]：动画进度。
  /// [color]：粒子颜色。
  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return; // 进度小于等于 0 时不绘制

    final center = Offset(size.width / 2, size.height / 2); // 画布中心点

    for (var particle in particles) {
      // 遍历粒子列表
      final position = center + (particle.velocity * progress * 100); // 计算粒子位置
      final opacity = (1.0 - progress) * 0.8; // 计算粒子透明度

      if (opacity <= 0) continue; // 透明度小于等于 0 时跳过绘制

      final paint = Paint()
        ..color = particle.color.withSafeOpacity(opacity) // 设置绘制颜色和透明度
        ..style = PaintingStyle.fill; // 填充样式

      canvas.drawCircle(
          position, particle.size * (1 - progress * 0.5), paint); // 绘制圆形粒子
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress; // 仅在进度变化时重绘
  }
}

/// `_Particle` 类：表示单个粒子数据模型。
///
/// 包含粒子的位置、速度、颜色和大小信息。
class _Particle {
  Offset position; // 粒子位置
  Offset velocity; // 粒子速度
  Color color; // 粒子颜色
  double size; // 粒子大小

  /// 构造函数。
  ///
  /// [position]：粒子位置。
  /// [velocity]：粒子速度。
  /// [color]：粒子颜色。
  /// [size]：粒子大小。
  _Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
  });
}
