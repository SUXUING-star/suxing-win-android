// lib/layouts/background/particle_effect.dart

/// 该文件定义了 ParticleEffect 组件，用于在背景上显示动态粒子效果。
/// ParticleEffect 创建并更新多种形状的粒子，实现背景的动画效果。
library;

import 'dart:math' as math; // 数学函数所需
import 'package:flutter/material.dart'; // Flutter UI 框架
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
enum ParticleShape { circle, heart, star, bubble }

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

/// `ParticleEffect` 类：粒子效果组件。
///
/// 该组件在背景上创建并更新多种形状的粒子，实现背景的动画效果。
class ParticleEffect extends StatefulWidget {
  final bool isCurrentlyResizing; // 标识窗口是否正在调整大小
  final int particleCount; // 粒子数量

  /// 构造函数。
  ///
  /// [key]：可选的 Key。
  /// [isCurrentlyResizing]：是否正在调整窗口大小。
  /// [particleCount]：粒子数量，默认为 50。
  const ParticleEffect({
    super.key,
    required this.isCurrentlyResizing,
    this.particleCount = 50,
  });

  /// 创建 `ParticleEffectState` 状态。
  @override
  ParticleEffectState createState() => ParticleEffectState();
}

/// `ParticleEffectState` 类：`ParticleEffect` 的状态。
///
/// 混入 `SingleTickerProviderStateMixin` 提供动画控制器。
class ParticleEffectState extends State<ParticleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller; // 动画控制器
  final List<Particle> _particles = []; // 粒子列表
  final List<Color> _pastelColors = [
    // 柔和颜色列表
    const Color(0xFFFFB3BA),
    const Color(0xFFBAE1FF),
    const Color(0xFFBAFFBF),
    const Color(0xFFFFDFBA),
    const Color(0xFFE3BAFF),
  ];
  Size _currentSize = Size.zero; // 当前尺寸

  /// 初始化状态。
  ///
  /// 设置动画控制器。
  @override
  void initState() {
    super.initState();
    _setupAnimation(); // 设置动画
  }

  /// 销毁状态。
  ///
  /// 销毁动画控制器。
  @override
  void dispose() {
    _controller.dispose(); // 销毁动画控制器
    super.dispose();
  }

  /// 根据需要初始化粒子。
  ///
  /// [size]：当前尺寸。
  /// 初始化粒子列表，设置随机位置、速度、尺寸、不透明度、角度、形状和颜色。
  void _initParticlesIfNeeded(Size size) {
    if (_particles.isNotEmpty && // 粒子已初始化且尺寸未明显变化时返回
        (_currentSize.width - size.width).abs() < 1 &&
        (_currentSize.height - size.height).abs() < 1) {
      return;
    }
    _currentSize = size; // 更新当前尺寸
    _particles.clear(); // 清空粒子列表
    final random = math.Random(); // 随机数生成器
    for (int i = 0; i < widget.particleCount; i++) {
      // 循环创建粒子
      final shape = ParticleShape
          .values[random.nextInt(ParticleShape.values.length)]; // 随机形状
      final color = _pastelColors[random.nextInt(_pastelColors.length)]; // 随机颜色
      _particles.add(
        Particle(
          x: random.nextDouble() * _currentSize.width, // 随机 X 坐标
          y: random.nextDouble() * _currentSize.height, // 随机 Y 坐标
          speed: 0.3 + random.nextDouble() * 0.8, // 随机速度
          size: 2 + random.nextDouble() * 4, // 随机尺寸
          opacity: 0.3 + random.nextDouble() * 0.4, // 随机不透明度
          angle: random.nextDouble() * math.pi * 2, // 随机角度
          shape: shape, // 形状
          color: color, // 颜色
        ),
      );
    }
  }

  /// 设置动画控制器。
  ///
  /// 配置动画控制器并添加监听器。
  void _setupAnimation() {
    _controller = AnimationController(
      // 创建动画控制器
      vsync: this, // 垂直同步
      duration: const Duration(milliseconds: 16), // 动画持续时间
    )..addListener(() {
        // 添加监听器
        if (_controller.isAnimating && mounted) {
          // 动画正在进行且组件已挂载时
          _updateParticles(); // 更新粒子
        }
      });
  }

  /// 如果需要，启动动画。
  ///
  /// 如果组件已挂载且动画未进行且有粒子，则循环播放动画。
  void _startAnimationIfNeeded() {
    if (mounted && !_controller.isAnimating && _particles.isNotEmpty) {
      // 检查条件
      _controller.repeat(); // 循环播放动画
    }
  }

  /// 更新粒子状态。
  ///
  /// 粒子根据速度移动，并处理边界循环。
  void _updateParticles() {
    if (!mounted || _currentSize == Size.zero) return; // 组件未挂载或尺寸为零时返回
    final random = math.Random(); // 随机数生成器
    setState(() {
      // 更新 UI
      for (var particle in _particles) {
        // 遍历粒子
        particle.velocityX += (random.nextDouble() - 0.5) * 0.1; // 更新 X 速度
        particle.y -= particle.speed; // 更新 Y 坐标
        particle.x += particle.velocityX; // 更新 X 坐标
        particle.y += particle.velocityY; // 更新 Y 坐标
        particle.angle += 0.02; // 更新角度
        particle.velocityX *= 0.98; // 减小 X 速度
        particle.velocityY *= 0.98; // 减小 Y 速度

        if (particle.y < -particle.size) {
          // 粒子移出顶部边界
          particle.y = _currentSize.height + particle.size; // 重新出现在底部
          particle.x = random.nextDouble() * _currentSize.width; // 随机 X 坐标
          particle.velocityX = 0; // 重置 X 速度
          particle.velocityY = 0; // 重置 Y 速度
          particle.opacity = 0.3 + random.nextDouble() * 0.4; // 随机不透明度
          particle.shape = ParticleShape
              .values[random.nextInt(ParticleShape.values.length)]; // 随机形状
          particle.color =
              _pastelColors[random.nextInt(_pastelColors.length)]; // 随机颜色
        }
        if (particle.x < -particle.size) {
          // 粒子移出左侧边界
          particle.x = _currentSize.width + particle.size; // 重新出现在右侧
        } else if (particle.x > _currentSize.width + particle.size) {
          // 粒子移出右侧边界
          particle.x = -particle.size; // 重新出现在左侧
        }
      }
    });
  }

  /// 应用涟漪效果。
  ///
  /// [position]：涟漪中心位置。
  /// [strength]：涟漪强度。
  /// 计算粒子与涟漪中心的距离，并施加力以创建涟漪效果。
  void applyRippleEffect(Offset position, double strength) {
    if (!mounted || _currentSize == Size.zero) return; // 组件未挂载或尺寸为零时返回

    for (var particle in _particles) {
      // 遍历粒子
      final dx = (particle.x - position.dx); // 粒子与涟漪中心 X 距离
      final dy = (particle.y - position.dy); // 粒子与涟漪中心 Y 距离
      final distance = math.sqrt(dx * dx + dy * dy); // 粒子与涟漪中心距离

      if (distance < 100) {
        // 距离小于阈值时
        final angle = math.atan2(dy, dx); // 计算角度
        final force = (1 - distance / 100) * strength * 3; // 计算施加的力
        particle.velocityX += math.cos(angle) * force; // 更新 X 速度
        particle.velocityY += math.sin(angle) * force; // 更新 Y 速度
      }
    }
  }

  /// 构建粒子效果 UI。
  ///
  /// [context]：Build 上下文。
  /// 返回一个 `Offstage` 组件，内部嵌套 `LayoutBuilder` 和 `CustomPaint`。
  @override
  Widget build(BuildContext context) {
    return Offstage(
      // 控制子组件是否显示
      offstage: widget.isCurrentlyResizing, // 窗口调整大小时隐藏粒子效果
      child: LayoutBuilder(
        // 布局构建器
        builder: (context, constraints) {
          final newSize = constraints.biggest; // 获取新尺寸
          if (_currentSize != newSize || _particles.isEmpty) {
            // 尺寸变化或无粒子时
            _initParticlesIfNeeded(newSize); // 初始化粒子
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // 在下一帧回调中
              _startAnimationIfNeeded(); // 启动动画
            });
          }
          if (_particles.isEmpty) {
            // 粒子列表为空时返回空组件
            return const SizedBox.shrink();
          }
          return CustomPaint(
            // 自定义绘制
            painter: ParticlesPainter(_particles), // 绘制器
            size: Size.infinite, // 无限大小
          );
        },
      ),
    );
  }
}
