// lib/layouts/background/particle_effect.dart

/// 该文件定义了 ParticleEffect 组件，用于在背景上显示动态粒子效果。
/// ParticleEffect 创建并更新多种形状的粒子，实现背景的动画效果。
library;

import 'dart:math' as math; // 数学函数所需
import 'package:flutter/material.dart'; // Flutter UI 框架
import 'package:suxingchahui/layouts/background/render_particle_effect.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展

/// `Particle` 类：粒子模型。
///
/// 包含粒子的位置、速度、尺寸、不透明度、速度分量、角度、形状和颜色。
class Particle {
  double x; // 粒子 X 坐标
  double y; // 粒子 Y 坐标
  double speed; // 粒子速度
  double size; // 粒子尺寸
  double opacity; // 粒子不透明度
  double velocityX; // 粒子 X 方向速度
  double velocityY; // 粒子 Y 方向速度
  double angle; // 粒子角度
  ParticleShape shape; // 粒子形状
  Color color; // 粒子颜色

  /// 构造函数。
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

/// `ParticleShape` 枚举：定义粒子的形状。
enum ParticleShape {
  circle,
  heart,
  star,
  bubble,
}

/// `ParticlesPainter` 类：粒子绘制器。
///
/// 继承自 `CustomPainter`，负责绘制粒子。
class ParticlesPainter extends CustomPainter {
  final List<Particle> particles; // 粒子列表

  /// 构造函数。
  ///
  /// [particles]：粒子列表。
  ParticlesPainter(this.particles);

  /// 绘制粒子。
  ///
  /// [canvas]：画布。
  /// [size]：绘制区域大小。
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill; // 画笔，填充样式

    for (var particle in particles) {
      // 遍历粒子
      paint.color =
          particle.color.withSafeOpacity(particle.opacity); // 设置颜色和不透明度
      final position = Offset(particle.x, particle.y); // 获取粒子位置

      switch (particle.shape) {
        // 根据粒子形状绘制
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

  /// 绘制气泡形状。
  ///
  /// [canvas]：画布。
  /// [position]：位置。
  /// [size]：尺寸。
  /// [paint]：画笔。
  void _drawBubble(Canvas canvas, Offset position, double size, Paint paint) {
    canvas.drawCircle(position, size, paint); // 绘制圆形
    final highlightPaint = Paint() // 亮点画笔
      ..color = Colors.white.withSafeOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      // 绘制高光圆形
      Offset(position.dx - size * 0.3, position.dy - size * 0.3),
      size * 0.2,
      highlightPaint,
    );
  }

  /// 绘制心形形状。
  ///
  /// [canvas]：画布。
  /// [position]：位置。
  /// [size]：尺寸。
  /// [paint]：画笔。
  /// [angle]：角度。
  void _drawHeart(
      Canvas canvas, Offset position, double size, Paint paint, double angle) {
    canvas.save(); // 保存画布状态
    canvas.translate(position.dx, position.dy); // 平移到位置
    canvas.rotate(angle); // 旋转
    final path = Path(); // 路径
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
    canvas.drawPath(path, paint); // 绘制路径
    canvas.restore(); // 恢复画布状态
  }

  /// 绘制星形形状。
  ///
  /// [canvas]：画布。
  /// [position]：位置。
  /// [size]：尺寸。
  /// [paint]：画笔。
  /// [angle]：角度。
  void _drawStar(
      Canvas canvas, Offset position, double size, Paint paint, double angle) {
    canvas.save(); // 保存画布状态
    canvas.translate(position.dx, position.dy); // 平移到位置
    canvas.rotate(angle); // 旋转
    final path = Path(); // 路径
    const points = 5; // 五角星
    final innerRadius = size * 0.4; // 内半径
    final outerRadius = size; // 外半径
    for (var i = 0; i < points * 2; i++) {
      // 循环绘制星角
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
    path.close(); // 闭合路径
    canvas.drawPath(path, paint); // 绘制路径
    canvas.restore(); // 恢复画布状态
  }

  /// 判断是否需要重绘。
  ///
  /// [oldDelegate]：旧的绘制器代理。
  /// 返回 true，表示始终重绘。
  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) => true; // 始终重绘
}

/// ParticleEffect 组件现在是一个简单的封装，
/// 将所有复杂的动画和绘制逻辑委托给高性能的 RenderObject。
class ParticleEffect extends StatelessWidget {
  final bool isCurrentlyResizing;
  final int particleCount;

  const ParticleEffect({
    super.key,
    required this.isCurrentlyResizing,
    this.particleCount = 50,
  });

  @override
  Widget build(BuildContext context) {
    return ParticleEffectRenderObjectWidget(
      particleCount: particleCount,
      isResizing: isCurrentlyResizing,
    );
  }
}
